import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../models/parent_model.dart';

/// Service d'authentification pour les Parents
/// 
/// Connexion simple avec code unique
class ParentAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryption = EncryptionService();

  /// Connexion du parent avec code unique
  /// 
  /// Recherche le parent dont le code chiffré correspond
  Future<ParentModel?> loginWithCode(String code) async {
    try {
      // Chiffrer le code pour la comparaison
      final encryptedCode = _encryption.encryptString(code);

      // Rechercher le parent avec ce code
      final querySnapshot = await _firestore
          .collection('parents')
          .where('codeEncrypted', isEqualTo: encryptedCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Code invalide');
      }

      final parentDoc = querySnapshot.docs.first;
      return ParentModel.fromFirestore(
        parentDoc.data(),
        parentDoc.id,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Créer un nouveau parent avec code généré
  Future<ParentModel> createParent({
    required String rawdhaId,
    required String firstName,
    required String lastName,
    required String phone,
    List<String> studentIds = const [],
  }) async {
    try {
      // Générer un code unique
      final code = _encryption.generateParentCode();
      final encryptedCode = _encryption.encryptString(code);
      final encryptedPhone = _encryption.encryptString(phone);

      final docRef = await _firestore.collection('parents').add({
        'rawdhaId': rawdhaId,
        'firstName': firstName,
        'lastName': lastName,
        'encryptedPhone': encryptedPhone,
        'codeEncrypted': encryptedCode,
        'studentIds': studentIds,
      });

      final parent = ParentModel(
        id: docRef.id,
        rawdhaId: rawdhaId,
        firstName: firstName,
        lastName: lastName,
        phone: encryptedPhone, // Map consistent with model field name if needed
        familyCode: '', // Should be generated if needed, but current model uses it
        accessCode: '', 
        studentIds: studentIds,
        createdAt: DateTime.now(),
      );

      return parent;
    } catch (e) {
      throw Exception('Erreur lors de la création du parent: $e');
    }
  }

  /// Régénérer le code d'un parent
  Future<String> regenerateCode(String parentId) async {
    try {
      final newCode = _encryption.generateParentCode();
      final encryptedCode = _encryption.encryptString(newCode);

      await _firestore.collection('parents').doc(parentId).update({
        'codeEncrypted': encryptedCode,
      });

      return newCode; // Retourner pour affichage
    } catch (e) {
      throw Exception('Erreur lors de la régénération du code: $e');
    }
  }

  /// Ajouter un enfant à un parent
  Future<void> addStudentToParent(String parentId, String studentId) async {
    try {
      await _firestore.collection('parents').doc(parentId).update({
        'studentIds': FieldValue.arrayUnion([studentId]),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'enfant: $e');
    }
  }

  /// Retirer un enfant d'un parent
  Future<void> removeStudentFromParent(String parentId, String studentId) async {
    try {
      await _firestore.collection('parents').doc(parentId).update({
        'studentIds': FieldValue.arrayRemove([studentId]),
      });
    } catch (e) {
      throw Exception('Erreur lors du retrait de l\'enfant: $e');
    }
  }
}
