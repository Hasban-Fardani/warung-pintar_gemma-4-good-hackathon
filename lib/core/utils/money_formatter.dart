import 'package:intl/intl.dart';

/// Integer Money Protocol (PRD §10.1).
///
/// ALL monetary values stored as int (sen = Rupiah × 100).
/// NEVER use float/double for money.
class MoneyFormatter {
  MoneyFormatter._();

  static final _formatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Convert Rupiah string to sen (integer).
  /// "45000" → 4500000
  static int rupiahToSen(String rupiah) {
    final cleaned = rupiah.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return int.parse(cleaned) * 100;
  }

  /// Convert sen (integer) to display string.
  /// 4500000 → "Rp 45.000"
  static String senToDisplay(int sen) {
    final rupiah = sen ~/ 100;
    return _formatter.format(rupiah);
  }

  /// Convert sen to pending display with tilde prefix (PRD §12.7).
  /// 4500000 → "~Rp 45.000"
  static String senToPendingDisplay(int sen) {
    final rupiah = sen ~/ 100;
    return '~${_formatter.format(rupiah)}';
  }

  /// Format sen with tabular-nums for numeric displays.
  /// Returns the raw numeric string without currency symbol.
  static String senToNumeric(int sen) {
    final rupiah = sen ~/ 100;
    return NumberFormat('#,###', 'id').format(rupiah);
  }
}
