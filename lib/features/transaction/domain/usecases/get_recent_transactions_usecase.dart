import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

class GetRecentTransactionsUseCase {
  final TransactionRepository _repository;

  const GetRecentTransactionsUseCase(this._repository);

  Future<Result<List<TransactionEntity>, String>> call({int limit = 100}) =>
      _repository.getRecentTransactions(limit: limit);
}
