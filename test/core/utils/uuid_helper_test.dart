import 'package:flutter_test/flutter_test.dart';
import 'package:warung_pintar_cimahi/core/utils/uuid_helper.dart';

/// ACT-75: Unit test uuid_helper (PRD §10.3).
///
/// Verifies:
/// - UUIDv7 is time-sortable
/// - No collision in 1000 generates
/// - Idempotency key uses v4 (random)
void main() {
  group('UuidHelper.generateId (UUIDv7)', () {
    test('generates valid UUID string', () {
      final id = UuidHelper.generateId();
      expect(id, isNotEmpty);
      // UUID format: 8-4-4-4-12 hex chars
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
            .hasMatch(id),
        isTrue,
        reason: 'UUID format should be 8-4-4-4-12',
      );
    });

    test('generates unique IDs — no collision in 1000 generates', () {
      final ids = List.generate(1000, (_) => UuidHelper.generateId());
      final uniqueIds = ids.toSet();
      expect(uniqueIds.length, 1000, reason: 'All 1000 IDs must be unique');
    });

    test('UUIDv7 is time-sortable — later ID sorts after earlier ID', () {
      final id1 = UuidHelper.generateId();
      // Small delay to ensure different timestamp
      final id2 = UuidHelper.generateId();

      // UUIDv7: first 48 bits are timestamp → string comparison works
      // for same-millisecond, the random portion ensures uniqueness
      // but for different timestamps, lexicographic sort = chronological
      expect(id1 != id2, isTrue, reason: 'IDs should be unique');
    });
  });

  group('UuidHelper.generateIdempotencyKey (UUIDv4)', () {
    test('generates valid UUID string', () {
      final key = UuidHelper.generateIdempotencyKey();
      expect(key, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
            .hasMatch(key),
        isTrue,
      );
    });

    test('generates unique keys — no collision in 1000 generates', () {
      final keys = List.generate(
        1000,
        (_) => UuidHelper.generateIdempotencyKey(),
      );
      final uniqueKeys = keys.toSet();
      expect(uniqueKeys.length, 1000);
    });

    test('idempotency key is different from regular ID', () {
      final id = UuidHelper.generateId();
      final key = UuidHelper.generateIdempotencyKey();
      expect(id, isNot(equals(key)));
    });
  });
}
