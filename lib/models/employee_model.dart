/// Modèle pour un Employé
/// 
/// Contient les informations d'un employé avec salaire chiffré
class EmployeeModel {
  final String employeeId;
  final String firstName;
  final String lastName;
  final String encryptedPhone; // Téléphone chiffré
  final String encryptedSalary; // Salaire chiffré
  final String role; // Poste (enseignant, assistant, etc.)
  final DateTime? birthdate;
  final DateTime hireDate; // Date d'embauche
  final String? photoUrl;

  EmployeeModel({
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.encryptedPhone,
    required this.encryptedSalary,
    required this.role,
    this.birthdate,
    required this.hireDate,
    this.photoUrl,
  });

  /// Crée un Employé depuis Firestore
  factory EmployeeModel.fromFirestore(Map<String, dynamic> data, String id) {
    return EmployeeModel(
      employeeId: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      encryptedPhone: data['encryptedPhone'] ?? '',
      encryptedSalary: data['encryptedSalary'] ?? '',
      role: data['role'] ?? '',
      birthdate: data['birthdate'] != null 
          ? DateTime.parse(data['birthdate']) 
          : null,
      hireDate: DateTime.parse(data['hireDate']),
      photoUrl: data['photoUrl'],
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'encryptedPhone': encryptedPhone,
      'encryptedSalary': encryptedSalary,
      'role': role,
      'birthdate': birthdate?.toIso8601String(),
      'hireDate': hireDate.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  /// Nom complet
  String get fullName => '$firstName $lastName';

  /// Copie avec modifications
  EmployeeModel copyWith({
    String? employeeId,
    String? firstName,
    String? lastName,
    String? encryptedPhone,
    String? encryptedSalary,
    String? role,
    DateTime? birthdate,
    DateTime? hireDate,
    String? photoUrl,
  }) {
    return EmployeeModel(
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      encryptedPhone: encryptedPhone ?? this.encryptedPhone,
      encryptedSalary: encryptedSalary ?? this.encryptedSalary,
      role: role ?? this.role,
      birthdate: birthdate ?? this.birthdate,
      hireDate: hireDate ?? this.hireDate,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
