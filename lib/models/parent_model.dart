import 'package:cloud_firestore/cloud_firestore.dart';

class ParentModel {
  final String id;
  final String rawdhaId; // Lien vers la Rawdha
  final String firstName;
  final String lastName;
  final String phone; // Will be stored encrypted
  final String familyCode; // The (Letter + 5 digits) code - used as ID/Username
  final String spouseName;
  final String spousePhone;
  final double? monthlyFee; // Optional override for total monthly payment
  final List<String> studentIds;
  final DateTime createdAt;
  final bool isDeleted; // Soft delete

  ParentModel({
    required this.id,
    required this.rawdhaId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.familyCode,
    this.spouseName = '',
    this.spousePhone = '',
    this.monthlyFee,
    required this.studentIds,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory ParentModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ParentModel(
      id: id,
      rawdhaId: data['rawdhaId'] ?? 'default',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      familyCode: data['familyCode'] ?? '',
      spouseName: data['spouseName'] ?? '',
      spousePhone: data['spousePhone'] ?? '',
      monthlyFee: (data['monthlyFee'] as num?)?.toDouble(),
      studentIds: List<String>.from(data['studentIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rawdhaId': rawdhaId,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'familyCode': familyCode,
      'spouseName': spouseName,
      'spousePhone': spousePhone,
      'monthlyFee': monthlyFee,
      'studentIds': studentIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
    };
  }
}
