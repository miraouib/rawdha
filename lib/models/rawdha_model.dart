import 'package:cloud_firestore/cloud_firestore.dart';

class RawdhaModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String registeredDeviceId;
  final bool accepter;
  final DateTime dateValide;

  RawdhaModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.registeredDeviceId,
    this.accepter = false,
    required this.dateValide,
  });

  factory RawdhaModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RawdhaModel(
      id: id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      registeredDeviceId: data['registeredDeviceId'] ?? '',
      accepter: data['accepter'] ?? false,
      dateValide: (data['dateValide'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'registeredDeviceId': registeredDeviceId,
      'accepter': accepter,
      'dateValide': Timestamp.fromDate(dateValide),
    };
  }

  bool get isSubscriptionActive => DateTime.now().isBefore(dateValide);
}
