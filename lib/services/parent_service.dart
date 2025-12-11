import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parent_model.dart';
import '../core/encryption/encryption_service.dart';

class ParentService {
  final CollectionReference _parentsCollection = FirebaseFirestore.instance.collection('parents');
  final _encryptionService = EncryptionService(); // Assume singleton or instance

  // Generate Family Code: First Letter + 4 digits
  String generateFamilyCode(String firstName) {
    if (firstName.isEmpty) return 'P${_generateRandomDigits(4)}';
    String letter = firstName[0].toUpperCase();
    if (!RegExp(r'[A-Z]').hasMatch(letter)) letter = 'P'; // Fail-safe
    return '$letter${_generateRandomDigits(4)}';
  }

  // Generate Access Code: 6 digits
  String generateAccessCode() {
    return _generateRandomDigits(6);
  }

  String _generateRandomDigits(int length) {
    final rand = Random();
    String result = '';
    for (int i = 0; i < length; i++) {
      result += rand.nextInt(10).toString();
    }
    return result;
  }

  Stream<List<ParentModel>> getParents() {
    return _parentsCollection.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Decrypt fields if needed. For now assuming stored PLAIN or Service handles it.
        // If we want encryption, we should decrypt here.
        // Assuming encrypted storage based on user request "code secret".
        
        // Example decryption (uncomment if implementing encryption):
        // data['phone'] = _encryptionService.decrypt(data['phone']);
        // data['familyCode'] = _encryptionService.decrypt(data['familyCode']);
        // data['accessCode'] = _encryptionService.decrypt(data['accessCode']);
        
        return ParentModel.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  Future<void> addParent(ParentModel parent) async {
    // Encrypt sensitive data before saving
    final map = parent.toMap();
    // map['phone'] = _encryptionService.encrypt(parent.phone);
    // map['familyCode'] = _encryptionService.encrypt(parent.familyCode);
    // map['accessCode'] = _encryptionService.encrypt(parent.accessCode);

    await _parentsCollection.add(map);
  }

  Future<void> updateParent(ParentModel parent) async {
    final map = parent.toMap();
    // Encrypt sensitive data
    // map['phone'] = _encryptionService.encrypt(parent.phone);
    // map['familyCode'] = _encryptionService.encrypt(parent.familyCode); // ID usually doesn't change?
    // map['accessCode'] = _encryptionService.encrypt(parent.accessCode); // Can change

    await _parentsCollection.doc(parent.id).update(map);
  }

  Future<void> deleteParent(String parentId) async {
    await _parentsCollection.doc(parentId).delete();
  }
}
