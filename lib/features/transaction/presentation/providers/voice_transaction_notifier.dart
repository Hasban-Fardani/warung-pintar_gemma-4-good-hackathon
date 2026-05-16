import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/core/voice/voice_service_impl.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/usecases/record_voice_transaction_usecase.dart';

class VoiceTransactionState {
  final AsyncValue<List<TransactionEntity>> transactions;
  final String transcript;
  final bool isListening;
  final int pendingCount;
  final bool isProcessing;
  final String? resultMessage;

  const VoiceTransactionState({
    this.transactions = const AsyncValue.data([]),
    this.transcript = '',
    this.isListening = false,
    this.pendingCount = 0,
    this.isProcessing = false,
    this.resultMessage,
  });

  VoiceTransactionState copyWith({
    AsyncValue<List<TransactionEntity>>? transactions,
    String? transcript,
    bool? isListening,
    int? pendingCount,
    bool? isProcessing,
    String? resultMessage,
  }) {
    return VoiceTransactionState(
      transactions: transactions ?? this.transactions,
      transcript: transcript ?? this.transcript,
      isListening: isListening ?? this.isListening,
      pendingCount: pendingCount ?? this.pendingCount,
      isProcessing: isProcessing ?? this.isProcessing,
      resultMessage: resultMessage ?? this.resultMessage,
    );
  }
}

class VoiceTransactionNotifier extends StateNotifier<VoiceTransactionState> {
  VoiceTransactionNotifier()
      : _voiceService = getIt<VoiceService>(),
        _recordVoiceTransaction = getIt<RecordVoiceTransactionUseCase>(),
        super(const VoiceTransactionState());

  final VoiceService _voiceService;
  final RecordVoiceTransactionUseCase _recordVoiceTransaction;

  Future<void> startListening() async {
    state = state.copyWith(isListening: true, resultMessage: null);

    await _voiceService.startListening(
      onResult: (transcript) async {
        state = state.copyWith(
          transcript: transcript,
          isListening: false,
          isProcessing: true,
        );
        await processTranscript(transcript);
      },
    );
  }

  Future<void> processTranscript(String transcript) async {
    state = state.copyWith(
      transcript: transcript,
      isProcessing: true,
      resultMessage: null,
    );

    final result = await _recordVoiceTransaction(transcript);

    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          isProcessing: false,
          resultMessage: data,
          pendingCount: state.pendingCount + 1,
          transactions: const AsyncValue.data([]),
        );
      case Failure(:final error):
        state = state.copyWith(
          isProcessing: false,
          resultMessage: error,
        );
    }
  }

  void stopListening() {
    _voiceService.stopListening();
    state = state.copyWith(isListening: false);
  }

  void clearResult() {
    state = state.copyWith(
      transcript: '',
      resultMessage: null,
      isProcessing: false,
    );
  }

  void setPendingCount(int count) {
    state = state.copyWith(pendingCount: count);
  }
}

final voiceTransactionProvider =
    StateNotifierProvider<VoiceTransactionNotifier, VoiceTransactionState>(
  (_) => VoiceTransactionNotifier(),
);
