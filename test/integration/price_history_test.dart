import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_test_helper.dart';

/// Integration test: price history isolation (PRD §10.6).
///
/// Verifies that updating `default_price_sen` in stock does NOT
/// retroactively change `price_at_transaction_sen` in old transactions.
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

  group('Price History Isolation', () {
    test(
      'updating stock price does not change old transaction prices',
      () async {
        // Setup: create category + stock
        await db.insert('categories', {'id': 'cat-001', 'name': 'Sembako'});

        await db.insert('stock', {
          'id': 'stock-001',
          'item_name': 'Beras Premium 5kg',
          'current_qty': 50,
          'default_price_sen': 7500000, // Rp 75.000
          'category_id': 'cat-001',
        });

        // Record transaction at OLD price
        await db.insert('transactions', {
          'id': 'tx-old',
          'idempotency_key': 'idem-old',
          'item_name': 'Beras Premium 5kg',
          'quantity': 1,
          'amount_sen': 7500000,
          'price_at_transaction_sen': 7500000, // snapshot: Rp 75.000
          'transaction_type': 'sell',
          'status': 'confirmed',
          'input_method': 'voice',
        });

        // Update stock price (append to price_history)
        await db.insert('price_history', {
          'id': 'ph-001',
          'stock_id': 'stock-001',
          'price_sen': 8000000, // Rp 80.000 (new price)
          'reason': 'Naik inflasi',
        });
        await db.update(
          'stock',
          {'default_price_sen': 8000000},
          where: 'id = ?',
          whereArgs: ['stock-001'],
        );

        // Record NEW transaction at NEW price
        await db.insert('transactions', {
          'id': 'tx-new',
          'idempotency_key': 'idem-new',
          'item_name': 'Beras Premium 5kg',
          'quantity': 1,
          'amount_sen': 8000000,
          'price_at_transaction_sen': 8000000, // snapshot: Rp 80.000
          'transaction_type': 'sell',
          'status': 'confirmed',
          'input_method': 'voice',
        });

        // VERIFY: old transaction still has old price
        final oldTx = await db.query(
          'transactions',
          where: 'id = ?',
          whereArgs: ['tx-old'],
        );
        expect(oldTx.first['price_at_transaction_sen'], 7500000);

        // VERIFY: new transaction has new price
        final newTx = await db.query(
          'transactions',
          where: 'id = ?',
          whereArgs: ['tx-new'],
        );
        expect(newTx.first['price_at_transaction_sen'], 8000000);

        // VERIFY: price_history has the new entry
        final history = await db.query(
          'price_history',
          where: 'stock_id = ?',
          whereArgs: ['stock-001'],
        );
        expect(history.length, 1);
        expect(history.first['price_sen'], 8000000);
      },
    );

    test(
      'price_history is append-only — multiple entries accumulate',
      () async {
        await db.insert('categories', {'id': 'cat-002', 'name': 'Minuman'});

        await db.insert('stock', {
          'id': 'stock-002',
          'item_name': 'Teh Botol',
          'current_qty': 100,
          'default_price_sen': 400000,
          'category_id': 'cat-002',
        });

        // Three price changes
        for (var i = 1; i <= 3; i++) {
          await db.insert('price_history', {
            'id': 'ph-tea-$i',
            'stock_id': 'stock-002',
            'price_sen': 400000 + (i * 50000),
            'reason': 'Perubahan ke-$i',
          });
        }

        final history = await db.query(
          'price_history',
          where: 'stock_id = ?',
          whereArgs: ['stock-002'],
          orderBy: 'effective_from ASC',
        );
        expect(history.length, 3);
        expect(history[0]['price_sen'], 450000);
        expect(history[1]['price_sen'], 500000);
        expect(history[2]['price_sen'], 550000);
      },
    );
  });
}
