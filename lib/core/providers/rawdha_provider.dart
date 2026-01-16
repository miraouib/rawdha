import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rawdha_model.dart';
import '../../services/school_service.dart';

/// Provider pour l'ID de la Rawdha actuelle
final currentRawdhaIdProvider = StateProvider<String?>((ref) => null);

/// Provider pour les informations de la Rawdha actuelle (abonnement, etc.)
final currentRawdhaProvider = StreamProvider<RawdhaModel?>((ref) {
  final rawdhaId = ref.watch(currentRawdhaIdProvider);
  if (rawdhaId == null) return Stream.value(null);
  
  return SchoolService().getRawdhaById(rawdhaId);
});
