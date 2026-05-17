import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:warung_pintar_cimahi/core/database/database_service.dart';
import 'package:warung_pintar_cimahi/core/utils/uuid_helper.dart';
import 'package:warung_pintar_cimahi/features/transaction/data/models/transaction_model.dart';
import 'package:sqflite/sqflite.dart';

class TransactionDatasource {
  final DatabaseService _db;

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  const TransactionDatasource(this._db);

  Future<String> insertPending({
    required String idempotencyKey,
    required String itemName,
    required int quantity,
    required int amountSen,
    required int priceAtTransactionSen,
    required String transactionType,
    required String inputMethod,
    bool needsClarification = false,
  }) async {
    final id = UuidHelper.generateId();

    try {
      await _db.db.insert('transactions', {
        'id': id,
        'idempotency_key': idempotencyKey,
        'item_name': itemName,
        'quantity': quantity,
        'amount_sen': amountSen,
        'price_at_transaction_sen': priceAtTransactionSen,
        'transaction_type': transactionType,
        'status': 'pending',
        'needs_clarification': needsClarification ? 1 : 0,
        'input_method': inputMethod,
      });
      _logger.d('TransactionDatasource: Inserted pending tx=$id');
      return id;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        _logger.w('TransactionDatasource: Duplicate idempotency_key');
        return id;
      }
      rethrow;
    }
  }

  Future<void> confirmTransaction(String transactionId) async {
    await _db.db.update(
      'transactions',
      {'status': 'confirmed', 'confirmed_at': DateTime.now().toIso8601String()},
      where: 'id = ? AND status = ?',
      whereArgs: [transactionId, 'pending'],
    );
    _logger.d('TransactionDatasource: Confirmed tx=$transactionId');
  }

  Future<void> confirmAllPending() async {
    final now = DateTime.now().toIso8601String();
    await _db.db.update(
      'transactions',
      {'status': 'confirmed', 'confirmed_at': now},
      where: 'status = ?',
      whereArgs: ['pending'],
    );
    _logger.d('TransactionDatasource: Confirmed all pending');
  }

  Future<void> softDelete(String transactionId) async {
    await _db.db.update(
      'transactions',
      {'is_deleted': 1, 'status': 'deleted'},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    _logger.d('TransactionDatasource: Deleted tx=$transactionId');
  }

  Future<List<TransactionModel>> getPending() async {
    final rows = await _db.db.query(
      'transactions',
      where: 'status = ? AND is_deleted = ?',
      whereArgs: ['pending', 0],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  Future<List<TransactionModel>> getRecent({int limit = 5}) async {
    final rows = await _db.db.query(
      'transactions',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  Future<void> insertAuditLog({
    required String transactionId,
    required String action,
    required Map<String, dynamic> stateSnapshot,
    String? rawInputSource,
    String? aiRawOutput,
  }) async {
    final id = UuidHelper.generateId();
    await _db.db.insert('audit_logs', {
      'id': id,
      'transaction_id': transactionId,
      'action': action,
      'raw_input_source': rawInputSource,
      'ai_raw_output': aiRawOutput,
      'state_snapshot': jsonEncode(stateSnapshot),
    });
  }
}
