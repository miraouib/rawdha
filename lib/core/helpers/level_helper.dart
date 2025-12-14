import 'package:easy_localization/easy_localization.dart';

/// Helper pour obtenir le nom traduit d'un niveau
class LevelHelper {
  static String getLevelName(String levelId) {
    // Map level IDs to translation keys
    final translationKey = 'levels.$levelId';
    
    // Try to get the translation, fallback to levelId if not found
    try {
      return translationKey.tr();
    } catch (e) {
      // If translation not found, return the levelId as is
      return levelId;
    }
  }
}
