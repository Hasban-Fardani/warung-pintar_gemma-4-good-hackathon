import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Shared helper for integration tests — creates an in-memory SQLite
/// database with the full WarungPintar schema (mirrors DatabaseServiceImpl).
class DatabaseTestHelper {
  DatabaseTestHelper._();

  /// Create an in-memory database with all tables per PRD §11.
  static Future<Database> createInMemoryDb() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE categories (
              id         TEXT    PRIMARY KEY,
              name       TEXT    UNIQUE NOT NULL,
              created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await db.execute('''
            CREATE TABLE stock (
              id                   TEXT    PRIMARY KEY,
              item_name            TEXT    UNIQUE NOT NULL,
              current_qty          INTEGER DEFAULT 0,
              default_price_sen    INTEGER DEFAULT 0,
              low_stock_threshold  INTEGER DEFAULT 5,
              category_id          TEXT    REFERENCES categories(id),
              is_deleted           INTEGER DEFAULT 0,
              last_updated         DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await db.execute('''
            CREATE TABLE transactions (
              id                       TEXT    PRIMARY KEY,
              idempotency_key          TEXT    UNIQUE NOT NULL,
              item_name                TEXT    NOT NULL,
              quantity                 INTEGER NOT NULL CHECK(quantity > 0),
              amount_sen               INTEGER NOT NULL CHECK(amount_sen >= 0),
              price_at_transaction_sen INTEGER NOT NULL,
              transaction_type         TEXT    NOT NULL
                                         CHECK(transaction_type IN ('sell', 'buy')),
              status                   TEXT    NOT NULL DEFAULT 'pending'
                                         CHECK(status IN ('pending', 'confirmed', 'deleted')),
              needs_clarification      INTEGER DEFAULT 0,
              input_method             TEXT    NOT NULL
                                         CHECK(input_method IN ('voice', 'image', 'manual')),
              confirmed_at             DATETIME,
              created_at               DATETIME DEFAULT CURRENT_TIMESTAMP,
              is_deleted               INTEGER DEFAULT 0
            )
          ''');

          await db.execute('''
            CREATE TABLE audit_logs (
              id               TEXT    PRIMARY KEY,
              transaction_id   TEXT    NOT NULL REFERENCES transactions(id),
              action           TEXT    NOT NULL CHECK(action IN (
                                 'CREATED_BY_AI_VOICE',
                                 'CREATED_BY_AI_IMAGE',
                                 'CREATED_MANUAL',
                                 'CONFIRMED_BY_USER',
                                 'CONFIRMED_BULK_VOICE',
                                 'EDITED_BY_USER',
                                 'NEEDS_CLARIFICATION',
                                 'CLARIFIED_BY_USER',
                                 'DELETED'
                               )),
              raw_input_source TEXT,
              ai_raw_output    TEXT,
              state_snapshot   TEXT    NOT NULL,
              created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await db.execute('''
            CREATE TABLE price_history (
              id             TEXT    PRIMARY KEY,
              stock_id       TEXT    NOT NULL REFERENCES stock(id),
              price_sen      INTEGER NOT NULL,
              reason         TEXT,
              effective_from DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await db.execute('''
            CREATE TABLE app_settings (
              key        TEXT PRIMARY KEY,
              value      TEXT NOT NULL,
              updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');
        },
      ),
    );
    return db;
  }
}
