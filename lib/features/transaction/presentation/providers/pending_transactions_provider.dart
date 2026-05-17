import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

class PendingBatch {
  final String idempotencyKey;
  final List<TransactionEntity> items;
  final DateTime createdAt;
  final int totalSen;

  const PendingBatch({
    required this.idempotencyKey,
    required this.items,
    required this.createdAt,
    required this.totalSen,
  });
}

class PendingTransactionsState {
  final List<PendingBatch> batches;
  final bool isLoading;
  final String? error;
  final int totalCount;

  const PendingTransactionsState({
    this.batches = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
  });

  PendingTransactionsState copyWith({
    List<PendingBatch>? batches,
    bool? isLoading,
    String? error,
    int? totalCount,
  }) {
    return PendingTransactionsState(
      batches: batches ?? this.batches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class PendingTransactionsNotifier extends StateNotifier<PendingTransactionsState> {
  PendingTransactionsNotifier()
      : _repository = getIt<TransactionRepository>(),
        super(const PendingTransactionsState());

  final TransactionRepository _repository;

  Future<void> loadPending() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getPendingTransactions();

    switch (result) {
      case Success(:final data):
        final batches = _groupByIdempotencyKey(data);
        state = state.copyWith(
          batches: batches,
          isLoading: false,
          totalCount: data.length,
        );
      case Failure(:final error):
        state = state.copyWith(
          isLoading: false,
          error: error,
        );
    }
  }

  List<PendingBatch> _groupByIdempotencyKey(List<TransactionEntity> items) {
    final Map<String, List<TransactionEntity>> grouped = {};

    for (final item in items) {
      if (!grouped.containsKey(item.idempotencyKey)) {
        grouped[item.idempotencyKey] = [];
      }
      grouped[item.idempotencyKey]!.add(item);
    }

    return grouped.entries.map((entry) {
      final items = entry.value;
      final totalSen = items.fold<int>(
        0,
        (sum, item) => sum + (item.priceAtTransactionSen * item.quantity),
      );
      final createdAt = items.isNotEmpty
          ? items.map((e) => e.createdAt).reduce(
              (a, b) => a.isAfter(b) ? a : b,
            )
          : DateTime.now();

      return PendingBatch(
        idempotencyKey: entry.key,
        items: items,
        createdAt: createdAt,
        totalSen: totalSen,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> confirmBatch(String idempotencyKey) async {
    final batch = state.batches.firstWhere(
      (b) => b.idempotencyKey == idempotencyKey,
      orElse: () => throw Exception('Batch not found'),
    );

    for (final item in batch.items) {
      await _repository.confirmTransaction(item.id);
    }

    await loadPending();
  }

  Future<void> deleteBatch(String idempotencyKey) async {
    final batch = state.batches.firstWhere(
      (b) => b.idempotencyKey == idempotencyKey,
      orElse: () => throw Exception('Batch not found'),
    );

    for (final item in batch.items) {
      await _repository.deleteTransaction(item.id);
    }

    await loadPending();
  }

  Future<void> confirmAllPending() async {
    state = state.copyWith(isLoading: true);

    await _repository.confirmAllPending();

    await loadPending();
  }
}

final pendingTransactionsProvider =
    StateNotifierProvider<PendingTransactionsNotifier, PendingTransactionsState>(
  (_) => PendingTransactionsNotifier(),
);
