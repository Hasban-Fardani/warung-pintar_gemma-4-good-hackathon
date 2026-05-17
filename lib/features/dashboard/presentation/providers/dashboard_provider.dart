import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/stock_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:warung_pintar_cimahi/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:warung_pintar_cimahi/features/dashboard/domain/usecases/dashboard_summary_usecase.dart';
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
  final DashboardSummaryUseCase _summaryUseCase;
  final TransactionRepository _transactionRepository;
  final CatalogRepository _catalogRepository;

  DashboardNotifier(
    this._summaryUseCase,
    this._transactionRepository,
    this._catalogRepository,
  ) : super(const DashboardState());

  static final _getIt = GetIt.instance;

  static DashboardNotifier create() {
    return DashboardNotifier(
      _getIt<DashboardSummaryUseCase>(),
      _getIt<TransactionRepository>(),
      _getIt<CatalogRepository>(),
    );
  }

  Future<void> loadSummary() async {
    state = state.copyWith(isLoading: true);

    // Use DashboardSummaryUseCase for confirmed-only calculations (PRD §7.2)
    final summaryResult = await _summaryUseCase();
    final summary = switch (summaryResult) {
      Success<DashboardSummaryEntity, String>(:final data) => data,
      Failure<DashboardSummaryEntity, String>() =>
        const DashboardSummaryEntity(),
    };

    // Recent transactions for the list
    final recentResult = await _transactionRepository.getRecentTransactions(
      limit: 5,
    );
    final recentTransactions = switch (recentResult) {
      Success<List<TransactionEntity>, String>(:final data) => data,
      Failure<List<TransactionEntity>, String>() => <TransactionEntity>[],
    };

    // Low stock items for banner
    final lowStockResult = await _catalogRepository.getLowStockItems();
    final lowStockItems = switch (lowStockResult) {
      Success<List<StockEntity>, String>(:final data) => data,
      Failure<List<StockEntity>, String>() => <StockEntity>[],
    };

    state = DashboardState(
      omzetSen: summary.omzetSen,
      profitSen: summary.profitSen,
      modalSen: summary.modalSen,
      pendingCount: summary.pendingCount,
      recentTransactions: recentTransactions,
      lowStockItems: lowStockItems,
      isLoading: false,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
      (ref) => DashboardNotifier.create(),
    );
