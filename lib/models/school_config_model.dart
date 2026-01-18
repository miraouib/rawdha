import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolConfigModel {
  final String id;
  final String rawdhaId; // Lien vers la Rawdha
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final Map<String, dynamic>? socialLinks;
  final String? schoolCode; // Unique School Code (e.g. ISRAA)
  final int paymentStartMonth; // Mois de début des calculs (1-12, default 9)
  final int? paymentStartYear; // Année de début (optionnel)
  final bool restrictDevices; // Restriction par appareil
  final DateTime? updatedAt;

  const SchoolConfigModel({
    this.id = 'default',
    required this.rawdhaId,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.socialLinks,
    this.schoolCode,
    this.paymentStartMonth = 9,
    this.paymentStartYear,
    this.restrictDevices = false,
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
      socialLinks: data['socialLinks'] as Map<String, dynamic>?,
      schoolCode: data['schoolCode'],
      paymentStartMonth: data['paymentStartMonth'] ?? 9,
      paymentStartYear: data['paymentStartYear'],
      restrictDevices: data['restrictDevices'] ?? false,
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
      'socialLinks': socialLinks,
      'schoolCode': schoolCode,
      'paymentStartMonth': paymentStartMonth,
      'paymentStartYear': paymentStartYear,
      'restrictDevices': restrictDevices,
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
    Map<String, dynamic>? socialLinks,
    String? rawdhaId,
    String? schoolCode,
    int? paymentStartMonth,
    int? paymentStartYear,
    bool? restrictDevices,
  }) {
    return SchoolConfigModel(
      id: id,
      rawdhaId: rawdhaId ?? this.rawdhaId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      schoolCode: schoolCode ?? this.schoolCode,
      paymentStartMonth: paymentStartMonth ?? this.paymentStartMonth,
      paymentStartYear: paymentStartYear ?? this.paymentStartYear,
      restrictDevices: restrictDevices ?? this.restrictDevices,
      updatedAt: updatedAt,
    );
  }
}
