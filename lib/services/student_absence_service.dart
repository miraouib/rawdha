import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_absence_model.dart';

class StudentAbsenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'student_absences';

  /// Ajouter une absence
  Future<void> addAbsence(StudentAbsenceModel absence) async {
    try {
      await _firestore.collection(_collection).add(absence.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'absence: $e');
    }
  }

  /// Récupérer les absences d'un élève
  Stream<List<StudentAbsenceModel>> getAbsencesByStudent(String studentId) {
    return _firestore.collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentAbsenceModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Récupérer les 20 dernières absences signalées (pour le Manager)
  Stream<List<StudentAbsenceModel>> getAllRecentAbsences({int limit = 20}) {
    return _firestore.collection(_collection)
        .orderBy('startDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentAbsenceModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
