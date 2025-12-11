import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

enum ExpenseType {
  salary,
  cleaning,
  schoolSupplies,
  rent,
  utilities, // Water, Electricity, Internet
  other
}

class ExpenseModel {
  final String id;
  final ExpenseType type;
  final double amount;
  final DateTime date;
  final String description;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.description = '',
    required this.createdAt,
  });

  String get typeLabel {
    switch (type) {
      case ExpenseType.salary: return 'finance.expense_types.salary'.tr();
      case ExpenseType.cleaning: return 'finance.expense_types.cleaning'.tr();
      case ExpenseType.schoolSupplies: return 'finance.expense_types.school_supplies'.tr();
      case ExpenseType.rent: return 'finance.expense_types.rent'.tr();
      case ExpenseType.utilities: return 'finance.expense_types.utilities'.tr();
      case ExpenseType.other: return 'finance.expense_types.other'.tr();
    }
  }

  factory ExpenseModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ExpenseModel(
      id: id,
      type: _parseType(data['type']),
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static ExpenseType _parseType(String? value) {
    if (value == null) return ExpenseType.other;
    try {
      return ExpenseType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return ExpenseType.other;
    }
  }
}
