import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/get_categories_usecase.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/usecases/get_recent_transactions_usecase.dart';

class ReportsState {
  final List<TransactionEntity> allTransactions;
  final List<TransactionEntity> filteredTransactions;
  final List<double> barData;
  final List<String> dayLabels;
  final String bestSellingProduct;
  final int averageTransactionSen;
  final int totalTransactions;
  final List<String> categories;
  final String selectedCategory;
  final bool isLoading;
  final String? error;
  final int periodIndex;

  const ReportsState({
    this.allTransactions = const [],
    this.filteredTransactions = const [],
    this.barData = const [0, 0, 0, 0, 0, 0, 0],
    this.dayLabels = const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
    this.bestSellingProduct = '-',
    this.averageTransactionSen = 0,
    this.totalTransactions = 0,
    this.categories = const ['Semua'],
    this.selectedCategory = 'Semua',
    this.isLoading = false,
    this.error,
    this.periodIndex = 0,
  });

  ReportsState copyWith({
    List<TransactionEntity>? allTransactions,
    List<TransactionEntity>? filteredTransactions,
    List<double>? barData,
    List<String>? dayLabels,
    String? bestSellingProduct,
    int? averageTransactionSen,
    int? totalTransactions,
    List<String>? categories,
    String? selectedCategory,
    bool? isLoading,
    String? error,
    int? periodIndex,
  }) {
    return ReportsState(
      allTransactions: allTransactions ?? this.allTransactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      barData: barData ?? this.barData,
      dayLabels: dayLabels ?? this.dayLabels,
      bestSellingProduct: bestSellingProduct ?? this.bestSellingProduct,
      averageTransactionSen:
          averageTransactionSen ?? this.averageTransactionSen,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      periodIndex: periodIndex ?? this.periodIndex,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  ReportsNotifier()
    : _getRecentTransactions = getIt<GetRecentTransactionsUseCase>(),
      _getCategories = getIt<GetCategoriesUseCase>(),
      super(const ReportsState());

  final GetRecentTransactionsUseCase _getRecentTransactions;
  final GetCategoriesUseCase _getCategories;

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);

    final txResult = await _getRecentTransactions(limit: 100);
    final catResult = await _getCategories();

    final categories = switch (catResult) {
      Success(:final data) => ['Semua', ...data.map((c) => c.name)],
      Failure() => ['Semua'],
    };

    final confirmedTransactions = switch (txResult) {
      Success(:final data) => data
          .where((t) => t.status == TransactionStatus.confirmed)
          .toList(),
      Failure() => <TransactionEntity>[],
    };

    final filtered = _filterByCategory(confirmedTransactions, state.selectedCategory);
    final stats = _calculateStats(filtered);
    final barData = _calculateBarData(filtered, state.periodIndex);

    state = state.copyWith(
      allTransactions: confirmedTransactions,
      filteredTransactions: filtered,
      barData: barData,
      bestSellingProduct: stats.bestSellingProduct,
      averageTransactionSen: stats.averageTransactionSen,
      totalTransactions: filtered.length,
      categories: categories,
      isLoading: false,
    );
  }

  void setPeriodIndex(int index) {
    if (index == state.periodIndex) return;
    final barData = _calculateBarData(state.filteredTransactions, index);
    state = state.copyWith(periodIndex: index, barData: barData);
  }

  void setSelectedCategory(String category) {
    if (category == state.selectedCategory) return;
    final filtered = _filterByCategory(state.allTransactions, category);
    final stats = _calculateStats(filtered);
    final barData = _calculateBarData(filtered, state.periodIndex);
    state = state.copyWith(
      selectedCategory: category,
      filteredTransactions: filtered,
      barData: barData,
      bestSellingProduct: stats.bestSellingProduct,
      averageTransactionSen: stats.averageTransactionSen,
      totalTransactions: filtered.length,
    );
  }

  List<TransactionEntity> _filterByCategory(
    List<TransactionEntity> transactions,
    String category,
  ) {
    if (category == 'Semua') return transactions;
    return transactions
        .where((t) => t.itemName.toLowerCase().contains(category.toLowerCase()))
        .toList();
  }

  _Stats _calculateStats(List<TransactionEntity> transactions) {
    if (transactions.isEmpty) {
      return const _Stats(bestSellingProduct: '-', averageTransactionSen: 0);
    }

    final Map<String, int> productRevenue = {};
    int totalSen = 0;

    for (final tx in transactions) {
      if (tx.type is TransactionSell) {
        productRevenue[tx.itemName] =
            (productRevenue[tx.itemName] ?? 0) + tx.amountSen;
      }
      totalSen += tx.amountSen;
    }

    String bestSelling = '-';
    int maxRevenue = 0;
    productRevenue.forEach((product, revenue) {
      if (revenue > maxRevenue) {
        maxRevenue = revenue;
        bestSelling = product;
      }
    });

    final averageSen = transactions.isNotEmpty
        ? (totalSen / transactions.length).round()
        : 0;

    return _Stats(
      bestSellingProduct: bestSelling,
      averageTransactionSen: averageSen,
    );
  }

  List<double> _calculateBarData(
    List<TransactionEntity> transactions,
    int periodIndex,
  ) {
    final now = DateTime.now();
    final dailyRevenue = <int, double>{};

    for (var i = 0; i < 7; i++) {
      dailyRevenue[i] = 0;
    }

    for (final tx in transactions) {
      if (tx.type is! TransactionSell) continue;

      final daysDiff = _getDaysDiff(tx.createdAt, now, periodIndex);
      if (daysDiff >= 0 && daysDiff < 7) {
        dailyRevenue[daysDiff] =
            (dailyRevenue[daysDiff] ?? 0) + tx.amountSen / 100;
      }
    }

    return List.generate(7, (i) => dailyRevenue[i] ?? 0);
  }

  int _getDaysDiff(DateTime txDate, DateTime now, int periodIndex) {
    switch (periodIndex) {
      case 0:
        return now.day - txDate.day;
      case 1:
        final nowWeekStart = now.subtract(Duration(days: now.weekday - 1));
        final txWeekStart = txDate.subtract(Duration(days: txDate.weekday - 1));
        return nowWeekStart.difference(txWeekStart).inDays ~/ 7;
      case 2:
        return ((now.year * 12 + now.month) -
            (txDate.year * 12 + txDate.month));
      default:
        return 0;
    }
  }
}

class _Stats {
  final String bestSellingProduct;
  final int averageTransactionSen;

  const _Stats({
    required this.bestSellingProduct,
    required this.averageTransactionSen,
  });
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>(
  (_) => ReportsNotifier(),
);
