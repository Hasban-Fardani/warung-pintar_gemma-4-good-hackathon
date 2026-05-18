import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Abstract database service interface.
/// Implementations handle SQLite setup, WAL mode, migrations.
abstract class DatabaseService {
  Future<void> init();

  /// Expose the database instance for datasources.
  Database get db;
}

/// Full SQLite implementation per PRD §11.
///
/// WAL mode for concurrent reads during AI inference.
/// All tables, indexes, foreign keys, and constraints defined here.
@LazySingleton(as: DatabaseService)
class DatabaseServiceImpl implements DatabaseService {
  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  Database? _db;
  static const int _dbVersion = 3;
  static const String _dbName = 'warung_pintar.db';

  @override
  Database get db {
    if (_db == null) {
      throw StateError('DatabaseService not initialized. Call init() first.');
    }
    return _db!;
  }

  @override
  Future<void> init() async {
    if (_db != null) return;

    _logger.i('DatabaseService: Initializing...');

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    _logger.i('DatabaseService: Ready at $dbPath');
  }

  /// Enable WAL mode and foreign keys before any table creation.
  Future<void> _onConfigure(Database db) async {
    await db.rawQuery('PRAGMA journal_mode = WAL');
    await db.rawQuery('PRAGMA synchronous = NORMAL');
    await db.rawQuery('PRAGMA foreign_keys = ON');
    _logger.d('DatabaseService: WAL mode + FK enabled');
  }

  /// Create all tables per PRD §11.
  Future<void> _onCreate(Database db, int version) async {
    _logger.i('DatabaseService: Creating schema v$version...');

    final batch = db.batch();

    batch.execute('''
      CREATE TABLE categories (
        id         TEXT    PRIMARY KEY,
        name       TEXT    UNIQUE NOT NULL,
        parent_id  TEXT    REFERENCES categories(id),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    batch.execute('''
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

    batch.execute('''
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
        raw_input_source         TEXT,
        ai_raw_output            TEXT,
        created_at               DATETIME DEFAULT CURRENT_TIMESTAMP,
        is_deleted               INTEGER DEFAULT 0
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_tx_date   ON transactions(date(created_at))',
    );
    batch.execute(
      'CREATE INDEX idx_tx_type   ON transactions(transaction_type)',
    );
    batch.execute('CREATE INDEX idx_tx_status ON transactions(status)');
    batch.execute('CREATE INDEX idx_tx_method ON transactions(input_method)');

    batch.execute('''
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

    batch.execute('''
      CREATE TABLE price_history (
        id             TEXT    PRIMARY KEY,
        stock_id       TEXT    NOT NULL REFERENCES stock(id),
        price_sen      INTEGER NOT NULL,
        reason         TEXT,
        effective_from DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    batch.execute('''
      CREATE TABLE app_settings (
        key        TEXT PRIMARY KEY,
        value      TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await batch.commit(noResult: true);
    _logger.i('DatabaseService: Schema created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('DatabaseService: Upgrading schema v$oldVersion → v$newVersion');
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN parent_id TEXT REFERENCES categories(id)',
      );
      _logger.i('DatabaseService: Added parent_id column to categories');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN raw_input_source TEXT',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN ai_raw_output TEXT',
      );
      _logger.i('DatabaseService: Added raw_input_source, ai_raw_output columns');
    }
  }
}
