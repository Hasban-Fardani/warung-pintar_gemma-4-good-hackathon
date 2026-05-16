import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
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
  });

  Future<Result<void, String>> confirmTransaction(String transactionId);

  Future<Result<void, String>> confirmAllPending();

  Future<Result<void, String>> skipTransaction(String transactionId);

  Future<Result<void, String>> deleteTransaction(String transactionId);

  Future<Result<List<TransactionEntity>, String>> getPendingTransactions();

  Future<Result<List<TransactionEntity>, String>> getRecentTransactions({int limit = 5});
}
