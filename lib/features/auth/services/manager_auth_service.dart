import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../core/utils/device_utils.dart';
import '../../../models/manager_model.dart';

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

      // 4. Vérifier et auto-autoriser l'appareil
      if (!manager.authorizedDevices.contains(deviceId)) {
        // Ajouter le nouvel appareil à la liste
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

  /// Créer un nouveau manager (pour l'initialisation)
  Future<ManagerModel> createManager({
    required String username,
    required String password,
  }) async {
    try {
      final passwordHash = _encryption.hashPassword(password);
      
      final docRef = await _firestore.collection('managers').add({
        'username': username,
        'passwordHash': passwordHash,
        'authorizedDevices': [],
      });

      return ManagerModel(
        managerId: docRef.id,
        username: username,
        passwordHash: passwordHash,
        authorizedDevices: [],
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
}
