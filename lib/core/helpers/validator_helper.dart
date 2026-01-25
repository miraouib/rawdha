import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class ValidatorHelper {
  static String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'common.required'.tr();
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length != 8) {
      return 'format_invalid_8_digits'.tr(); // Note: Translation key should be added or used
    }
    
    // Check if it's strictly numbers and exactly 8
    if (value.length != 8 || !RegExp(r'^\d{8}$').hasMatch(value)) {
       return 'format_invalid_8_digits_only'.tr();
    }

    return null;
  }

  static List<TextInputFormatter> phoneFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(8),
    ];
  }
}
