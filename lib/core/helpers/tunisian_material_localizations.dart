import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

class TunisianMaterialLocalizations extends GlobalMaterialLocalizations {
  const TunisianMaterialLocalizations({
    super.localeName = 'ar',
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

  static const List<String> _months = [
    'جانفي',
    'فيفري',
    'مارس',
    'أفريل',
    'ماي',
    'جوان',
    'جويلية',
    'أوت',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const List<String> _weekdays = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  String get anteMeridiemAbbreviation => 'ص';

  @override
  String get postMeridiemAbbreviation => 'م';

  @override
  List<String> getNarrowWeekdays() => ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];

  @override
  List<String> getMonths() => _months;

  @override
  String formatMediumDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  String formatMonthYear(DateTime date) {
    return '${_months[date.month - 1]} ${date.year}';
  }

  @override
  String formatFullDate(DateTime date) {
    return '${_weekdays[date.weekday % 7]} ${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  @override
  String formatShortMonthDay(DateTime date) {
    return '${date.day} ${_months[date.month - 1]}';
  }

  @override
  String formatYear(DateTime date) => '${date.year}';

  @override
  String get cancelButtonLabel => 'إلغاء';

  @override
  String get okButtonLabel => 'موافق';

  @override
  String get datePickerHelpText => 'اختيار التاريخ';

  @override
  String get dateRangePickerHelpText => 'اختيار الفترة';

  @override
  String get selectYearSemanticsLabel => 'اختيار السنة';

  @override
  String get dateInputLabel => 'أدخل التاريخ';

  @override
  String get dateRangeStartLabel => 'تاريخ البداية';

  @override
  String get dateRangeEndLabel => 'تاريخ النهاية';

  @override
  String get invalidDateFormatLabel => 'تنسيق غير صالح.';

  @override
  String get invalidDateRangeLabel => 'فترة غير صالحة.';

  @override
  String get invalidTextLabel => 'نص غير صالح.';

  @override
  String get dateHelpText => 'يوم/شهر/سنة';

  @override
  String get saveButtonLabel => 'حفظ';

  @override
  String get calendarModeButtonLabel => 'التبديل إلى التقويم';

  @override
  String get dateOutOfRangeLabel => 'التاريخ خارج النطاق.';

  @override
  String get datePickerHourSemanticsLabel => 'اختيار الساعة';

  @override
  String get datePickerMinuteSemanticsLabel => 'اختيار الدقائق';

  @override
  String get dateSeparator => '/';

  @override
  String get dialModeButtonLabel => 'التبديل إلى وضع اختيار الأرقام';

  @override
  String get inputDateModeButtonLabel => 'التبديل إلى الإدخال النصي';

  @override
  String get inputTimeModeButtonLabel => 'التبديل إلى إدخال النص';

  @override
  String get licensesPackageDetailTextOne => 'حزمة واحدة من التراخيص';

  @override
  String get licensesPackageDetailTextOther => '\$licenseCount حزمة من التراخيص';

  @override
  String get licensesPageTitle => 'التراخيص';

  @override
  String get modalBarrierDismissLabel => 'إغلاق';

  @override
  String get nextMonthTooltip => 'الشهر التالي';

  @override
  String get nextPageTooltip => 'الصفحة التالية';

  @override
  String get openAppDrawerTooltip => 'فتح قائمة التنقل';

  @override
  String get popupMenuLabel => 'قائمة منبثقة';

  @override
  String get previousMonthTooltip => 'الشهر السابق';

  @override
  String get previousPageTooltip => 'الصفحة السابقة';

  @override
  String get refreshIndicatorSemanticLabel => 'تحديث';

  @override
  String get remainingTextFieldCharacterCountOne => 'متبقي حرف واحد';

  @override
  String get remainingTextFieldCharacterCountOther => 'متبقي \$remainingCount حرفًا';

  @override
  String get rowsPerPageTitle => 'عدد الصفوف في الصفحة:';

  @override
  String get searchFieldLabel => 'بحث';

  @override
  String get selectAllButtonLabel => 'اختيار الكل';

  @override
  String get signedInLabel => 'تم تسجيل الدخول';

  @override
  String get timePickerHourModeAnnouncement => 'اختيار الساعات';

  @override
  String get timePickerMinuteModeAnnouncement => 'اختيار الدقائق';

  @override
  String get viewLicensesButtonLabel => 'عرض التراخيص';

  @override
  List<String> getShortMonths() => _months;

  @override
  List<String> getShortWeekdays() => _weekdays;

  @override
  List<String> getFullWeekdays() => _weekdays;

  @override
  intl.NumberFormat get decimalFormat => intl.NumberFormat('#.##', 'en');

  @override
  intl.NumberFormat get twoDigitZeroPaddedFormat => intl.NumberFormat('00', 'en');

  @override
  String formatDecimal(int number) => number.toString();

  @override
  String formatCompactDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  String formatShortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  String get firstPageTooltip => 'الصفحة الأولى';

  @override
  String get lastPageTooltip => 'الصفحة الأخيرة';

  // Fixed: method signature
  @override
  TimeOfDayFormat timeOfDayFormat({bool alwaysUse24HourFormat = false}) {
     return alwaysUse24HourFormat ? TimeOfDayFormat.H_colon_mm : TimeOfDayFormat.h_colon_mm_space_a;
  }

  @override
  String get copyButtonLabel => 'نسخ';

  @override
  String get cutButtonLabel => 'قص';

  @override
  String get pasteButtonLabel => 'لصق';

  @override
  String get lookUpButtonLabel => 'بحث';

  @override
  String get menuBarMenuLabel => 'قائمة شريط القوائم';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyAltGraph => 'AltGr';

  @override
  String get keyboardKeyBackspace => 'Backspace';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyDelete => 'Del';

  @override
  String get keyboardKeyDone => 'تم';

  @override
  String get keyboardKeyEject => 'Eject';

  @override
  String get keyboardKeyEnd => 'End';

  @override
  String get keyboardKeyEnter => 'Enter';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyFn => 'Fn';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Ins';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaMac => 'Command';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyNumLock => 'Num Lock';

  @override
  String get keyboardKeyNumpad0 => 'Num 0';

  @override
  String get keyboardKeyNumpad1 => 'Num 1';

  @override
  String get keyboardKeyNumpad2 => 'Num 2';

  @override
  String get keyboardKeyNumpad3 => 'Num 3';

  @override
  String get keyboardKeyNumpad4 => 'Num 4';

  @override
  String get keyboardKeyNumpad5 => 'Num 5';

  @override
  String get keyboardKeyNumpad6 => 'Num 6';

  @override
  String get keyboardKeyNumpad7 => 'Num 7';

  @override
  String get keyboardKeyNumpad8 => 'Num 8';

  @override
  String get keyboardKeyNumpad9 => 'Num 9';

  @override
  String get keyboardKeyNumpadAdd => 'Num +';

  @override
  String get keyboardKeyNumpadComma => 'Num ,';

  @override
  String get keyboardKeyNumpadDecimal => 'Num .';

  @override
  String get keyboardKeyNumpadDivide => 'Num /';

  @override
  String get keyboardKeyNumpadEnter => 'Num Enter';

  @override
  String get keyboardKeyNumpadEqual => 'Num =';

  @override
  String get keyboardKeyNumpadMultiply => 'Num *';

  @override
  String get keyboardKeyNumpadParenLeft => 'Num (';

  @override
  String get keyboardKeyNumpadParenRight => 'Num )';

  @override
  String get keyboardKeyNumpadSubtract => 'Num -';

  @override
  String get keyboardKeyPageDown => 'PgDn';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeyPower => 'Power';

  @override
  String get keyboardKeyPrintScreen => 'Print Screen';

  @override
  String get keyboardKeyScrollLock => 'Scroll Lock';

  @override
  String get keyboardKeySelect => 'Select';

  @override
  String get keyboardKeySpace => 'Space';

  // Fixed: method signature
  @override
  String scrimOnTapHint(String modalRouteContentName) => 'إغلاق \$modalRouteContentName';

  @override
  String get bottomSheetLabel => 'صحيفة سفلية';

  @override
  String get collapsedIconTapHint => 'توسيع';

  @override
  String get expandedIconTapHint => 'طي';

  @override
  String get expansionTileCollapsedHint => 'انقر للتوسيع';

  @override
  String get expansionTileCollapsedTapHint => 'توسيع لمزيد من التفاصيل';

  @override
  String get expansionTileExpandedHint => 'انقر للطي';

  @override
  String get expansionTileExpandedTapHint => 'طي';

  @override
  String get scanTextButtonLabel => 'مسح النص برمجياً';

  @override
  String get searchMenuButtonLabel => 'بحث';

  @override
  String get selectedRowCountTitleOne => 'تم اختيار عنصر واحد';

  @override
  String get selectedRowCountTitleOther => 'تم اختيار \$selectedRowCount عنصرًا';

  @override
  String get shareButtonLabel => 'مشاركة';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.tall;

  @override
  String get aboutListTileTitleRaw => 'عن \$applicationName';

  @override
  String get dateRangeEndDateSemanticLabelRaw => 'تاريخ الانتهاء \$fullDate';

  @override
  String get dateRangeStartDateSemanticLabelRaw => 'تاريخ البدء \$fullDate';

  @override
  String get pageRowsInfoTitleApproximateRaw => 'صفوف \$firstRow–\$lastRow من حوالي \$rowCount';

  @override
  String get pageRowsInfoTitleRaw => 'صفوف \$firstRow–\$lastRow من \$rowCount';

  @override
  String get scrimOnTapHintRaw => 'إغلاق \$modalRouteContentName';

  @override
  String get tabLabelRaw => 'التبويب \$tabIndex من \$tabCount';

  @override
  TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.h_colon_mm_space_a;

  @override
  String get alertDialogLabel => 'تنبيه';

  @override
  String get backButtonTooltip => 'رجوع';

  @override
  String get clearButtonTooltip => 'مسح';

  @override
  String get closeButtonLabel => 'إغلاق';

  @override
  String get closeButtonTooltip => 'إغلاق';

  @override
  String get collapsedHint => 'موسع';

  @override
  String get continueButtonLabel => 'استمرار';

  @override
  String get currentDateLabel => 'اليوم';

  @override
  String get deleteButtonTooltip => 'حذف';

  @override
  String get dialogLabel => 'حوار';

  @override
  String get drawerLabel => 'قائمة التنقل';

  @override
  String get expandedHint => 'مطوي';

  @override
  String get hideAccountsLabel => 'اخفاء الحسابات';

  @override
  String get invalidTimeLabel => 'الوقت غير صالح';

  @override
  String get keyboardKeyChannelDown => 'القناة لأسفل';

  @override
  String get keyboardKeyChannelUp => 'القناة لأعلى';

  @override
  String get keyboardKeyMetaMacOs => 'Command';

  @override
  String get keyboardKeyPowerOff => 'إيقاف التشغيل';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get menuDismissLabel => 'تجاهل القائمة';

  @override
  String get moreButtonTooltip => 'المزيد';

  @override
  String get reorderItemDown => 'نقل لأسفل';

  @override
  String get reorderItemLeft => 'نقل لليسار';

  @override
  String get reorderItemRight => 'نقل لليمين';

  @override
  String get reorderItemToEnd => 'نقل للنهاية';

  @override
  String get reorderItemToStart => 'نقل للبداية';

  @override
  String get reorderItemUp => 'نقل لأعلى';

  @override
  String get scrimLabel => 'غشاء';

  @override
  String get searchWebButtonLabel => 'البحث في الويب';

  @override
  String get selectedDateLabel => 'التاريخ المختار';

  @override
  String get showAccountsLabel => 'إظهار الحسابات';

  @override
  String get showMenuTooltip => 'إظهار القائمة';

  @override
  String get timePickerDialHelpText => 'اختيار الوقت';

  @override
  String get timePickerHourLabel => 'ساعة';

  @override
  String get timePickerInputHelpText => 'أدخل الوقت';

  @override
  String get timePickerMinuteLabel => 'دقيقة';

  @override
  String get unspecifiedDate => 'تاريخ غير محدد';

  @override
  String get unspecifiedDateRange => 'فترة غير محددة';

  static Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
      TunisianMaterialLocalizations(
        fullYearFormat: intl.DateFormat('yyyy', 'en'),
        compactDateFormat: intl.DateFormat('dd/MM/yyyy', 'en'),
        shortDateFormat: intl.DateFormat('dd/MM/yyyy', 'en'),
        mediumDateFormat: intl.DateFormat('dd MMM yyyy', 'en'),
        longDateFormat: intl.DateFormat('dd MMMM yyyy', 'en'),
        yearMonthFormat: intl.DateFormat('MMMM yyyy', 'en'),
        shortMonthDayFormat: intl.DateFormat('MMM d', 'en'),
        decimalFormat: intl.NumberFormat('#.##', 'en'),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', 'en'),
      ),
    );
  }

  static const LocalizationsDelegate<MaterialLocalizations> delegate = _TunisianMaterialLocalizationsDelegate();
}

class _TunisianMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _TunisianMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<MaterialLocalizations> load(Locale locale) => TunisianMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_TunisianMaterialLocalizationsDelegate old) => false;
}
