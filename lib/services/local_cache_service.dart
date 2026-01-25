import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const String _parentsKey = 'cached_parents';
  static const String _studentsKey = 'cached_students';
  static const String _timestampKeyPrefix = 'cache_ts_';
  
  // Cache duration: 25 days
  static const int _cacheDurationDays = 25;

  Future<void> saveParents(String rawdhaId, List<Map<String, dynamic>> data) async {
    await _saveData('$_parentsKey\_$rawdhaId', data);
  }

  Future<List<Map<String, dynamic>>?> getParents(String rawdhaId) async {
    return await _getData('$_parentsKey\_$rawdhaId');
  }

  Future<void> saveStudents(String rawdhaId, List<Map<String, dynamic>> data) async {
    await _saveData('$_studentsKey\_$rawdhaId', data);
  }

  Future<List<Map<String, dynamic>>?> getStudents(String rawdhaId) async {
    return await _getData('$_studentsKey\_$rawdhaId');
  }

  Future<void> clearCache(String rawdhaId) async {
    await invalidateParents(rawdhaId);
    await invalidateStudents(rawdhaId);
  }

  /// Clear ALL cache (for all rawdhas)
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    // Remove all cache-related keys
    for (var key in keys) {
      if (key.startsWith(_parentsKey) || 
          key.startsWith(_studentsKey) || 
          key.startsWith(_timestampKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> invalidateParents(String rawdhaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_parentsKey\_$rawdhaId');
    await prefs.remove('$_timestampKeyPrefix\$_parentsKey\_$rawdhaId');
  }

  Future<void> invalidateStudents(String rawdhaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_studentsKey\_$rawdhaId');
    await prefs.remove('$_timestampKeyPrefix\$_studentsKey\_$rawdhaId');
  }

  Future<void> _saveData(String key, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data, toEncodable: (nonEncodable) {
      if (nonEncodable is DateTime) {
        return nonEncodable.toIso8601String();
      }
      // Handle Firestore Timestamp if passed in data maps
      try {
        if (nonEncodable.runtimeType.toString() == 'Timestamp') {
          return (nonEncodable as dynamic).toDate().toIso8601String();
        }
      } catch (e) {
        // Not a timestamp or similar
      }
      return nonEncodable.toString();
    });
    await prefs.setString(key, jsonString);
    await prefs.setInt('$_timestampKeyPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Map<String, dynamic>>?> _getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    final timestamp = prefs.getInt('$_timestampKeyPrefix$key');

    if (jsonString == null || timestamp == null) return null;

    final cachedDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    // 25 days check
    if (now.difference(cachedDate).inDays >= _cacheDurationDays) {
      // Cache expired
      await prefs.remove(key);
      await prefs.remove('$_timestampKeyPrefix$key');
      return null;
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return null;
    }
  }
}
