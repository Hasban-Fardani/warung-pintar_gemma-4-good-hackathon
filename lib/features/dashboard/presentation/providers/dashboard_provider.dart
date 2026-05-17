import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/stock_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

class DashboardState {
  final int omzetSen;
  final int profitSen;
  final int modalSen;
  final int pendingCount;
  final List<TransactionEntity> recentTransactions;
  final List<StockEntity> lowStockItems;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.omzetSen = 0,
    this.profitSen = 0,
    this.modalSen = 0,
    this.pendingCount = 0,
    this.recentTransactions = const [],
    this.lowStockItems = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    int? omzetSen,
    int? profitSen,
    int? modalSen,
    int? pendingCount,
    List<TransactionEntity>? recentTransactions,
    List<StockEntity>? lowStockItems,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      omzetSen: omzetSen ?? this.omzetSen,
      profitSen: profitSen ?? this.profitSen,
      modalSen: modalSen ?? this.modalSen,
      pendingCount: pendingCount ?? this.pendingCount,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final TransactionRepository _transactionRepository;
  final CatalogRepository _catalogRepository;

  DashboardNotifier(this._transactionRepository, this._catalogRepository)
    : super(const DashboardState());

  static final _getIt = GetIt.instance;

  static DashboardNotifier create() {
    return DashboardNotifier(
      _getIt<TransactionRepository>(),
      _getIt<CatalogRepository>(),
    );
  }

  Future<void> loadSummary() async {
    state = state.copyWith(isLoading: true);

    final recentResult = _transactionRepository.getRecentTransactions(
      limit: 50,
    );
    final pendingResult = _transactionRepository.getPendingTransactions();
    final lowStockResult = _catalogRepository.getLowStockItems();

    final recentTransactions = switch (await recentResult) {
      Success<List<TransactionEntity>, String>(:final data) => data,
      Failure<List<TransactionEntity>, String>() => <TransactionEntity>[],
    };

    final pendingList = switch (await pendingResult) {
      Success<List<TransactionEntity>, String>(:final data) => data,
      Failure<List<TransactionEntity>, String>() => <TransactionEntity>[],
    };

    final lowStockItems = switch (await lowStockResult) {
      Success<List<StockEntity>, String>(:final data) => data,
      Failure<List<StockEntity>, String>() => <StockEntity>[],
    };

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayConfirmed = recentTransactions.where(
      (t) =>
          t.status == TransactionStatus.confirmed &&
          t.createdAt.isAfter(todayStart) &&
          t.createdAt.isBefore(todayStart.add(const Duration(days: 1))),
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

    state = DashboardState(
      omzetSen: omzetSen,
      profitSen: omzetSen - modalSen,
      modalSen: modalSen,
      pendingCount: pendingList.length,
      recentTransactions: recentTransactions.take(5).toList(),
      lowStockItems: lowStockItems,
      isLoading: false,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
      (ref) => DashboardNotifier.create(),
    );
