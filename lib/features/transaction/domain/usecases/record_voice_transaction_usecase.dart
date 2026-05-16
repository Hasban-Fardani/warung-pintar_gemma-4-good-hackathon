import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/inference_retry.dart';
import 'package:warung_pintar_cimahi/core/ai/fallback/level1_json_repair.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

class RecordVoiceTransactionUseCase {
  final AiService _aiService;
  final TransactionRepository _repository;

  const RecordVoiceTransactionUseCase(this._aiService, this._repository);

  static const _systemPrompt = '''
Kamu kasir WarungPintar. Ubah ucapan pengguna menjadi transaksi JSON.
Aturan wajib:
- "jual"/"laku"/"terjual" = sell (pemasukan)
- "beli"/"kulakan"/"stok"/"masuk" = buy (pengeluaran)
- total_price_sen = total rupiah × 100 (bukan per satuan)
- Harga harus integer bulat, TIDAK boleh float
- Jika harga tidak disebutkan, gunakan default_price_sen dari konteks
- Jika item ambigu, set needs_clarification: true
- Jangan pernah menebak harga jika tidak ada default
- Output HANYA JSON valid, tanpa markdown fence, tanpa teks lain
''';

  Future<Result<String, String>> call(String transcript) async {
    final inferenceResult = await InferenceRetry.runWithRetry(
      aiService: _aiService,
      systemPrompt: _systemPrompt,
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

    int count = 0;
    for (final tx in transactions) {
      if (tx is! Map) continue;
      final result = await _repository.insertPending(
        idempotencyKey: tx['idempotency_key']?.toString() ?? '',
        itemName: tx['item_name']?.toString() ?? '',
        quantity: (tx['quantity'] as num?)?.toInt() ?? 1,
        amountSen: (tx['total_price_sen'] as num?)?.toInt() ?? 0,
        priceAtTransactionSen: (tx['total_price_sen'] as num?)?.toInt() ?? 0,
        transactionType: tx['transaction_type']?.toString() ?? 'sell',
        inputMethod: 'voice',
        needsClarification: tx['needs_clarification'] == true,
        rawInputSource: transcript,
      );
      if (result is Success) count++;
    }

    return Success('$count transaksi dicatat');
  }

  Future<Result<String, String>> _attemptRepair(
    AiFailure error,
    String transcript,
  ) async {
    if (error is InvalidJsonOutputFailure) {
      final repairResult = await Level1JsonRepair.attempt(
        aiService: _aiService,
        systemPrompt: _systemPrompt,
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
