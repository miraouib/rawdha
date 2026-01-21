import 'package:easy_localization/easy_localization.dart';

class ValidatorHelper {
  static String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'common.required'.tr();
    }
    
    // Remove any spaces or special characters if needed, 
    // but for now we expect exactly 8 digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length != 8) {
      return 'Format invalide (8 chiffres requis)';
    }
    
    if (value.length != 8) {
       return 'Format invalide (8 chiffres uniquement)';
    }

    return null;
  }
}
