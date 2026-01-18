import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parent_model.dart';
import '../core/encryption/encryption_service.dart';

class ParentService {
  final CollectionReference _parentsCollection = FirebaseFirestore.instance.collection('parents');
  final _encryptionService = EncryptionService(); // Assume singleton or instance

  // Generate Family Code: First Letter + 5 digits
  String generateFamilyCode(String firstName) {
    if (firstName.isEmpty) return 'P${_generateRandomDigits(5)}';
    String letter = firstName[0].toUpperCase();
    if (!RegExp(r'[A-Z]').hasMatch(letter)) letter = 'P'; // Fail-safe
    return '$letter${_generateRandomDigits(5)}';
  }


  String _generateRandomDigits(int length) {
    final rand = Random();
    String result = '';
    for (int i = 0; i < length; i++) {
      result += rand.nextInt(10).toString();
    }
    return result;
  }

    /// Stream of active parents for a given Rawdha
  Stream<List<ParentModel>> getParents(String rawdhaId) {
    return _parentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final parents = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ParentModel.fromFirestore(data, doc.id);
      }).toList();
      parents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return parents;
    });
  }

  /// Stream of archived (soft deleted) parents for a given Rawdha
  Stream<List<ParentModel>> getArchivedParents(String rawdhaId) {
    return _parentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final parents = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ParentModel.fromFirestore(data, doc.id);
      }).toList();
      parents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return parents;
    });
  } 

  /// Vérifier les identifiants d'un parent
  /// Login with ONLY School Code + Family Code
  Future<ParentModel?> loginParent(String schoolCode, String familyCode) async {
    try {
      // 1. Find Rawdha by School Code
      final rawdhaQuery = await FirebaseFirestore.instance
          .collection('rawdhas')
          .where('code', isEqualTo: schoolCode.toUpperCase())
          .limit(1)
          .get();

      if (rawdhaQuery.docs.isEmpty) {
        throw Exception('Code école incorrect');
      }
      
      final rawdhaId = rawdhaQuery.docs.first.id;

      // 2. Find Parent by Family Code AND Rawdha ID
      final snapshot = await _parentsCollection
          .where('rawdhaId', isEqualTo: rawdhaId)
          .where('familyCode', isEqualTo: familyCode)
          .where('isDeleted', isEqualTo: false) // Ensure active
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return ParentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      throw Exception('Code famille introuvable pour cette école');
    } catch (e) {
      if (e is Exception) rethrow; // Pass specific messages
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
