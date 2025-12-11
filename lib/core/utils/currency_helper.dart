class CurrencyHelper {
  static const String currency = 'TND'; // Dinar Tunisien
  static const String currencyAr = 'د.ت'; // Dinar Tunisien en arabe
  
  static String formatAmount(double amount, {bool showCurrency = true}) {
    if (showCurrency) {
      return '${amount.toStringAsFixed(2)} $currency';
    }
    return amount.toStringAsFixed(2);
  }
  
  static String formatAmountInt(double amount, {bool showCurrency = true}) {
    if (showCurrency) {
      return '${amount.toStringAsFixed(0)} $currency';
    }
    return amount.toStringAsFixed(0);
  }
}
