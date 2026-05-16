import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/inference_retry.dart';
import 'package:warung_pintar_cimahi/core/ai/fallback/level1_json_repair.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

class ConfirmTransactionUseCase {
  final AiService _aiService;
  final TransactionRepository _repository;

  const ConfirmTransactionUseCase(this._aiService, this._repository);

  static const _systemPrompt = '''
Kamu membantu konfirmasi transaksi pending WarungPintar.
Analisa jawaban pengguna dan output JSON action.
Jangan menebak — jika tidak jelas, output clarify.

Actions:
- "confirm" → konfirmasi item ini
- "edit_price" → ubah harga, sertakan new_price_sen
- "skip" → lewati item ini
- "delete" → hapus item ini
- confirm_all:true → konfirmasi semua pending
''';

  Future<Result<String, String>> call(
    String transcript,
    List<TransactionEntity> pendingItems,
  ) async {
    final pendingJson = pendingItems.map((e) => {
      'id': e.id,
      'item_name': e.itemName,
      'quantity': e.quantity,
      'amount_sen': e.amountSen,
      'transaction_type': e.type is TransactionSell ? 'sell' : 'buy',
    }).toList();

    final userInput =
        'Pending items: ${pendingJson.length}\n'
        'Items: ${pendingJson.toString()}\n'
        'User said: $transcript';

    final inferenceResult = await InferenceRetry.runWithRetry(
      aiService: _aiService,
      systemPrompt: _systemPrompt,
      userInput: userInput,
    );

    switch (inferenceResult) {
      case Success(:final data):
        return _processActions(data);
      case Failure(:final error):
        return _attemptRepair(error, userInput);
    }
  }

  Future<Result<String, String>> _processActions(
    ToolCallResult toolCall,
  ) async {
    if (toolCall is! ToolCallSuccess) {
      return const Failure('AI tidak menghasilkan aksi konfirmasi');
    }

    final actions = toolCall.arguments['actions'];
    final confirmAll = toolCall.arguments['confirm_all'] == true;

    if (confirmAll) {
      final result = await _repository.confirmAllPending();
      switch (result) {
        case Success():
          return const Success('Semua transaksi dikonfirmasi');
        case Failure(:final error):
          return Failure(error);
      }
    }

    if (actions is! List || actions.isEmpty) {
      return const Failure('Tidak ada aksi yang terdeteksi');
    }

    int confirmed = 0;
    int skipped = 0;
    for (final action in actions) {
      if (action is! Map) continue;
      final actionType = action['action']?.toString();
      final txId = action['transaction_id']?.toString() ?? '';
      if (txId.isEmpty) continue;

      switch (actionType) {
        case 'confirm':
          final r = await _repository.confirmTransaction(txId);
          if (r is Success) confirmed++;
        case 'skip':
          final r = await _repository.skipTransaction(txId);
          if (r is Success) skipped++;
        case 'delete':
          await _repository.deleteTransaction(txId);
        case 'edit_price':
          await _repository.confirmTransaction(txId);
          confirmed++;
      }
    }

    return Success('$confirmed dikonfirmasi, $skipped dilewati');
  }

  Future<Result<String, String>> _attemptRepair(
    AiFailure error,
    String userInput,
  ) async {
    if (error is InvalidJsonOutputFailure) {
      final repairResult = await Level1JsonRepair.attempt(
        aiService: _aiService,
        systemPrompt: _systemPrompt,
        userInput: userInput,
        rawMalformedOutput: error.rawOutput,
      );
      switch (repairResult) {
        case Success(:final data):
          return _processActions(data);
        case Failure():
          return const Failure('Gagal memproses konfirmasi');
      }
    }
    return Failure(error.message);
  }
}
