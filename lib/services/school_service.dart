import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/school_level_model.dart';
import '../../models/school_config_model.dart';
import '../../models/rawdha_model.dart';

/// Service de gestion de l'école (Niveaux)
class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _levelsCollection => _firestore.collection('school_levels');
  CollectionReference get _configCollection => _firestore.collection('school_config');
  CollectionReference get _rawdhasCollection => _firestore.collection('rawdhas');
  CollectionReference get _parentsCollection => _firestore.collection('parents');
  CollectionReference get _studentsCollection => _firestore.collection('students');

  /// Réinitialiser les données de l'école (Soft Delete)
  /// Met à jour tous les parents et élèves actifs à isDeleted = true
  Future<void> resetSchoolData(String rawdhaId) async {
    final batch = _firestore.batch();
    
    // 1. Soft Delete Parents
    final parentsQuery = await _parentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('isDeleted', isEqualTo: false)
        .get();

    for (var doc in parentsQuery.docs) {
      batch.update(doc.reference, {'isDeleted': true});
    }

    // 2. Soft Delete Students
    final studentsQuery = await _studentsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('isDeleted', isEqualTo: false)
        .get();

    for (var doc in studentsQuery.docs) {
      batch.update(doc.reference, {'isDeleted': true});
    }

    await batch.commit();
  }

  /// Restaurer un parent et ses enfants
  /// Met isDeleted = false et met à jour les niveaux des enfants
  Future<void> restoreParent(String parentId, Map<String, String> studentLevelUpdates) async {
    final batch = _firestore.batch();
    
    // 1. Restore Parent
    final parentRef = _parentsCollection.doc(parentId);
    batch.update(parentRef, {'isDeleted': false});

    // 2. Restore & Update Children
    for (var entry in studentLevelUpdates.entries) {
      final studentId = entry.key;
      final newLevelId = entry.value;
      
      final studentRef = _studentsCollection.doc(studentId);
      batch.update(studentRef, {
        'isDeleted': false,
        'levelId': newLevelId, // Update level for new year
      });
    }

    await batch.commit();
  }

  /// Récupérer les infos d'une Rawdha par ID
  Stream<RawdhaModel?> getRawdhaById(String id) {
    return _rawdhasCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RawdhaModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Initialiser les niveaux par défaut si inexistants pour une rawdha
  Future<void> initializeDefaultLevels(String rawdhaId) async {
    final levels = [
      SchoolLevelModel(
        id: '${rawdhaId}_level_3', 
        rawdhaId: rawdhaId, 
        nameAr: 'تمهيدي 1 (3 سنوات)', 
        nameFr: 'Petite Section (3 ans)',
        order: 1, 
        descriptionAr: 'أطفال 3 سنوات',
        descriptionFr: 'Enfants de 3 ans',
      ),
      SchoolLevelModel(
        id: '${rawdhaId}_level_4', 
        rawdhaId: rawdhaId, 
        nameAr: 'تمهيدي 2 (4 سنوات)', 
        nameFr: 'Moyenne Section (4 ans)',
        order: 2, 
        descriptionAr: 'أطفال 4 سنوات',
        descriptionFr: 'Enfants de 4 ans',
      ),
      SchoolLevelModel(
        id: '${rawdhaId}_level_5', 
        rawdhaId: rawdhaId, 
        nameAr: 'تحضيري (5 سنوات)', 
        nameFr: 'Grande Section (5 ans)',
        order: 3, 
        descriptionAr: 'أطفال 5 سنوات / تحضيري',
        descriptionFr: 'Enfants de 5 ans / Préparatoire',
      ),
    ];

    for (var level in levels) {
      final doc = await _levelsCollection.doc(level.id).get();
      if (!doc.exists) {
        await _levelsCollection.doc(level.id).set(level.toFirestore());
      }
    }
  }

  /// Récupérer tous les niveaux triés pour une rawdha
  Stream<List<SchoolLevelModel>> getLevels(String rawdhaId) {
    return _levelsCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .snapshots()
        .map((snapshot) {
      final levels = snapshot.docs.map((doc) {
        return SchoolLevelModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      // Sort in-memory to avoid Firestore composite index requirement
      levels.sort((a, b) => a.order.compareTo(b.order));
      return levels;
    });
  }


  /// Récupérer la configuration de l'école par rawdha
  Stream<SchoolConfigModel> getSchoolConfig(String rawdhaId) {
    return _configCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return SchoolConfigModel(rawdhaId: rawdhaId, name: 'Ma Maternelle'); // Default
      }
      final doc = snapshot.docs.first;
      return SchoolConfigModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Sauvegarder la configuration de l'école
  Future<void> saveSchoolConfig(SchoolConfigModel config, String rawdhaId) async {
    final docId = config.id == 'default' ? null : config.id;
    if (docId == null) {
      // Nouvelle config pour cette rawdha
      await _configCollection.add(config.toFirestore());
    } else {
      await _configCollection.doc(docId).set(config.toFirestore());
    }

    // Sync School Code to Rawdha Model for easier lookup
    if (config.schoolCode != null && config.schoolCode!.isNotEmpty) {
      await _rawdhasCollection.doc(rawdhaId).update({
        'code': config.schoolCode,
      });
    }
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
