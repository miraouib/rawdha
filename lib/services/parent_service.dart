import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parent_model.dart';
import '../core/encryption/encryption_service.dart';
import '../services/student_service.dart';
import '../services/local_cache_service.dart';

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

  final _cacheService = LocalCacheService();

  /// Get parents for a given Rawdha (with caching)
  Future<List<ParentModel>> getParents(String rawdhaId, {bool forceRefresh = false}) async {
    // 1. Try Cache
    if (!forceRefresh) {
      final cachedData = await _cacheService.getParents(rawdhaId);
      if (cachedData != null) {
        return cachedData.map((data) => ParentModel.fromFirestore(data, data['id'] ?? '')).toList();
      }
    }

    // 2. Fetch from Firestore
    final snapshot = await _parentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('isDeleted', isEqualTo: false)
        .get();

    final parents = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is in the map for caching
      return ParentModel.fromFirestore(data, doc.id);
    }).toList();

    parents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 3. Save to Cache
    await _cacheService.saveParents(rawdhaId, parents.map((p) => p.toMap()..['id'] = p.id).toList());

    return parents;
  }

  /// Get archived parents (less frequent, can still use get())
  Future<List<ParentModel>> getArchivedParents(String rawdhaId) async {
    final snapshot = await _parentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('isDeleted', isEqualTo: true)
        .get();

    final parents = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ParentModel.fromFirestore(data, doc.id);
    }).toList();
    
    parents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return parents;
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

      // Check if archived/deleted parent exists
      final snapshotDeleted = await _parentsCollection
          .where('rawdhaId', isEqualTo: rawdhaId)
          .where('familyCode', isEqualTo: familyCode)
          .where('isDeleted', isEqualTo: true) 
          .limit(1)
          .get();

      if (snapshotDeleted.docs.isNotEmpty) {
        throw Exception('parent.account_archived'.tr());
      }
      
      throw Exception('parent.invalid_credentials'.tr());
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
    map['phone'] = _encryptionService.encryptString(parent.phone);
    if (parent.spousePhone.isNotEmpty) {
      map['spousePhone'] = _encryptionService.encryptString(parent.spousePhone);
    }
    // map['familyCode'] = _encryptionService.encrypt(parent.familyCode);
    // map['accessCode'] = _encryptionService.encrypt(parent.accessCode);

    await _parentsCollection.add(map);
    await _cacheService.invalidateParents(parent.rawdhaId);
  }

  Future<void> updateParent(ParentModel parent) async {
    final map = parent.toMap();
    // Encrypt sensitive data
    map['phone'] = _encryptionService.encryptString(parent.phone);
    if (parent.spousePhone.isNotEmpty) {
      map['spousePhone'] = _encryptionService.encryptString(parent.spousePhone);
    }
    // map['familyCode'] = _encryptionService.encrypt(parent.familyCode); // ID usually doesn't change?
    // map['accessCode'] = _encryptionService.encrypt(parent.accessCode); // Can change

    await _parentsCollection.doc(parent.id).update(map);
    await _cacheService.invalidateParents(parent.rawdhaId);
  }

  Future<void> deleteParentWithStudents(String rawdhaId, String parentId) async {
    final studentService = StudentService();
    
    // 1. Get all students for this parent
    final studentsSnapshot = await FirebaseFirestore.instance.collection('students')
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('parentIds', arrayContains: parentId)
        .get();

    // 2. Delete each student
    for (var doc in studentsSnapshot.docs) {
      final data = doc.data();
      final List<String> parentIds = List<String>.from(data['parentIds'] ?? []);
      
      await studentService.deleteStudent(rawdhaId, doc.id, parentIds);
    }

    // 3. Delete the parent
    await _parentsCollection.doc(parentId).delete();
    await _cacheService.invalidateParents(rawdhaId);
  }

  Future<void> deleteParent(String parentId) async {
    await _parentsCollection.doc(parentId).delete();
  }

  Future<void> deleteAllArchivedParents(String rawdhaId) async {
    final archivedParents = await getArchivedParents(rawdhaId);
    for (var parent in archivedParents) {
      await deleteParentWithStudents(rawdhaId, parent.id);
    }
  }
}
