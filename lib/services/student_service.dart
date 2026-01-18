import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';



class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _studentsCollection => _firestore.collection('students');
  CollectionReference get _parentsCollection => _firestore.collection('parents');

  // Encryption service (placeholder if not fully implemented)
  // final _encryptionService = EncryptionService();

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
          .where((s) => s.levelId == levelId)
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
  Future<void> addStudent(String rawdhaId, StudentModel student) async {
    // 1. Add student
    final docRef = await _studentsCollection.add(student.toFirestore());
    final studentId = docRef.id;

    // 2. Link to parents
    if (student.parentIds.isNotEmpty) {
      for (var parentId in student.parentIds) {
        await _parentsCollection.doc(parentId).update({
          'studentIds': FieldValue.arrayUnion([studentId])
        });
      }
    }
  }

  /// Mettre à jour un élève
  Future<void> updateStudent(String rawdhaId, StudentModel student) async {
    // Check if parent IDs changed? complex logic.
    // For MVP, assume parents list is correct in model.
    // If parents changed, we need to handle removing from old parents and adding to new.
    // Simplifying: Just update student doc.
    await _studentsCollection.doc(student.studentId).update(student.toFirestore());
    
    // Ideally we ensure parent links are consistent, but for now rely on add/create flow.
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
  }

  /// Récupérer un élève par ID
  Future<StudentModel?> getStudentById(String rawdhaId, String studentId) async {
    final doc = await _studentsCollection.doc(studentId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    if (data['rawdhaId'] != rawdhaId) return null;
    return StudentModel.fromFirestore(data, doc.id);
  }
}
