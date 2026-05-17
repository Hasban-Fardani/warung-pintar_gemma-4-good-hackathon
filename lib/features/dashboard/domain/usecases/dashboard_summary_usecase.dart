import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

/// Calculates dashboard summary from confirmed transactions only (PRD §7.2).
///
/// - Omzet: sum of `amountSen` for confirmed sell transactions today
/// - Modal: sum of `amountSen` for confirmed buy transactions today
/// - Profit: omzet - modal
/// - Pending count: separate count from pending list
class DashboardSummaryUseCase {
  final TransactionRepository _transactionRepository;

  const DashboardSummaryUseCase(this._transactionRepository);

  Future<Result<DashboardSummaryEntity, String>> call() async {
    final recentResult = await _transactionRepository.getRecentTransactions(
      limit: 50,
    );
    final pendingResult = await _transactionRepository.getPendingTransactions();

    final recentTransactions = switch (recentResult) {
      Success<List<TransactionEntity>, String>(:final data) => data,
      Failure<List<TransactionEntity>, String>() => <TransactionEntity>[],
    };

    final pendingList = switch (pendingResult) {
      Success<List<TransactionEntity>, String>(:final data) => data,
      Failure<List<TransactionEntity>, String>() => <TransactionEntity>[],
    };

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayConfirmed = recentTransactions.where(
      (t) =>
          t.status == TransactionStatus.confirmed &&
          t.createdAt.isAfter(todayStart) &&
          t.createdAt.isBefore(todayEnd),
    );

    int omzetSen = 0;
    int modalSen = 0;
    for (final tx in todayConfirmed) {
      if (tx.type is TransactionSell) {
        omzetSen += tx.amountSen;
      } else if (tx.type is TransactionBuy) {
        modalSen += tx.amountSen;
      }
    }

    return Success(
      DashboardSummaryEntity(
        omzetSen: omzetSen,
        profitSen: omzetSen - modalSen,
        modalSen: modalSen,
        pendingCount: pendingList.length,
      ),
    );
  }
}
