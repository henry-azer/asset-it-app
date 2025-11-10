import 'package:intl/intl.dart';

class NumberFormatter {
  static final _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  static final _wholeNumberFormat = NumberFormat('#,##0', 'en_US');
  static final _decimalFormat = NumberFormat('#,##0.##', 'en_US');

  static String formatCurrency(double value, {bool showDecimals = true}) {
    if (showDecimals) {
      return _currencyFormat.format(value);
    }
    return _wholeNumberFormat.format(value);
  }

  static String formatNumber(double value, {int? decimalPlaces}) {
    if (decimalPlaces != null) {
      return NumberFormat('#,##0.${'0' * decimalPlaces}', 'en_US').format(value);
    }
    return _decimalFormat.format(value);
  }

  static String formatWithSymbol(double value, {String symbol = '\$', bool showDecimals = true}) {
    final formatted = formatCurrency(value, showDecimals: showDecimals);
    return '$symbol$formatted';
  }

  static String formatGainLoss(double value, {bool showDecimals = false}) {
    final formatted = formatCurrency(value.abs(), showDecimals: showDecimals);
    final sign = value >= 0 ? '+' : '-';
    return '$sign\$$formatted';
  }

  static String formatCompactCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }
}
