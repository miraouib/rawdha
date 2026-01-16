import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parent_model.dart';
import '../core/encryption/encryption_service.dart';

class ParentService {
  final CollectionReference _parentsCollection = FirebaseFirestore.instance.collection('parents');
  final _encryptionService = EncryptionService(); // Assume singleton or instance

  // Generate Family Code: First Letter + 4 digits
  String generateFamilyCode(String firstName) {
    if (firstName.isEmpty) return 'P${_generateRandomDigits(4)}';
    String letter = firstName[0].toUpperCase();
    if (!RegExp(r'[A-Z]').hasMatch(letter)) letter = 'P'; // Fail-safe
    return '$letter${_generateRandomDigits(4)}';
  }

  // Generate Access Code: 6 digits
  String generateAccessCode() {
    return _generateRandomDigits(6);
  }

  String _generateRandomDigits(int length) {
    final rand = Random();
    String result = '';
    for (int i = 0; i < length; i++) {
      result += rand.nextInt(10).toString();
    }
    return result;
  }

  Stream<List<ParentModel>> getParents(String rawdhaId) {
    return _parentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .snapshots()
        .map((snapshot) {
      final parents = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ParentModel.fromFirestore(data, doc.id);
      }).toList();

      // Sort in-memory to avoid Firestore composite index requirement
      parents.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Descending
      return parents;
    });
  }

  /// Vérifier les identifiants d'un parent
  Future<ParentModel?> loginParent(String familyCode, String accessCode) async {
    try {
      final snapshot = await _parentsCollection
          .where('familyCode', isEqualTo: familyCode)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final parent = ParentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        if (parent.accessCode == accessCode) {
          return parent;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupérer un parent par son ID
  Future<ParentModel?> getParentById(String rawdhaId, String id) async {
    try {
      final doc = await _parentsCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['rawdhaId'] == rawdhaId) {
          return ParentModel.fromFirestore(data, doc.id);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  Future<void> addParent(ParentModel parent) async {
    // Encrypt sensitive data before saving
    final map = parent.toMap();
    // map['phone'] = _encryptionService.encrypt(parent.phone);
    // map['familyCode'] = _encryptionService.encrypt(parent.familyCode);
    // map['accessCode'] = _encryptionService.encrypt(parent.accessCode);

    await _parentsCollection.add(map);
  }

  Future<void> updateParent(ParentModel parent) async {
    final map = parent.toMap();
    // Encrypt sensitive data
    // map['phone'] = _encryptionService.encrypt(parent.phone);
    // map['familyCode'] = _encryptionService.encrypt(parent.familyCode); // ID usually doesn't change?
    // map['accessCode'] = _encryptionService.encrypt(parent.accessCode); // Can change

    await _parentsCollection.doc(parent.id).update(map);
  }

  Future<void> deleteParent(String parentId) async {
    await _parentsCollection.doc(parentId).delete();
  }
}
