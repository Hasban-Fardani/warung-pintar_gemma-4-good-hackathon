import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_test_helper.dart';

/// Integration test: idempotency constraint (PRD §10.2).
///
/// Verifies that duplicate `idempotency_key` results in exactly 1 row,
/// not a crash or duplicate entry.
void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await DatabaseTestHelper.createInMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('Idempotency Constraint', () {
    test('duplicate idempotency_key is silently ignored', () async {
      const idemKey = 'test-idem-key-001';
      const txBase = {
        'id': 'tx-001',
        'idempotency_key': idemKey,
        'item_name': 'Beras Premium 5kg',
        'quantity': 3,
        'amount_sen': 4500000,
        'price_at_transaction_sen': 1500000,
        'transaction_type': 'sell',
        'status': 'pending',
        'input_method': 'voice',
      };

      // First insert — should succeed
      await db.insert('transactions', txBase);

      // Second insert with same idempotency_key — should be ignored
      try {
        await db.insert('transactions', {
          ...txBase,
          'id': 'tx-002', // different PK
        });
        // If we get here, the DB didn't enforce unique constraint
        fail('Expected UNIQUE constraint violation');
      } on DatabaseException catch (e) {
        expect(e.isUniqueConstraintError(), isTrue);
      }

      // Verify only 1 row exists
      final rows = await db.query(
        'transactions',
        where: 'idempotency_key = ?',
        whereArgs: [idemKey],
      );
      expect(rows.length, 1);
      expect(rows.first['id'], 'tx-001');
    });

    test('different idempotency_keys allow multiple inserts', () async {
      await db.insert('transactions', {
        'id': 'tx-a',
        'idempotency_key': 'key-a',
        'item_name': 'Gula 1kg',
        'quantity': 1,
        'amount_sen': 1500000,
        'price_at_transaction_sen': 1500000,
        'transaction_type': 'sell',
        'status': 'pending',
        'input_method': 'voice',
      });

      await db.insert('transactions', {
        'id': 'tx-b',
        'idempotency_key': 'key-b',
        'item_name': 'Gula 1kg',
        'quantity': 2,
        'amount_sen': 3000000,
        'price_at_transaction_sen': 1500000,
        'transaction_type': 'sell',
        'status': 'pending',
        'input_method': 'voice',
      });

      final rows = await db.query('transactions');
      expect(rows.length, 2);
    });
  });
}
