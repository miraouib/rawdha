import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../models/student_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _paymentsCollection => _firestore.collection('payments');
  CollectionReference get _studentsCollection => _firestore.collection('students');

  /// Vérifier si un paiement existe déjà pour ce parent, ce mois et cette année
  Future<bool> checkPaymentExists(String rawdhaId, String parentId, int month, int year) async {
    final snapshot = await _paymentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('parentId', isEqualTo: parentId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .limit(1)
        .get();
        
    return snapshot.docs.isNotEmpty;
  }

  /// Ajouter un paiement
  Future<void> addPayment(String rawdhaId, PaymentModel payment) async {
    // Vérifier s'il existe déjà un paiement pour ce parent/mois/année et mettre à jour ou ajouter ?
    // Simplification : On ajoute un nouveau doc. Si on veut cumuler, il faudrait lire avant.
    // Ici on suppose un paiement unique par mois ou des ajouts. pour l'instant simple add.
    await _paymentsCollection.add(payment.toFirestore());
  }

  /// Récupérer les revenus pour un mois donné dans une rawdha
  Stream<List<PaymentModel>> getPaymentsByMonth(String rawdhaId, int month, int year) {
    return _paymentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((p) => p.month == month && p.year == year)
          .toList();
    });
  }

  /// Récupérer l'historique d'un parent
  Stream<List<PaymentModel>> getPaymentsByParent(String rawdhaId, String parentId) {
    return _paymentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((p) => p.parentId == parentId)
          .toList();
    });
  }

  /// Calculer le montant dû par un parent
  /// Si le parent a un 'monthlyFee' défini (forfait global/négocié), on l'utilise.
  /// Sinon, on fait la somme des 'monthlyFee' de ses enfants actifs.
  Future<double> calculateExpectedAmount(String rawdhaId, String parentId) async {
    // 1. Check Parent Level Fee
    final parentDoc = await _firestore.collection('parents').doc(parentId).get();
    if (parentDoc.exists) {
       final pData = parentDoc.data();
       if (pData != null && pData['monthlyFee'] != null) {
          final fee = (num.tryParse(pData['monthlyFee'].toString()) ?? 0).toDouble();
          if (fee > 0) return fee;
       }
    }

    // 2. Sum Children Fees
    final snapshot = await _studentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('parentIds', arrayContains: parentId)
        .where('active', isEqualTo: true) // Seuls les actifs paient
        .get();
    
    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (num.tryParse(data['monthlyFee']?.toString() ?? '0') ?? 0).toDouble();
    }
    return total;
  }

  /// Supprimer un paiement
  Future<void> deletePayment(String rawdhaId, String paymentId) async {
    await _paymentsCollection.doc(paymentId).delete();
  }
}
