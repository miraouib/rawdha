import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un Élève
/// 
/// Contient toutes les informations d'un élève
class StudentModel {
  final String studentId;
  final String rawdhaId; // Lien vers la Rawdha
  final String firstName;
  final String lastName;
  final String gender; // 'boy' ou 'girl'
  final List<String> parentIds; // IDs des parents
  final String levelId; // ID du niveau (Tamhidi, Ta7dhiri, etc.)
  final String encryptedMonthlyFee; // Frais mensuels chiffrés
  final double monthlyFee; // Frais mensuels (non chiffrés pour MVP)
  final DateTime? birthdate;
  final DateTime createdAt;
  final bool active;
  final bool isDeleted; // Soft delete
  final String? photoUrl; // URL de la photo (optionnel)
  final String? parentName; // Denormalized: Primary parent name
  final String? parentPhone; // Denormalized: Primary parent phone

  StudentModel({
    required this.studentId,
    required this.rawdhaId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.parentIds,
    required this.levelId,
    required this.encryptedMonthlyFee,
    this.monthlyFee = 0.0,
    this.birthdate,
    required this.createdAt,
    this.active = true,
    this.isDeleted = false,
    this.photoUrl,
    this.parentName,
    this.parentPhone,
  });

  /// Crée un Élève depuis Firestore
  factory StudentModel.fromFirestore(Map<String, dynamic> data, String id) {
    return StudentModel(
      studentId: id,
      rawdhaId: data['rawdhaId'] ?? 'default',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      gender: data['gender'] ?? 'boy',
      parentIds: List<String>.from(data['parentIds'] ?? []),
      levelId: data['levelId'] ?? '',
      encryptedMonthlyFee: data['encryptedMonthlyFee'] ?? '',
      monthlyFee: (data['monthlyFee'] ?? 0).toDouble(),
      birthdate: data['birthdate'] is Timestamp 
          ? (data['birthdate'] as Timestamp).toDate() 
          : (data['birthdate'] is String ? DateTime.tryParse(data['birthdate']) : null),
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : (data['createdAt'] is String 
              ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
              : DateTime.now()),
      active: data['active'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      photoUrl: data['photoUrl'],
      parentName: data['parentName'],
      parentPhone: data['parentPhone'],
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'rawdhaId': rawdhaId,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'parentIds': parentIds,
      'levelId': levelId,
      'encryptedMonthlyFee': encryptedMonthlyFee,
      'monthlyFee': monthlyFee,
      'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'active': active,
      'isDeleted': isDeleted,
      'photoUrl': photoUrl,
      'parentName': parentName,
      'parentPhone': parentPhone,
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
    String? rawdhaId,
    String? firstName,
    String? lastName,
    String? gender,
    List<String>? parentIds,
    String? levelId,
    String? encryptedMonthlyFee,
    double? monthlyFee,
    DateTime? birthdate,
    DateTime? createdAt,
    bool? active,
    bool? isDeleted,
    String? photoUrl,
    String? parentName,
    String? parentPhone,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      rawdhaId: rawdhaId ?? this.rawdhaId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      parentIds: parentIds ?? this.parentIds,
      levelId: levelId ?? this.levelId,
      encryptedMonthlyFee: encryptedMonthlyFee ?? this.encryptedMonthlyFee,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      birthdate: birthdate ?? this.birthdate,
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
      isDeleted: isDeleted ?? this.isDeleted,
      photoUrl: photoUrl ?? this.photoUrl,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
    );
  }
}
