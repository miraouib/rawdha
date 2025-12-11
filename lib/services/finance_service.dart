import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _expensesCollection => _firestore.collection('expenses');

  /// Ajouter une dépense
  Future<void> addExpense(ExpenseModel expense) async {
    await _expensesCollection.add(expense.toFirestore());
  }

  /// Récupérer les dépenses pour un mois donné (et année)
  Stream<List<ExpenseModel>> getExpensesByMonth(int month, int year) {
    // Calculer la date de début et de fin du mois
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));

    return _expensesCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Supprimer une dépense
  Future<void> deleteExpense(String id) async {
    await _expensesCollection.doc(id).delete();
  }
}
