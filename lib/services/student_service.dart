import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';



class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _studentsCollection => _firestore.collection('students');
  CollectionReference get _parentsCollection => _firestore.collection('parents');

  // Encryption service (placeholder if not fully implemented)
  // final _encryptionService = EncryptionService();

  /// Récupérer tous les élèves
  Stream<List<StudentModel>> getStudents() {
    return _studentsCollection
        .orderBy('firstName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StudentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Method getStudentsByClass removed as class concept is deprecated

  
  /// Récupérer les élèves d'un niveau
  Stream<List<StudentModel>> getStudentsByLevel(String levelId) {
    return _studentsCollection
        .where('levelId', isEqualTo: levelId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StudentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Récupérer les élèves d'un parent
  Stream<List<StudentModel>> getStudentsByParentId(String parentId) {
    return _studentsCollection
        .where('parentIds', arrayContains: parentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StudentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Ajouter un élève
  /// Met à jour la liste des étudiants chez le parent aussi si un parent est lié
  Future<void> addStudent(StudentModel student) async {
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
  Future<void> updateStudent(StudentModel student) async {
    // Check if parent IDs changed? complex logic.
    // For MVP, assume parents list is correct in model.
    // If parents changed, we need to handle removing from old parents and adding to new.
    // Simplifying: Just update student doc.
    await _studentsCollection.doc(student.studentId).update(student.toFirestore());
    
    // Ideally we ensure parent links are consistent, but for now rely on add/create flow.
  }

  /// Supprimer un élève
  Future<void> deleteStudent(String studentId, List<String> parentIds) async {
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
  Future<StudentModel?> getStudentById(String studentId) async {
    final doc = await _studentsCollection.doc(studentId).get();
    if (!doc.exists) return null;
    return StudentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }
}
