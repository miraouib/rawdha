import 'package:shared_preferences/shared_preferences.dart';
import '../../models/parent_model.dart';
import '../../models/manager_model.dart'; // Import
import '../../services/parent_service.dart';
import '../../features/auth/services/manager_auth_service.dart'; // Import

class SessionService {
  static const String _keyFamilyCode = 'parent_family_code';
  static const String _keyAccessCode = 'parent_access_code';
  static const String _keyRawdhaId = 'parent_rawdha_id';
  static const String _keySchoolCode = 'parent_school_code';
  static const String _keyIsLoggedIn = 'parent_is_logged_in';
  
  static const String _keyManagerId = 'manager_id';
  static const String _keyUserType = 'user_type'; // 'parent' or 'manager'

  final ParentService _parentService = ParentService();
  final ManagerAuthService _managerAuthService = ManagerAuthService();

  Future<void> saveSession(String schoolCode, String familyCode, String rawdhaId) async {
    final prefs = await SharedPreferences.getInstance();
    final upperFamilyCode = familyCode.toUpperCase();
    final upperSchoolCode = schoolCode.toUpperCase();
    
    await prefs.setString(_keySchoolCode, upperSchoolCode);
    await prefs.setString(_keyFamilyCode, upperFamilyCode);
    await prefs.setString(_keyRawdhaId, rawdhaId);
    await prefs.setString(_keyUserType, 'parent');
    await prefs.setBool(_keyIsLoggedIn, true);
    print('SessionService: Saved PARENT session');
  }

  Future<void> saveManagerSession(String managerId, String rawdhaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyManagerId, managerId);
    await prefs.setString(_keyRawdhaId, rawdhaId);
    await prefs.setString(_keyUserType, 'manager');
    await prefs.setBool(_keyIsLoggedIn, true);
    print('SessionService: Saved MANAGER session');
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep familyCode/schoolCode/managerId for pre-fill if needed, but definitely clear login flag
    await prefs.setBool(_keyIsLoggedIn, false);
    // Optional: Clear user type to force selection next time
    await prefs.remove(_keyUserType);
    print('SessionService: Logged out');
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
  Future<Object?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final userType = prefs.getString(_keyUserType);
    
    if (userType == 'manager') {
       final managerId = prefs.getString(_keyManagerId);
       if (managerId != null) {
         return await _managerAuthService.loginWithId(managerId);
       }
    } else {
       // Default to parent or check explicit 'parent'
       final familyCode = prefs.getString(_keyFamilyCode);
       final schoolCode = prefs.getString(_keySchoolCode);
       
       if (familyCode != null && schoolCode != null) {
         return await _parentService.loginParent(schoolCode, familyCode);
       }
    }
    
    return null;
  }
}
