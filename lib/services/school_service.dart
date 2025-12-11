import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/school_level_model.dart';
import '../../models/school_class_model.dart';

/// Service de gestion de l'école (Niveaux et Classes)
class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _levelsCollection => _firestore.collection('school_levels');
  CollectionReference get _classesCollection => _firestore.collection('school_classes');

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

  /// Récupérer les classes d'un niveau
  Stream<List<SchoolClassModel>> getClassesForLevel(String levelId) {
    return _classesCollection.where('levelId', isEqualTo: levelId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SchoolClassModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Créer une classe
  Future<void> createClass(SchoolClassModel schoolClass) async {
    await _classesCollection.add(schoolClass.toFirestore());
  }

  /// Mettre à jour une classe
  Future<void> updateClass(SchoolClassModel schoolClass) async {
    await _classesCollection.doc(schoolClass.id).update(schoolClass.toFirestore());
  }

  /// Supprimer une classe
  Future<void> deleteClass(String classId) async {
    // Vérifier si des élèves sont liés avant de supprimer ? (À faire plus tard)
    await _classesCollection.doc(classId).delete();
  }

  /// Compter le nombre de classes par niveau
  Future<int> countClassesInLevel(String levelId) async {
    final snapshot = await _classesCollection.where('levelId', isEqualTo: levelId).get();
    return snapshot.size;
  }
}
