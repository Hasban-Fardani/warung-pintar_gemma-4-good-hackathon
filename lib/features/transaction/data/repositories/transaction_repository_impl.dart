import 'package:logger/logger.dart';

import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/transaction/data/datasources/transaction_datasource.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDatasource _datasource;

  const TransactionRepositoryImpl(this._datasource);

  @override
  Future<Result<String, String>> insertPending({
    required String idempotencyKey,
    required String itemName,
    required int quantity,
    required int amountSen,
    required int priceAtTransactionSen,
    required String transactionType,
    required String inputMethod,
    bool needsClarification = false,
    String? rawInputSource,
    String? aiRawOutput,
  }) async {
    try {
      final txId = await _datasource.insertPending(
        idempotencyKey: idempotencyKey,
        itemName: itemName,
        quantity: quantity,
        amountSen: amountSen,
        priceAtTransactionSen: priceAtTransactionSen,
        transactionType: transactionType,
        inputMethod: inputMethod,
        needsClarification: needsClarification,
      );

      await _datasource.insertAuditLog(
        transactionId: txId,
        action: inputMethod == 'voice'
            ? 'CREATED_BY_AI_VOICE'
            : inputMethod == 'image'
            ? 'CREATED_BY_AI_IMAGE'
            : 'CREATED_MANUAL',
        stateSnapshot: {
          'item_name': itemName,
          'quantity': quantity,
          'amount_sen': amountSen,
          'type': transactionType,
          'status': 'pending',
        },
        rawInputSource: rawInputSource,
        aiRawOutput: aiRawOutput,
      );

      return Success(txId);
    } catch (e) {
      return Failure('Gagal menyimpan transaksi: $e');
    }
  }

  @override
  Future<Result<void, String>> confirmTransaction(String transactionId) async {
    try {
      await _datasource.confirmTransaction(transactionId);
      await _datasource.insertAuditLog(
        transactionId: transactionId,
        action: 'CONFIRMED_BY_USER',
        stateSnapshot: {'status': 'confirmed'},
      );
      return const Success(null);
    } catch (e) {
      return Failure('Gagal mengkonfirmasi: $e');
    }
  }

  @override
  Future<Result<void, String>> confirmAllPending() async {
    try {
      final pending = await getPendingTransactions();
      switch (pending) {
        case Success(:final data):
          await _datasource.confirmAllPending();
          for (final tx in data) {
            await _datasource.insertAuditLog(
              transactionId: tx.id,
              action: 'CONFIRMED_BULK_VOICE',
              stateSnapshot: {'status': 'confirmed'},
            );
          }
          return const Success(null);
        case Failure(:final error):
          return Failure(error);
      }
    } catch (e) {
      return Failure('Gagal konfirmasi semua: $e');
    }
  }

  @override
  Future<Result<void, String>> skipTransaction(String transactionId) async {
    _logger.d('TransactionRepositoryImpl: Skipped tx=$transactionId');
    return const Success(null);
  }

  @override
  Future<Result<void, String>> deleteTransaction(String transactionId) async {
    try {
      await _datasource.softDelete(transactionId);
      await _datasource.insertAuditLog(
        transactionId: transactionId,
        action: 'DELETED',
        stateSnapshot: {'status': 'deleted'},
      );
      return const Success(null);
    } catch (e) {
      return Failure('Gagal menghapus: $e');
    }
  }

  @override
  Future<Result<List<TransactionEntity>, String>>
  getPendingTransactions() async {
    try {
      final models = await _datasource.getPending();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Failure('Gagal memuat transaksi pending: $e');
    }
  }

  @override
  Future<Result<List<TransactionEntity>, String>> getRecentTransactions({
    int limit = 5,
  }) async {
    try {
      final models = await _datasource.getRecent(limit: limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Failure('Gagal memuat transaksi terbaru: $e');
    }
  }
}
