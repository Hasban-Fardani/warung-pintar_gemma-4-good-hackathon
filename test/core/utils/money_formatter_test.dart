import 'package:flutter_test/flutter_test.dart';
import 'package:warung_pintar_cimahi/core/utils/money_formatter.dart';

/// ACT-74: Unit test money_formatter (PRD §10.1).
///
/// Verifies:
/// - rupiahToSen conversion (string → int sen)
/// - senToDisplay conversion (int sen → display string)
/// - Pending display with tilde prefix
/// - Edge cases: empty, non-numeric, zero
/// - NEVER float — always int
void main() {
  group('MoneyFormatter.rupiahToSen', () {
    test('converts clean numeric string to sen', () {
      expect(MoneyFormatter.rupiahToSen('45000'), 4500000);
    });

    test('converts string with dots (thousand separator) to sen', () {
      expect(MoneyFormatter.rupiahToSen('45.000'), 4500000);
    });

    test('converts string with Rp prefix to sen', () {
      expect(MoneyFormatter.rupiahToSen('Rp 45.000'), 4500000);
    });

    test('returns 0 for empty string', () {
      expect(MoneyFormatter.rupiahToSen(''), 0);
    });

    test('returns 0 for non-numeric string', () {
      expect(MoneyFormatter.rupiahToSen('abc'), 0);
    });

    test('handles small values', () {
      expect(MoneyFormatter.rupiahToSen('100'), 10000);
    });

    test('handles large values without overflow', () {
      // Rp 999.999.999 → 99999999900 sen
      expect(MoneyFormatter.rupiahToSen('999999999'), 99999999900);
    });

    test('result is always int, never float', () {
      final result = MoneyFormatter.rupiahToSen('45000');
      expect(result, isA<int>());
    });
  });

  group('MoneyFormatter.senToDisplay', () {
    test('converts sen to formatted Rupiah display', () {
      expect(MoneyFormatter.senToDisplay(4500000), 'Rp 45.000');
    });

    test('displays zero correctly', () {
      expect(MoneyFormatter.senToDisplay(0), 'Rp 0');
    });

    test('displays small amount correctly', () {
      expect(MoneyFormatter.senToDisplay(10000), 'Rp 100');
    });

    test('uses integer division (truncates sub-rupiah)', () {
      // 4500050 sen ÷ 100 = 45000 (integer division truncates)
      expect(MoneyFormatter.senToDisplay(4500050), 'Rp 45.000');
    });
  });

  group('MoneyFormatter.senToPendingDisplay', () {
    test('adds tilde prefix for pending amounts (PRD §12.7)', () {
      expect(MoneyFormatter.senToPendingDisplay(4500000), '~Rp 45.000');
    });

    test('pending zero displays correctly', () {
      expect(MoneyFormatter.senToPendingDisplay(0), '~Rp 0');
    });
  });

  group('MoneyFormatter.senToNumeric', () {
    test('returns numeric string without currency symbol', () {
      expect(MoneyFormatter.senToNumeric(4500000), '45.000');
    });

    test('returns 0 for zero sen', () {
      expect(MoneyFormatter.senToNumeric(0), '0');
    });
  });
}
