import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math';
import '../../../core/encryption/encryption_service.dart';
import '../../../core/utils/device_utils.dart';
import '../../../models/manager_model.dart';
import '../../../models/school_config_model.dart';
import '../../../services/school_service.dart';

/// Service d'authentification pour les Managers
/// 
/// Gère la connexion avec vérification de l'appareil
class ManagerAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryption = EncryptionService();

  /// Connexion du manager
  /// 
  /// Vérifie:
  /// 1. Username et password
  /// 2. Autorisation de l'appareil
  /// 3. Premier appareil → autorisation automatique
  Future<ManagerModel?> login(String username, String password) async {
    try {
      // 1. Rechercher le manager par username
      final querySnapshot = await _firestore
          .collection('managers')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Nom d\'utilisateur ou mot de passe incorrect');
      }

      final managerDoc = querySnapshot.docs.first;
      final manager = ManagerModel.fromFirestore(
        managerDoc.data(),
        managerDoc.id,
      );

      // 2. Vérifier le mot de passe
      final passwordHash = _encryption.hashPassword(password);
      
      if (manager.passwordHash != passwordHash) {
        throw Exception('Nom d\'utilisateur ou mot de passe incorrect');
      }

      // 3. Obtenir l'ID de l'appareil actuel
      final deviceId = await DeviceUtils.getDeviceId();

      // 4. Vérifier la restriction par appareil dans la config de l'école
      final schoolConfig = await SchoolService().getSchoolConfig(manager.rawdhaId).first;
      final isRestricted = schoolConfig.restrictDevices;

      // 5. Vérifier et auto-autoriser l'appareil
      if (!manager.authorizedDevices.contains(deviceId)) {
        if (isRestricted) {
          throw Exception('manager.auth.device_restricted'.tr());
        }

        // Ajouter le nouvel appareil à la liste (Autorisation automatique si non restreint)
        final updatedDevices = List<String>.from(manager.authorizedDevices)..add(deviceId);
        
        await _firestore
            .collection('managers')
            .doc(manager.managerId)
            .update({'authorizedDevices': updatedDevices});
        
        return manager.copyWith(authorizedDevices: updatedDevices);
      }

      return manager;
    } catch (e) {
      rethrow;
    }
  }

  /// Vérifier le mot de passe du manager actuel (pour les actions sensibles)
  Future<bool> verifyPassword(String managerId, String password) async {
    try {
      final doc = await _firestore.collection('managers').doc(managerId).get();
      if (!doc.exists) return false;
      
      final data = doc.data();
      if (data == null) return false;
      
      final storedHash = data['passwordHash'];
      final providedHash = _encryption.hashPassword(password);
      
      return storedHash == providedHash;
    } catch (e) {
      return false;
    }
  }

  /// Mettre à jour le mot de passe du manager
  Future<void> updatePassword(String managerId, String newPassword) async {
    try {
      final passwordHash = _encryption.hashPassword(newPassword);
      await _firestore.collection('managers').doc(managerId).update({
        'passwordHash': passwordHash,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du mot de passe: $e');
    }
  }

  /// Créer un nouveau manager (pour l'initialisation)
  Future<ManagerModel> createManager({
    required String username,
    required String password,
    required String rawdhaId,
  }) async {
    try {
      final passwordHash = _encryption.hashPassword(password);
      
      final docRef = await _firestore.collection('managers').add({
        'username': username,
        'passwordHash': passwordHash,
        'rawdhaId': rawdhaId,
        'authorizedDevices': [],
        'hasSeenOnboarding': false,
      });

      return ManagerModel(
        managerId: docRef.id,
        rawdhaId: rawdhaId,
        username: username,
        passwordHash: passwordHash,
        authorizedDevices: [],
        hasSeenOnboarding: false,
      );
    } catch (e) {
      throw Exception('Erreur lors de la création du manager: $e');
    }
  }

  /// Autoriser un nouvel appareil
  Future<void> authorizeDevice(String managerId, String deviceId) async {
    try {
      await _firestore.collection('managers').doc(managerId).update({
        'authorizedDevices': FieldValue.arrayUnion([deviceId]),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'autorisation de l\'appareil: $e');
    }
  }

  /// Marquer l'onboarding comme terminé
  Future<void> completeOnboarding(String managerId) async {
    try {
      await _firestore.collection('managers').doc(managerId).update({
        'hasSeenOnboarding': true,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'onboarding: $e');
    }
  }

  /// Révoquer l'autorisation d'un appareil
  Future<void> revokeDevice(String managerId, String deviceId) async {
    try {
      await _firestore.collection('managers').doc(managerId).update({
        'authorizedDevices': FieldValue.arrayRemove([deviceId]),
      });
    } catch (e) {
      throw Exception('Erreur lors de la révocation de l\'appareil: $e');
    }
  }

  /// Restreindre uniquement à l'appareil actuel
  Future<void> restrictToCurrentDevice(String managerId) async {
    try {
      final deviceId = await DeviceUtils.getDeviceId();
      await _firestore.collection('managers').doc(managerId).update({
        'authorizedDevices': [deviceId],
      });
    } catch (e) {
      throw Exception('Erreur lors de la restriction de l\'appareil: $e');
    }
  }
  /// Générer un code école unique basé sur le nom
  Future<String> _generateUniqueSchoolCode(String rawdhaName, String rawdhaId) async {
    // Extraire les premières lettres du nom (enlever les espaces et caractères spéciaux)
    final cleanName = rawdhaName
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\u0600-\u06FF]'), ''); // Garder lettres latines, chiffres et arabes
    
    // Prendre les 4-6 premiers caractères
    String baseCode = cleanName.length >= 4 
        ? cleanName.substring(0, cleanName.length >= 6 ? 6 : cleanName.length)
        : cleanName;
    
    // Vérifier si ce code existe déjà
    final schoolService = SchoolService();
    bool codeExists = await schoolService.checkSchoolCodeExists(baseCode, rawdhaId);
    
    if (!codeExists) {
      return baseCode;
    }
    
    // Si le code existe, générer un code aléatoire unique de 8 caractères
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    
    for (int attempt = 0; attempt < 10; attempt++) {
      String randomCode = List.generate(
        8, 
        (index) => chars[random.nextInt(chars.length)]
      ).join();
      
      bool exists = await schoolService.checkSchoolCodeExists(randomCode, rawdhaId);
      if (!exists) {
        return randomCode;
      }
    }
    
    // Fallback: utiliser timestamp
    return 'SCH${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  /// Enregistrer une nouvelle Rawdha et son admin
  Future<void> registerRawdha({
    required String rawdhaName,
    required String phoneNumber,
    required String adminUsername,
    required String adminPassword,
  }) async {
    try {
      final deviceId = await DeviceUtils.getDeviceId();

      // 1. Vérifier si le nom d'utilisateur est déjà pris
      final usernameQuery = await _firestore
          .collection('managers')
          .where('username', isEqualTo: adminUsername)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Ce nom d\'utilisateur est déjà pris.');
      }

      // 2. Vérifier si le numéro de téléphone est déjà utilisé
      final phoneQuery = await _firestore
          .collection('rawdhas')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (phoneQuery.docs.isNotEmpty) {
        throw Exception('Ce numéro de téléphone est déjà utilisé par un autre établissement.');
      }

      // 3. Vérifier si cet appareil a déjà une inscription
      final deviceQuery = await _firestore
          .collection('rawdhas')
          .where('registeredDeviceId', isEqualTo: deviceId)
          .limit(1)
          .get();

      if (deviceQuery.docs.isNotEmpty) {
        throw Exception('Cet appareil est déjà associé à une inscription.');
      }

      // 4. Générer un code école unique
      final schoolCode = await _generateUniqueSchoolCode(rawdhaName, 'temp');

      // 5. Créer la Rawdha
      final rawdhaDocRef = await _firestore.collection('rawdhas').add({
        'name': rawdhaName,
        'phoneNumber': phoneNumber,
        'registeredDeviceId': deviceId,
        'code': schoolCode, // Ajouter le code école
        'accepter': true, // Par défaut, nécessite validation
        'dateValide': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))), // 7 jours d'essai
      });

      // 6. Créer la configuration de l'école avec le même nom et code
      final schoolConfig = SchoolConfigModel(
        rawdhaId: rawdhaDocRef.id,
        name: rawdhaName,
        schoolCode: schoolCode,
        paymentStartMonth: 9, // Septembre par défaut
        restrictDevices: false,
      );
      await SchoolService().saveSchoolConfig(schoolConfig, rawdhaDocRef.id);

      // 7. Créer l'admin associé
      await createManager(
        username: adminUsername,
        password: adminPassword,
        rawdhaId: rawdhaDocRef.id,
      );

      // 8. Initialiser les niveaux par défaut
      await SchoolService().initializeDefaultLevels(rawdhaDocRef.id);
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement: $e');
    }
  }
}
