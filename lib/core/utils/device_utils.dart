import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Utilitaires pour obtenir les informations de l'appareil
/// 
/// Utilisé pour le système d'autorisation des appareils managers
class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Obtient l'ID unique de l'appareil
  /// 
  /// Sur Android: retourne androidId
  /// Sur iOS: retourne identifierForVendor
  /// 
  /// Cet ID est utilisé pour le système d'autorisation des appareils
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // Android ID unique
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown-ios';
      }
      return 'unknown-platform';
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
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'id': androidInfo.id,
          'name': '${androidInfo.manufacturer} ${androidInfo.model}',
          'platform': 'Android',
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt.toString(),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'id': iosInfo.identifierForVendor ?? 'unknown',
          'name': iosInfo.name,
          'platform': 'iOS',
          'version': iosInfo.systemVersion,
          'model': iosInfo.model,
        };
      }
      return {
        'id': 'unknown',
        'name': 'Unknown Device',
        'platform': 'Unknown',
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des infos appareil: $e');
    }
  }
}
