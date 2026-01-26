import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../services/local_cache_service.dart';
import '../services/parent_service.dart';



class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _studentsCollection => _firestore.collection('students');
  CollectionReference get _parentsCollection => _firestore.collection('parents');

  // Encryption service (placeholder if not fully implemented)
  // final _encryptionService = EncryptionService();
  final _cacheService = LocalCacheService();

  /// Récupérer tous les élèves d'une rawdha (actifs et non supprimés)
  Stream<List<StudentModel>> getStudents(String rawdhaId) {
    return _studentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('isDeleted', isEqualTo: false) // Exclude soft deleted
        .snapshots()
        .map((snapshot) {
      final students = snapshot.docs.map((doc) {
        return StudentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Sort in-memory
      students.sort((a, b) => a.firstName.compareTo(b.firstName));
      return students;
    });
  }

  // Method getStudentsByClass removed as class concept is deprecated

  
  /// Récupérer les élèves d'un niveau dans une rawdha
  Stream<List<StudentModel>> getStudentsByLevel(String rawdhaId, String levelId) {
    return _studentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('isDeleted', isEqualTo: false) // Filter
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StudentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((s) {
            // Flexible comparison: check if the base ID (e.g., 'level_5') matches
            final studentBaseLevelId = s.levelId.split('_').last;
            final targetBaseLevelId = levelId.split('_').last;
            return studentBaseLevelId == targetBaseLevelId;
          })
          .toList();
    });
  }

  /// Récupérer les élèves d'un parent (option de voir les supprimés pour restauration)
  Stream<List<StudentModel>> getStudentsByParentId(String rawdhaId, String parentId, {bool includeDeleted = false}) {
    var query = _studentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId);
        
    if (!includeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }
        
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StudentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((s) => s.parentIds.contains(parentId))
          .toList();
    });
  }

  /// Ajouter un élève
  /// Met à jour la liste des étudiants chez le parent aussi si un parent est lié
  /// Implémente la dénormalisation des infos du parent
  Future<void> addStudent(String rawdhaId, StudentModel student) async {
    // 0. Denormalization: Get parent info
    String? pName;
    String? pPhone;
    
    if (student.parentIds.isNotEmpty) {
      final parentService = ParentService();
      // Try to get from cache first via ParentService.getParents logic
      final parents = await parentService.getParents(rawdhaId);
      final parent = parents.where((p) => p.id == student.parentIds.first).firstOrNull;
      
      if (parent != null) {
        pName = '${parent.firstName} ${parent.lastName}';
        pPhone = parent.phone;
      }
    }

    final studentWithParentInfo = student.copyWith(
      parentName: pName,
      parentPhone: pPhone,
    );

    // 1. Add student
    final docRef = await _studentsCollection.add(studentWithParentInfo.toFirestore());
    final studentId = docRef.id;

    // 2. Link to parents
    if (studentWithParentInfo.parentIds.isNotEmpty) {
      for (var parentId in studentWithParentInfo.parentIds) {
        await _parentsCollection.doc(parentId).update({
          'studentIds': FieldValue.arrayUnion([studentId])
        });
      }
      // Since parent document changed (studentIds added), invalidate parent cache
      await _cacheService.invalidateParents(rawdhaId);
    }

    // 3. Invalidate student cache
    await _cacheService.invalidateStudents(rawdhaId);
  }

  /// Mettre à jour un élève
  Future<void> updateStudent(String rawdhaId, StudentModel student) async {
    await _studentsCollection.doc(student.studentId).update(student.toFirestore());
    await _cacheService.invalidateStudents(rawdhaId);
  }

  /// Supprimer un élève
  Future<void> deleteStudent(String rawdhaId, String studentId, List<String> parentIds) async {
    // 1. Remove from parents
    for (var parentId in parentIds) {
      await _parentsCollection.doc(parentId).update({
        'studentIds': FieldValue.arrayRemove([studentId])
      });
    }

    // 2. Delete student doc
    await _studentsCollection.doc(studentId).delete();
    
    // 3. Invalidate caches
    await _cacheService.invalidateStudents(rawdhaId);
    await _cacheService.invalidateParents(rawdhaId);
  }

  /// Récupérer un élève par ID
  Future<StudentModel?> getStudentById(String rawdhaId, String studentId) async {
    final doc = await _studentsCollection.doc(studentId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    if (data['rawdhaId'] != rawdhaId) return null;
    return StudentModel.fromFirestore(data, doc.id);
  }

  /// Supprimer TOUS les élèves et parents d'une rawdha (pour test/reset)
  Future<void> deleteAllStudentsAndParents(String rawdhaId) async {
     final batch = _firestore.batch();
     
     // 1. Get all students
     final studentsQuery = await _studentsCollection.where('rawdhaId', isEqualTo: rawdhaId).get();
     for (var doc in studentsQuery.docs) {
       batch.delete(doc.reference);
     }
     
     // 2. Get all parents
     final parentsQuery = await _parentsCollection.where('rawdhaId', isEqualTo: rawdhaId).get();
     for (var doc in parentsQuery.docs) {
       batch.delete(doc.reference);
     }
     
     await batch.commit();
     await _cacheService.invalidateStudents(rawdhaId);
     await _cacheService.invalidateParents(rawdhaId);
  }
}
