import 'package:cloud_firestore/cloud_firestore.dart';

class DeveloperModel {
  final String id;
  final String nameAr;
  final String nameFr;
  final String? email;
  final String? phone;
  final String? bioAr;
  final String? bioFr;
  final String? photoUrl;
  final Map<String, dynamic>? socialLinks;
  final bool isUpdateAvailable;
  final String? updateUrl;

  DeveloperModel({
    required this.id,
    required this.nameAr,
    required this.nameFr,
    this.email,
    this.phone,
    this.bioAr,
    this.bioFr,
    this.photoUrl,
    this.socialLinks,
    this.isUpdateAvailable = false,
    this.updateUrl,
  });

  factory DeveloperModel.fromFirestore(Map<String, dynamic> data, String id) {
    return DeveloperModel(
      id: id,
      nameAr: data['nameAr'] ?? data['name'] ?? 'Développeur',
      nameFr: data['nameFr'] ?? data['name'] ?? 'Développeur',
      email: data['email'],
      phone: data['phone'],
      bioAr: data['bioAr'] ?? data['bio'],
      bioFr: data['bioFr'] ?? data['bio'],
      photoUrl: data['photoUrl'],
      socialLinks: data['socialLinks'] as Map<String, dynamic>?,
      isUpdateAvailable: data['isUpdateAvailable'] ?? false,
      updateUrl: data['updateUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameAr': nameAr,
      'nameFr': nameFr,
      'email': email,
      'phone': phone,
      'bioAr': bioAr,
      'bioFr': bioFr,
      'photoUrl': photoUrl,
      'socialLinks': socialLinks,
      'isUpdateAvailable': isUpdateAvailable,
      'updateUrl': updateUrl,
    };
  }
}
