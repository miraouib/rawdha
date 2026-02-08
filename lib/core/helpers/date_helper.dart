import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DateHelper {
  static final Map<int, String> _tunisianMonths = {
    1: 'جانفي',
    2: 'فيفري',
    3: 'مارس',
    4: 'أفريل',
    5: 'ماي',
    6: 'جوان',
    7: 'جويلية',
    8: 'أوت',
    9: 'سبتمبر',
    10: 'أكتوبر',
    11: 'نوفمبر',
    12: 'ديسمبر',
  };

  static String getMonthName(BuildContext context, int month) {
    if (context.locale.languageCode == 'ar') {
      return _tunisianMonths[month] ?? '';
    }
    final date = DateTime(2024, month, 1);
    return DateFormat('MMM', 'fr').format(date);
  }

  static final Map<int, String> _arabicWeekdays = {
    1: 'الإثنين',
    2: 'الثلاثاء',
    3: 'الأربعاء',
    4: 'الخميس',
    5: 'الجمعة',
    6: 'السبت',
    7: 'الأحد',
  };

  static String formatMonthYear(BuildContext context, DateTime date) {
    if (context.locale.languageCode == 'ar') {
      return convertNumbers(
        context,
        '${_tunisianMonths[date.month]} ${date.year}',
      );
    }
    String formatted = DateFormat('MMMM yyyy', 'fr').format(date);
    return convertNumbers(context, formatted);
  }

  static String formatDateShort(BuildContext context, DateTime date) {
    if (context.locale.languageCode == 'ar') {
      return convertNumbers(
        context,
        '${date.day} ${_tunisianMonths[date.month]}',
      );
    }
    String formatted = DateFormat('dd MMM', 'fr').format(date);
    return convertNumbers(context, formatted);
  }

  static String formatDateLong(BuildContext context, DateTime date) {
    if (context.locale.languageCode == 'ar') {
      return convertNumbers(
        context,
        '${date.day} ${_tunisianMonths[date.month]} ${date.year}',
      );
    }
    String formatted = DateFormat('dd MMMM yyyy', 'fr').format(date);
    return convertNumbers(context, formatted);
  }

  static String formatDateFull(BuildContext context, DateTime date) {
    if (context.locale.languageCode == 'ar') {
      return convertNumbers(
        context,
        '${_arabicWeekdays[date.weekday]} ${date.day} ${_tunisianMonths[date.month]} ${date.year}',
      );
    }
    String formatted = DateFormat('EEEE d MMMM yyyy', 'fr').format(date);
    // Capitalize first letter
    if (formatted.isNotEmpty) {
      formatted = formatted[0].toUpperCase() + formatted.substring(1);
    }
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
