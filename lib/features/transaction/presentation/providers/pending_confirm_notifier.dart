import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/usecases/confirm_transaction_usecase.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/usecases/get_pending_transactions_usecase.dart';

class PendingConfirmState {
  final List<TransactionEntity> items;
  final int currentItemIndex;
  final bool isProcessing;
  final String? error;
  final String? resultMessage;

  const PendingConfirmState({
    this.items = const [],
    this.currentItemIndex = 0,
    this.isProcessing = false,
    this.error,
    this.resultMessage,
  });

  TransactionEntity? get currentItem =>
      items.isNotEmpty && currentItemIndex < items.length
      ? items[currentItemIndex]
      : null;

  PendingConfirmState copyWith({
    List<TransactionEntity>? items,
    int? currentItemIndex,
    bool? isProcessing,
    String? error,
    String? resultMessage,
  }) {
    return PendingConfirmState(
      items: items ?? this.items,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      resultMessage: resultMessage ?? this.resultMessage,
    );
  }
}

class PendingConfirmNotifier extends StateNotifier<PendingConfirmState> {
  PendingConfirmNotifier()
    : _getPendingTransactions = getIt<GetPendingTransactionsUseCase>(),
      _confirmTransaction = getIt<ConfirmTransactionUseCase>(),
      _repository = getIt<TransactionRepository>(),
      super(const PendingConfirmState());

  final GetPendingTransactionsUseCase _getPendingTransactions;
  final ConfirmTransactionUseCase _confirmTransaction;
  final TransactionRepository _repository;

  Future<void> loadPending() async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await _getPendingTransactions();

    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          items: data,
          currentItemIndex: 0,
          isProcessing: false,
        );
      case Failure(:final error):
        state = state.copyWith(isProcessing: false, error: error);
    }
  }

  Future<void> confirmAll() async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await _confirmTransaction('semua benar', state.items);

    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          items: [],
          currentItemIndex: 0,
          isProcessing: false,
          resultMessage: data,
        );
      case Failure(:final error):
        state = state.copyWith(isProcessing: false, error: error);
    }
  }

  Future<void> confirmSingle(String id) async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await _repository.confirmTransaction(id);

    switch (result) {
      case Success():
        final updatedItems = state.items
            .where((item) => item.id != id)
            .toList();
        state = state.copyWith(
          items: updatedItems,
          currentItemIndex: _clampIndex(updatedItems),
          isProcessing: false,
          resultMessage: '1 transaksi dikonfirmasi',
        );
      case Failure(:final error):
        state = state.copyWith(isProcessing: false, error: error);
    }
  }

  Future<void> skipItem(String id) async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await _repository.skipTransaction(id);

    switch (result) {
      case Success():
        final updatedItems = state.items
            .where((item) => item.id != id)
            .toList();
        state = state.copyWith(
          items: updatedItems,
          currentItemIndex: _clampIndex(updatedItems),
          isProcessing: false,
          resultMessage: '1 transaksi dilewati',
        );
      case Failure(:final error):
        state = state.copyWith(isProcessing: false, error: error);
    }
  }

  void nextItem() {
    if (state.currentItemIndex < state.items.length - 1) {
      state = state.copyWith(currentItemIndex: state.currentItemIndex + 1);
    }
  }

  void previousItem() {
    if (state.currentItemIndex > 0) {
      state = state.copyWith(currentItemIndex: state.currentItemIndex - 1);
    }
  }

  void clearError() {
    state = state.copyWith(error: null, resultMessage: null);
  }

  int _clampIndex(List<TransactionEntity> items) {
    if (items.isEmpty) return 0;
    if (state.currentItemIndex >= items.length) {
      return items.length - 1;
    }
    return state.currentItemIndex;
  }
}

final pendingConfirmProvider =
    StateNotifierProvider<PendingConfirmNotifier, PendingConfirmState>(
      (_) => PendingConfirmNotifier(),
    );
