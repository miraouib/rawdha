import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/developer_model.dart';

class DeveloperService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get developer info from 'developpeur' collection
  /// Assuming there's only one main developer record or we take the first one
  Stream<DeveloperModel?> getDeveloperInfo() {
    return _firestore
        .collection('developpeur')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first; // Get prime developer
      return DeveloperModel.fromFirestore(doc.data(), doc.id);
    });
  }

  Future<void> seedDeveloperData() async {
    final snapshot = await _firestore.collection('developpeur').limit(1).get();
    if (snapshot.docs.isEmpty) {
      await _firestore.collection('developpeur').add({
        'nameAr': 'فريق روضتي',
        'nameFr': 'Rawdhati Team',
        'email': 'support@rawdhati.com',
        'phone': '+213123456789',
        'bioAr': 'فريق تطوير شغوف بالتعليم والتكنولوجيا.',
        'bioFr': 'Équipe de développement passionnée par l\'éducation et la technologie.',
        'photoUrl': 'https://firebasestorage.googleapis.com/v0/b/safe-kids-7f0b5.appspot.com/o/developer%2Flogo_dev.png?alt=media',
        'socialLinks': {
          'facebook': 'https://facebook.com/rawdhati',
          'linkedin': 'https://linkedin.com/company/rawdhati',
        },
      });
    }
  }
}
