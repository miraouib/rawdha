import 'package:shared_preferences/shared_preferences.dart';
import '../../models/parent_model.dart';
import '../../services/parent_service.dart';

class SessionService {
  static const String _keyFamilyCode = 'parent_family_code';
  static const String _keyAccessCode = 'parent_access_code';
  static const String _keyRawdhaId = 'parent_rawdha_id';
  static const String _keyIsLoggedIn = 'parent_is_logged_in';

  final ParentService _parentService = ParentService();

  Future<void> saveSession(String familyCode, String accessCode, String rawdhaId) async {
    final prefs = await SharedPreferences.getInstance();
    final upperFamilyCode = familyCode.toUpperCase();
    bool s1 = await prefs.setString(_keyFamilyCode, upperFamilyCode);
    bool s2 = await prefs.setString(_keyAccessCode, accessCode);
    bool s3 = await prefs.setString(_keyRawdhaId, rawdhaId);
    bool s4 = await prefs.setBool(_keyIsLoggedIn, true);
    print('SessionService: Saved session ($upperFamilyCode, $accessCode, $rawdhaId) -> success: ${s1 && s2 && s3 && s4}');
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep familyCode and accessCode to allow pre-filling fields
    await prefs.setBool(_keyIsLoggedIn, false);
    print('SessionService: Logged out (credentials kept for pre-fill)');
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final familyCode = prefs.getString(_keyFamilyCode);
    final accessCode = prefs.getString(_keyAccessCode);
    print('SessionService: getSavedCredentials found $familyCode / $accessCode');
    return {
      'familyCode': familyCode,
      'accessCode': accessCode,
    };
  }

  Future<ParentModel?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    print('SessionService: tryAutoLogin isLoggedIn=$isLoggedIn');
    if (!isLoggedIn) return null;

    final familyCode = prefs.getString(_keyFamilyCode);
    final accessCode = prefs.getString(_keyAccessCode);
    print('SessionService: Found credentials: $familyCode / $accessCode');

    if (familyCode != null && accessCode != null) {
      return await _parentService.loginParent(familyCode, accessCode);
    }
    return null;
  }
}
