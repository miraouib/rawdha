import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DateHelper {
  static String formatMonthYear(BuildContext context, DateTime date) {
    String formatted = DateFormat('MMMM yyyy', 'fr').format(date);
    return convertNumbers(context, formatted);
  }

  static String formatDateShort(BuildContext context, DateTime date) {
    String formatted = DateFormat('dd MMM', 'fr').format(date);
    return convertNumbers(context, formatted);
  }

  static String formatDateLong(BuildContext context, DateTime date) {
    String formatted = DateFormat('dd MMMM yyyy', 'fr').format(date);
    return convertNumbers(context, formatted);
  }

  static String formatDateFull(BuildContext context, DateTime date) {
    String formatted = DateFormat('EEEE d MMMM yyyy', 'fr').format(date);
    // Capitalize first letter
    formatted = formatted[0].toUpperCase() + formatted.substring(1);
    return convertNumbers(context, formatted);
  }

  static String convertNumbers(BuildContext context, String text) {
    // Force Western numerals (123...) even if the locale/system produces Arabic numerals (٠١٢...)
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const westernDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = text;
    for (int i = 0; i < arabicDigits.length; i++) {
        result = result.replaceAll(arabicDigits[i], westernDigits[i]);
    }
    return result;
  }
}
