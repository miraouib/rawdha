import 'package:shared_preferences/shared_preferences.dart';
import '../core/encryption/encryption_service.dart';
import '../../services/parent_service.dart';
import '../../features/auth/services/manager_auth_service.dart';

class SessionService {
  static const String _keyFamilyCode = 'parent_family_code';
  static const String _keyRawdhaId = 'parent_rawdha_id';
  static const String _keySchoolCode = 'parent_school_code';
  static const String _keyIsLoggedIn = 'parent_is_logged_in';
  
  static const String _keyManagerId = 'manager_id';
  static const String _keyUserType = 'user_type'; // 'parent' or 'manager'

  final ParentService _parentService = ParentService();
  final ManagerAuthService _managerAuthService = ManagerAuthService();
  final EncryptionService _encryptionService = EncryptionService();

  Future<void> saveSession(String schoolCode, String familyCode, String rawdhaId) async {
    final prefs = await SharedPreferences.getInstance();
    final upperFamilyCode = familyCode.toUpperCase();
    final upperSchoolCode = schoolCode.toUpperCase();
    
    await prefs.setString(_keySchoolCode, upperSchoolCode);
    await prefs.setString(_keyFamilyCode, upperFamilyCode);
    await prefs.setString(_keyRawdhaId, rawdhaId);
    await prefs.setString(_keyUserType, 'parent');
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  Future<void> saveManagerSession(String managerId, String rawdhaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyManagerId, managerId);
    await prefs.setString(_keyRawdhaId, rawdhaId);
    await prefs.setString(_keyUserType, 'manager');
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep familyCode/schoolCode/managerId for pre-fill if needed, but definitely clear login flag
    await prefs.setBool(_keyIsLoggedIn, false);
    // Optional: Clear user type to force selection next time
    await prefs.remove(_keyUserType);
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return {
      'familyCode': prefs.getString(_keyFamilyCode),
      'schoolCode': prefs.getString(_keySchoolCode),
      'managerId': prefs.getString(_keyManagerId),
      'userType': prefs.getString(_keyUserType),
    };
  }

  /// Returns ParentModel or ManagerModel or null
  /// For Manager, it performs FULL re-authentication using stored credentials
  Future<Object?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final userType = prefs.getString(_keyUserType);
    
    if (userType == 'manager') {
       // Perform full re-authentication for Managers
       final username = prefs.getString('remember_username');
       final encryptedPass = prefs.getString('remember_password_enc');

       if (username != null && encryptedPass != null) {
         try {
           final password = _encryptionService.decryptString(encryptedPass);
           return await _managerAuthService.login(username, password);
         } catch (e) {
           return null;
         }
       }
       return null; 
    } else {
       // Parent login remains simpler (uses stored school/family codes)
       final familyCode = prefs.getString(_keyFamilyCode);
       final schoolCode = prefs.getString(_keySchoolCode);
       
       if (familyCode != null && schoolCode != null) {
         return await _parentService.loginParent(schoolCode, familyCode);
       }
    }
    
    return null;
  }
}
