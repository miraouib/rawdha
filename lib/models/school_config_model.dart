import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolConfigModel {
  final String id;
  final String rawdhaId; // Lien vers la Rawdha
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? registrationNumber;
  final Map<String, dynamic>? socialLinks;
  final DateTime? updatedAt;

  const SchoolConfigModel({
    this.id = 'default',
    required this.rawdhaId,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.registrationNumber,
    this.socialLinks,
    this.updatedAt,
  });

  /// Créer à partir de Firestore
  factory SchoolConfigModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SchoolConfigModel(
      id: id,
      rawdhaId: data['rawdhaId'] ?? 'default',
      name: data['name'] ?? 'Ma Maternelle',
      address: data['address'],
      phone: data['phone'],
      email: data['email'],
      logoUrl: data['logoUrl'],
      registrationNumber: data['registrationNumber'],
      socialLinks: data['socialLinks'] as Map<String, dynamic>?,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Convertir pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'rawdhaId': rawdhaId,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'registrationNumber': registrationNumber,
      'socialLinks': socialLinks,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Copie avec modification
  SchoolConfigModel copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? registrationNumber,
    Map<String, dynamic>? socialLinks,
    String? rawdhaId,
  }) {
    return SchoolConfigModel(
      id: id,
      rawdhaId: rawdhaId ?? this.rawdhaId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      socialLinks: socialLinks ?? this.socialLinks,
      updatedAt: updatedAt,
    );
  }
}
