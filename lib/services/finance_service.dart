import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _expensesCollection => _firestore.collection('expenses');

  /// Ajouter une dépense
  Future<void> addExpense(ExpenseModel expense) async {
    await _expensesCollection.add(expense.toFirestore());
  }

  /// Récupérer les dépenses pour un mois donné (et année) dans une rawdha
  Stream<List<ExpenseModel>> getExpensesByMonth(String rawdhaId, int month, int year) {
    // Calculer la date de début et de fin du mois
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));

    return _expensesCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      final expenses = snapshot.docs.map((doc) {
        return ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Sort in-memory (note: range queries still require a composite index on [rawdhaId, date])
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    });
  }

  /// Supprimer une dépense
  Future<void> deleteExpense(String id) async {
    await _expensesCollection.doc(id).delete();
  }
}
