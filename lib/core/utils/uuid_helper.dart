import 'package:uuid/uuid.dart';

/// UUID helper for offline-first primary keys (PRD §10.3).
///
/// UUIDv7 (time-sortable) — never use AUTOINCREMENT.
/// Safe for future cloud sync (zero collision risk).
class UuidHelper {
  UuidHelper._();

  static const _uuid = Uuid();

  /// Generate a new UUIDv7 (time-sortable) for primary keys.
  static String generateId() => _uuid.v7();

  /// Generate a new UUIDv4 for idempotency keys (PRD §10.2).
  static String generateIdempotencyKey() => _uuid.v4();
}
