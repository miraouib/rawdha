import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DateHelper {
  static String formatMonthYear(BuildContext context, DateTime date) {
    String formatted = DateFormat('MMMM yyyy', context.locale.toString()).format(date);
    return convertNumbers(context, formatted);
  }

  static String formatDateShort(BuildContext context, DateTime date) {
    String formatted = DateFormat('dd MMM', context.locale.toString()).format(date);
    return convertNumbers(context, formatted);
  }

  static String convertNumbers(BuildContext context, String text) {
    if (context.locale.languageCode == 'ar') {
      const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      return text.replaceAllMapped(RegExp(r'\d'), (match) {
        final digit = int.parse(match.group(0)!);
        return arabicDigits[digit];
      });
    }
    return text;
  }
}
