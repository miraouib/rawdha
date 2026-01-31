import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Utilitaires pour obtenir les informations de l'appareil
/// 
/// Utilisé pour le système d'autorisation des appareils managers
class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const String _deviceIdKey = 'unique_device_id';
  static const _uuid = Uuid();

  /// Obtient l'ID unique de l'appareil
  /// 
  /// Génère et stocke un UUID unique par installation d'application.
  /// Cet ID persiste même après redémarrage de l'app, mais sera réinitialisé
  /// si l'utilisateur désinstalle et réinstalle l'application.
  /// 
  /// Cet ID est utilisé pour le système d'autorisation des appareils
  static Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Vérifier si un ID existe déjà
      String? deviceId = prefs.getString(_deviceIdKey);
      
      if (deviceId == null || deviceId.isEmpty) {
        // Générer un nouvel UUID unique
        deviceId = _uuid.v4();
        
        // Sauvegarder pour les prochaines utilisations
        await prefs.setString(_deviceIdKey, deviceId);
      }
      
      return deviceId;
    } catch (e) {
      throw Exception('Impossible d\'obtenir l\'ID de l\'appareil: $e');
    }
  }

  /// Obtient le nom de l'appareil
  /// 
  /// Exemple: "Samsung Galaxy S21", "iPhone 13 Pro"
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Obtient les informations complètes de l'appareil
  /// 
  /// Retourne un Map avec toutes les informations utiles
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      final deviceId = await getDeviceId();
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'id': deviceId,
          'name': '${androidInfo.manufacturer} ${androidInfo.model}',
          'platform': 'Android',
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt.toString(),
          'buildId': androidInfo.id, // Build ID (version Android)
          'fingerprint': androidInfo.fingerprint, // Empreinte de l'appareil
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'id': deviceId,
          'name': iosInfo.name,
          'platform': 'iOS',
          'version': iosInfo.systemVersion,
          'model': iosInfo.model,
        };
      }
      return {
        'id': deviceId,
        'name': 'Unknown Device',
        'platform': 'Unknown',
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des infos appareil: $e');
    }
  }
}

