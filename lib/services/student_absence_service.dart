import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_absence_model.dart';

class StudentAbsenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'student_absences';

  /// Ajouter une absence
  Future<void> addAbsence(String rawdhaId, StudentAbsenceModel absence) async {
    try {
      await _firestore.collection(_collection).add(absence.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'absence: $e');
    }
  }

  /// Récupérer les absences d'un élève
  Stream<List<StudentAbsenceModel>> getAbsencesByStudent(String rawdhaId, String studentId) {
    return _firestore.collection(_collection)
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final absences = snapshot.docs
          .map((doc) => StudentAbsenceModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Sort in-memory to avoid Firestore composite index requirement
      absences.sort((a, b) => b.startDate.compareTo(a.startDate)); // Descending
      return absences;
    });
  }

  /// Récupérer les derniers signalements d'absence pour une rawdha
  Stream<List<StudentAbsenceModel>> getAllRecentAbsences(String rawdhaId, {int limit = 20}) {
    return _firestore.collection(_collection)
        .where('rawdhaId', isEqualTo: rawdhaId)
        .snapshots()
        .map((snapshot) {
      final absences = snapshot.docs
          .map((doc) => StudentAbsenceModel.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort in-memory to avoid Firestore composite index requirement
      absences.sort((a, b) => b.startDate.compareTo(a.startDate)); // Descending
      
      // Apply limit in-memory
      return absences.take(limit).toList();
    });
  }
}
