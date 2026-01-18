import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rawdha_model.dart';
import '../../models/school_config_model.dart';
import '../../services/school_service.dart';

/// Provider pour l'ID de la Rawdha actuelle
final currentRawdhaIdProvider = StateProvider<String?>((ref) => null);

/// Provider pour l'ID du Manager connecté
final currentManagerIdProvider = StateProvider<String?>((ref) => null);

/// Provider pour le nom d'utilisateur du Manager connecté
final currentManagerUsernameProvider = StateProvider<String?>((ref) => null);

/// Provider pour les informations de la Rawdha actuelle (abonnement, etc.)
final currentRawdhaProvider = StreamProvider<RawdhaModel?>((ref) {
  final rawdhaId = ref.watch(currentRawdhaIdProvider);
  if (rawdhaId == null) return Stream.value(null);
  
  return SchoolService().getRawdhaById(rawdhaId);
});

/// Provider pour la configuration de l'école
final schoolConfigProvider = StreamProvider<SchoolConfigModel?>((ref) {
  final rawdhaId = ref.watch(currentRawdhaIdProvider);
  if (rawdhaId == null) return Stream.value(null);
  return SchoolService().getSchoolConfig(rawdhaId);
});
