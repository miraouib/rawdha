/// Modèle pour une Absence d'élève
/// 
/// Gère les absences des élèves avec dates et cause
class StudentAbsenceModel {
  final String absenceId;
  final String studentId;
  final DateTime startDate;
  final DateTime? endDate; // Null si l'absence est en cours
  final String cause; // Raison de l'absence

  StudentAbsenceModel({
    required this.absenceId,
    required this.studentId,
    required this.startDate,
    this.endDate,
    required this.cause,
  });

  /// Crée une Absence depuis Firestore
  factory StudentAbsenceModel.fromFirestore(Map<String, dynamic> data, String id) {
    return StudentAbsenceModel(
      absenceId: id,
      studentId: data['studentId'] ?? '',
      startDate: DateTime.parse(data['startDate']),
      endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
      cause: data['cause'] ?? '',
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'cause': cause,
    };
  }

  /// Vérifie si l'absence est en cours aujourd'hui
  bool get isCurrentlyAbsent {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    
    if (endDate == null) {
      // Absence sans date de fin - vérifier si elle a commencé
      return today.isAtSameMomentAs(start) || today.isAfter(start);
    }
    
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return (today.isAtSameMomentAs(start) || today.isAfter(start)) &&
           (today.isAtSameMomentAs(end) || today.isBefore(end));
  }

  /// Durée de l'absence en jours
  int get durationInDays {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }

  /// Copie avec modifications
  StudentAbsenceModel copyWith({
    String? absenceId,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    String? cause,
  }) {
    return StudentAbsenceModel(
      absenceId: absenceId ?? this.absenceId,
      studentId: studentId ?? this.studentId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cause: cause ?? this.cause,
    );
  }
}
