import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

class GetPendingTransactionsUseCase {
  final TransactionRepository _repository;

  const GetPendingTransactionsUseCase(this._repository);

  Future<Result<List<TransactionEntity>, String>> call() =>
      _repository.getPendingTransactions();
}
