import 'dart:convert';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/inference_retry.dart';
import 'package:warung_pintar_cimahi/core/ai/fallback/level1_json_repair.dart';
import 'package:warung_pintar_cimahi/core/ai/prompts/voice_transaction_prompt.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/utils/uuid_helper.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

class RecordVoiceTransactionUseCase {
  final AiService _aiService;
  final TransactionRepository _repository;

  const RecordVoiceTransactionUseCase(this._aiService, this._repository);

  Future<Result<String, String>> call(String transcript) async {
    final inferenceResult = await InferenceRetry.runWithRetry(
      aiService: _aiService,
      systemPrompt: voiceTransactionSystemPrompt,
      userInput: transcript,
    );

    switch (inferenceResult) {
      case Success(:final data):
        return _processToolCall(data, transcript);
      case Failure(:final error):
        return _attemptRepair(error, transcript);
    }
  }

  Future<Result<String, String>> _processToolCall(
    ToolCallResult toolCall,
    String transcript,
  ) async {
    if (toolCall is! ToolCallSuccess) {
      return const Failure('AI tidak menghasilkan data transaksi');
    }

    final transactions = toolCall.arguments['transactions'];
    if (transactions is! List || transactions.isEmpty) {
      return const Failure('Tidak ada transaksi yang terdeteksi');
    }

    // Build raw AI output string for audit trail
    final aiRawOutput = jsonEncode({
      'name': toolCall.name,
      'arguments': toolCall.arguments,
    });

    int count = 0;
    for (final tx in transactions) {
      if (tx is! Map) continue;

      final priceSen = (tx['price_sen'] as num?)?.toInt() ?? 0;
      final quantity = (tx['quantity'] as num?)?.toInt() ?? 1;

      final result = await _repository.insertPending(
        idempotencyKey: UuidHelper.generateIdempotencyKey(),
        itemName: tx['name']?.toString() ?? '',
        quantity: quantity,
        amountSen: priceSen * quantity,
        priceAtTransactionSen: priceSen,
        transactionType: tx['transaction_type']?.toString() ?? 'sell',
        inputMethod: 'voice',
        needsClarification: tx['needs_clarification'] == true,
        rawInputSource: transcript,
        aiRawOutput: aiRawOutput,
      );
      if (result is Success) count++;
    }

    return Success('$count transaksi dicatat sebagai pending');
  }

  Future<Result<String, String>> _attemptRepair(
    AiFailure error,
    String transcript,
  ) async {
    if (error is InvalidJsonOutputFailure) {
      final repairResult = await Level1JsonRepair.attempt(
        aiService: _aiService,
        systemPrompt: voiceTransactionSystemPrompt,
        userInput: transcript,
        rawMalformedOutput: error.rawOutput,
      );
      switch (repairResult) {
        case Success(:final data):
          return _processToolCall(data, transcript);
        case Failure():
          return const Failure('Gagal memproses transaksi setelah perbaikan');
      }
    }
    return Failure(error.message);
  }
}
