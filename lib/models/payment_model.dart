import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  paid,    // Vert: Payé en totalité (>= montant dû)
  partial, // Orange: Payé partiellement (< montant dû)
  unpaid   // Rouge: Rien payé (Utilisé pour l'affichage, pas forcément stocké en base si pas de doc)
}

class PaymentModel {
  final String id;
  final String rawdhaId; // Lien vers la Rawdha
  final String parentId;
  final double amount;
  final double expectedAmount; // Le montant qui était dû ce mois-là (snapshot)
  final DateTime date;
  final int month; // 1-12
  final int year;
  final String? note;
  final DateTime createdAt;
  final String? parentName; // Denormalized
  final String? parentFamilyCode; // Denormalized

  PaymentModel({
    required this.id,
    required this.rawdhaId,
    required this.parentId,
    required this.amount,
    required this.expectedAmount,
    required this.date,
    required this.month,
    required this.year,
    this.note,
    required this.createdAt,
    this.parentName,
    this.parentFamilyCode,
  });

  PaymentStatus get status {
    // Use a small epsilon for floating point comparison
    const epsilon = 0.01;
    if (amount >= expectedAmount - epsilon) return PaymentStatus.paid;
    if (amount > 0) return PaymentStatus.partial;
    return PaymentStatus.unpaid;
  }

  factory PaymentModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PaymentModel(
      id: id,
      rawdhaId: data['rawdhaId'] ?? 'default',
      parentId: data['parentId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      expectedAmount: (data['expectedAmount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      month: data['month'] ?? DateTime.now().month,
      year: data['year'] ?? DateTime.now().year,
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      parentName: data['parentName'],
      parentFamilyCode: data['parentFamilyCode'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rawdhaId': rawdhaId,
      'parentId': parentId,
      'amount': amount,
      'expectedAmount': expectedAmount,
      'date': Timestamp.fromDate(date),
      'month': month,
      'year': year,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentName': parentName,
      'parentFamilyCode': parentFamilyCode,
    };
  }
}
