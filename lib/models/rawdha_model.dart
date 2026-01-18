import 'package:cloud_firestore/cloud_firestore.dart';

class RawdhaModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String registeredDeviceId;
  final bool accepter;
  final DateTime dateValide;
  final String? code; // Unique School Code directly on Rawdha for easier query

  RawdhaModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.registeredDeviceId,
    this.accepter = false,
    required this.dateValide,
    this.code,
  });

  factory RawdhaModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RawdhaModel(
      id: id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      registeredDeviceId: data['registeredDeviceId'] ?? '',
      accepter: data['accepter'] ?? false,
      dateValide: (data['dateValide'] as Timestamp?)?.toDate() ?? DateTime.now(),
      code: data['code'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'registeredDeviceId': registeredDeviceId,
      'accepter': accepter,
      'dateValide': Timestamp.fromDate(dateValide),
      'code': code,
    };
  }

  bool get isSubscriptionActive => DateTime.now().isBefore(dateValide);
}
