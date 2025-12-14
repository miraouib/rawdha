import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../models/student_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _paymentsCollection => _firestore.collection('payments');
  CollectionReference get _studentsCollection => _firestore.collection('students');

  /// Ajouter un paiement
  Future<void> addPayment(PaymentModel payment) async {
    // Vérifier s'il existe déjà un paiement pour ce parent/mois/année et mettre à jour ou ajouter ?
    // Simplification : On ajoute un nouveau doc. Si on veut cumuler, il faudrait lire avant.
    // Ici on suppose un paiement unique par mois ou des ajouts. pour l'instant simple add.
    await _paymentsCollection.add(payment.toFirestore());
  }

  /// Récupérer les revenus pour un mois donné
  Stream<List<PaymentModel>> getPaymentsByMonth(int month, int year) {
    return _paymentsCollection
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PaymentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Récupérer l'historique d'un parent
  Stream<List<PaymentModel>> getPaymentsByParent(String parentId) {
    return _paymentsCollection
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PaymentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Calculer le montant dû par un parent
  /// Si le parent a un 'monthlyFee' défini (forfait global/négocié), on l'utilise.
  /// Sinon, on fait la somme des 'monthlyFee' de ses enfants actifs.
  Future<double> calculateExpectedAmount(String parentId) async {
    // 1. Check Parent Level Fee
    final parentDoc = await _firestore.collection('parents').doc(parentId).get();
    if (parentDoc.exists) {
       final pData = parentDoc.data();
       if (pData != null && pData['monthlyFee'] != null && (pData['monthlyFee'] as num) > 0) {
         return (pData['monthlyFee'] as num).toDouble();
       }
    }

    // 2. Sum Children Fees
    final snapshot = await _studentsCollection
        .where('parentIds', arrayContains: parentId)
        .where('active', isEqualTo: true) // Seuls les actifs paient
        .get();
    
    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['monthlyFee'] ?? 0).toDouble();
    }
    return total;
  }

  /// Supprimer un paiement
  Future<void> deletePayment(String paymentId) async {
    await _paymentsCollection.doc(paymentId).delete();
  }
}
