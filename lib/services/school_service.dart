import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/school_level_model.dart';
import '../../models/school_config_model.dart';

/// Service de gestion de l'école (Niveaux)
class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _levelsCollection => _firestore.collection('school_levels');
  CollectionReference get _configCollection => _firestore.collection('school_config');

  /// Initialiser les niveaux par défaut si inexistants
  Future<void> initializeDefaultLevels() async {
    final levels = [
      SchoolLevelModel(id: SchoolLevelModel.level3Id, name: '3 Ans (Petite)', order: 1, description: 'Petite section'),
      SchoolLevelModel(id: SchoolLevelModel.level4Id, name: '4 Ans (Moyenne)', order: 2, description: 'Moyenne section'),
      SchoolLevelModel(id: SchoolLevelModel.level5Id, name: '5 Ans (Grande)', order: 3, description: 'Grande section'),
    ];

    for (var level in levels) {
      final doc = await _levelsCollection.doc(level.id).get();
      if (!doc.exists) {
        await _levelsCollection.doc(level.id).set(level.toFirestore());
      }
    }
  }

  /// Récupérer tous les niveaux triés
  Stream<List<SchoolLevelModel>> getLevels() {
    return _levelsCollection.orderBy('order').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SchoolLevelModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }


  /// Récupérer la configuration de l'école
  Stream<SchoolConfigModel> getSchoolConfig() {
    return _configCollection.doc('main').snapshots().map((doc) {
      if (!doc.exists) {
        return const SchoolConfigModel(name: 'Ma Maternelle'); // Default
      }
      return SchoolConfigModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Sauvegarder la configuration de l'école
  Future<void> saveSchoolConfig(SchoolConfigModel config) async {
    await _configCollection.doc('main').set(config.toFirestore());
  }

  /// Téléverser le logo de l'école
  Future<String> uploadSchoolLogo(File imageFile) async {
    final ref = _storage.ref().child('school').child('logo.jpg');
    // On écrase toujours 'logo.jpg' pour économiser l'espace, ou on peut utiliser un ID unique
    // Pour une config école unique, écraser c'est bien.
    // Mais attention au cache. On va ajouter un timestamp.
    
    // Upload
    final uploadTask = await ref.putFile(imageFile);
    final url = await uploadTask.ref.getDownloadURL();
    return url;
  }
}
