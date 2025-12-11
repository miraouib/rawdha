import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un Élève
/// 
/// Contient toutes les informations d'un élève
class StudentModel {
  final String studentId;
  final String firstName;
  final String lastName;
  final String gender; // 'boy' ou 'girl'
  final List<String> parentIds; // IDs des parents
  final String levelId; // ID du niveau (Tamhidi, Ta7dhiri, etc.)
  final String classId; // ID de la classe
  final String encryptedMonthlyFee; // Frais mensuels chiffrés
  final double monthlyFee; // Frais mensuels (non chiffrés pour MVP)
  final DateTime? birthdate;
  final DateTime createdAt;
  final bool active;
  final String? photoUrl; // URL de la photo (optionnel)

  StudentModel({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.parentIds,
    required this.levelId,
    required this.classId,
    required this.encryptedMonthlyFee,
    this.monthlyFee = 0.0,
    this.birthdate,
    required this.createdAt,
    this.active = true,
    this.photoUrl,
  });

  /// Crée un Élève depuis Firestore
  factory StudentModel.fromFirestore(Map<String, dynamic> data, String id) {
    return StudentModel(
      studentId: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      gender: data['gender'] ?? 'boy',
      parentIds: List<String>.from(data['parentIds'] ?? []),
      levelId: data['levelId'] ?? '',
      classId: data['classId'] ?? '',
      encryptedMonthlyFee: data['encryptedMonthlyFee'] ?? '',
      monthlyFee: (data['monthlyFee'] ?? 0).toDouble(),
      birthdate: (data['birthdate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: data['active'] ?? true,
      photoUrl: data['photoUrl'],
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'parentIds': parentIds,
      'levelId': levelId,
      'classId': classId,
      'encryptedMonthlyFee': encryptedMonthlyFee,
      'monthlyFee': monthlyFee,
      'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'active': active,
      'photoUrl': photoUrl,
    };
  }

  /// Nom complet
  String get fullName => '$firstName $lastName';

  /// Avatar par défaut basé sur le genre
  String get defaultAvatar => gender == 'boy' 
      ? 'assets/images/student_boy_avatar.png'
      : 'assets/images/student_girl_avatar.png';

  /// Copie avec modifications
  StudentModel copyWith({
    String? studentId,
    String? firstName,
    String? lastName,
    String? gender,
    List<String>? parentIds,
    String? levelId,
    String? classId,
    String? encryptedMonthlyFee,
    double? monthlyFee,
    DateTime? birthdate,
    DateTime? createdAt,
    bool? active,
    String? photoUrl,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      parentIds: parentIds ?? this.parentIds,
      levelId: levelId ?? this.levelId,
      classId: classId ?? this.classId,
      encryptedMonthlyFee: encryptedMonthlyFee ?? this.encryptedMonthlyFee,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      birthdate: birthdate ?? this.birthdate,
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
