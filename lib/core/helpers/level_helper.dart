import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Helper pour obtenir le nom traduit d'un niveau
class LevelHelper {
  static String getLevelName(String levelId, BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    
    // Extract base level ID (e.g., 'level_3' from 'rawdhaId_level_3')
    final baseId = levelId.split('_').last;
    
    // Map level IDs to translation keys in JSON files
    final translationKey = 'levels.level_$baseId';
    
    return translationKey.tr();
  }
}
