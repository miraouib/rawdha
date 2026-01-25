import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/module_model.dart';
import 'notification_service.dart';

class ModuleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _modulesCollection => _firestore.collection('modules');

  /// Récupérer les modules d'un niveau, triés par date de début (plus récent en premier)
  Stream<List<ModuleModel>> getModulesForLevel(String rawdhaId, String levelId) {
    // Normalisation : S'assurer que le levelId a le préfixe rawdhaId
    // Cela permet de supporter les anciens élèves et de s'assurer que la requête est exacte.
    String queryLevelId = levelId;
    if (!levelId.startsWith(rawdhaId)) {
      queryLevelId = '${rawdhaId}_$levelId';
    }

    return _modulesCollection
        .where('levelId', isEqualTo: queryLevelId)
        // .where('rawdhaId', isEqualTo: rawdhaId) // Retiré pour éviter le besoin d'index composite
        .snapshots()
        .map((snapshot) {
      final modules = snapshot.docs.map((doc) {
        return ModuleModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      // Tri Chronologique (Ancien -> Récent)
      modules.sort((a, b) => a.startDate.compareTo(b.startDate));
      return modules;
    });
  }

  /// Récupérer le module ACTIF pour un niveau (basé sur la date)
  Stream<ModuleModel?> getActiveModule(String rawdhaId, String levelId) {
    return getModulesForLevel(rawdhaId, levelId).map((modules) {
      for (var module in modules) {
        if (module.isCurrentlyActive) {
          return module;
        }
      }
      return null;
    });
  }

  /// Ajouter un module (avec vérification de chevauchement)
  Future<void> addModule(ModuleModel module) async {
    final hasConflict = await _checkDateConflict(module.rawdhaId, module.levelId, module.startDate, module.endDate);
    if (hasConflict) {
      throw Exception('Il y a déjà un module actif sur cette période.');
    }
    await _modulesCollection.add(module.toFirestore());

    // Trigger Notification
    await NotificationService().sendNotification(
      rawdhaId: module.rawdhaId,
      title: 'Programme de la semaine / برنامج الأسبوع',
      body: module.title,
      type: 'module',
    );
  }

  /// Mettre à jour un module
  Future<void> updateModule(ModuleModel module) async {
    // Vérifier les conflits (en excluant le module lui-même)
    final hasConflict = await _checkDateConflict(module.rawdhaId, module.levelId, module.startDate, module.endDate, excludeModuleId: module.id);
    if (hasConflict) {
      throw Exception('Il y a déjà un module actif sur cette période.');
    }
    await _modulesCollection.doc(module.id).update(module.toFirestore());
  }

  /// Supprimer un module
  Future<void> deleteModule(String moduleId) async {
    await _modulesCollection.doc(moduleId).delete();
  }

  /// Vérifie s'il y a un chevauchement de dates pour un niveau donné
  Future<bool> _checkDateConflict(String rawdhaId, String levelId, DateTime start, DateTime end, {String? excludeModuleId}) async {
    // On récupère tous les modules du niveau
    // Optimisation possible : récupérer seulement ceux proches des dates concernées
    final snapshot = await _modulesCollection.where('rawdhaId', isEqualTo: rawdhaId).where('levelId', isEqualTo: levelId).get();
    
    for (var doc in snapshot.docs) {
      if (excludeModuleId != null && doc.id == excludeModuleId) continue;
      
      final data = doc.data() as Map<String, dynamic>;
      // Si les dates manquent (anciens modules ?), on ignore ou assume pas de conflit
      if (data['startDate'] == null || data['endDate'] == null) continue;

      final existingStart = (data['startDate'] as Timestamp).toDate();
      final existingEnd = (data['endDate'] as Timestamp).toDate();

      // Chevauchement si (StartA <= EndB) et (EndA >= StartB)
      // On compare les jours en ignorant les heures pour être précis
      final rangeStart = DateTime(start.year, start.month, start.day);
      final rangeEnd = DateTime(end.year, end.month, end.day);
      
      final otherStart = DateTime(existingStart.year, existingStart.month, existingStart.day);
      final otherEnd = DateTime(existingEnd.year, existingEnd.month, existingEnd.day);

      if ((rangeStart.isBefore(otherEnd) || rangeStart.isAtSameMomentAs(otherEnd)) && 
          (rangeEnd.isAfter(otherStart) || rangeEnd.isAtSameMomentAs(otherStart))) {
        return true;
      }
    }
    return false;
  }
}
