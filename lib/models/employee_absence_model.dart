/// Modèle pour une Absence d'employé
/// 
/// Gère les absences des employés avec dates et raison
class EmployeeAbsenceModel {
  final String absenceId;
  final String rawdhaId; // Lien vers la Rawdha
  final String employeeId;
  final DateTime startDate;
  final DateTime? endDate; // Null si l'absence est en cours
  final String reason; // Raison de l'absence (maladie, congé, etc.)
  final String type; // Type: 'sick', 'vacation', 'personal', 'other'

  EmployeeAbsenceModel({
    required this.absenceId,
    required this.rawdhaId,
    required this.employeeId,
    required this.startDate,
    this.endDate,
    required this.reason,
    required this.type,
  });

  /// Crée une Absence depuis Firestore
  factory EmployeeAbsenceModel.fromFirestore(Map<String, dynamic> data, String id) {
    return EmployeeAbsenceModel(
      absenceId: id,
      rawdhaId: data['rawdhaId'] ?? 'default',
      employeeId: data['employeeId'] ?? '',
      startDate: DateTime.parse(data['startDate']),
      endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
      reason: data['reason'] ?? '',
      type: data['type'] ?? 'other',
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'rawdhaId': rawdhaId,
      'employeeId': employeeId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'reason': reason,
      'type': type,
    };
  }

  /// Vérifie si l'absence est en cours aujourd'hui
  bool get isCurrentlyAbsent {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    
    if (endDate == null) {
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
  EmployeeAbsenceModel copyWith({
    String? absenceId,
    String? rawdhaId,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? type,
  }) {
    return EmployeeAbsenceModel(
      absenceId: absenceId ?? this.absenceId,
      rawdhaId: rawdhaId ?? this.rawdhaId,
      employeeId: employeeId ?? this.employeeId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      type: type ?? this.type,
    );
  }
}
