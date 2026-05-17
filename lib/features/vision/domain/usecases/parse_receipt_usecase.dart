import 'dart:convert';
import 'dart:io';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/fallback/level1_json_repair.dart';
import 'package:warung_pintar_cimahi/core/ai/inference_retry.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/core/utils/uuid_helper.dart';
import 'package:warung_pintar_cimahi/core/vision/image_quality_gate.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

class ParseReceiptResult {
  final int insertedCount;
  final int totalDetected;
  const ParseReceiptResult(this.insertedCount, this.totalDetected);
}

class ParseReceiptUseCase {
  final AiService _aiService;
  final TransactionRepository _transactionRepository;

  const ParseReceiptUseCase(this._aiService, this._transactionRepository);

  static const _systemPrompt = '''
Kamu adalah parser struk belanja WarungPintar.
Dari gambar struk/nota, ekstrak semua item yang dibeli beserta harga total per item.
Semua transaksi dari struk adalah tipe "buy" (kulakan/modal), status "pending".
Output HANYA JSON valid sesuai skema record_transactions.
Konversi semua harga ke sen (× 100).
Jika gambar tidak terbaca, output: {"error": "image_unreadable"}.
''';

  Future<Result<ParseReceiptResult, String>> call(File imageFile) async {
    final qualityResult = await ImageQualityGate.validate(imageFile);
    switch (qualityResult) {
      case ImageQualityFail(:final reason):
        return Failure(_qualityMessage(reason));
      case ImageQualityPass():
        break;
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final inferenceResult = await InferenceRetry.runWithRetry(
      aiService: _aiService,
      systemPrompt: _systemPrompt,
      userInput: '',
      imageBase64: base64Image,
    );

    switch (inferenceResult) {
      case Success(:final data):
        return _processResult(data, imageFile.path);
      case Failure(:final error):
        return _attemptRepair(error);
    }
  }

  Future<Result<ParseReceiptResult, String>> _processResult(
    ToolCallResult toolCall,
    String imagePath,
  ) async {
    if (toolCall is! ToolCallSuccess) {
      return const Failure('AI tidak dapat membaca struk');
    }

    if (toolCall.name == 'record_transactions') {
      final transactions = toolCall.arguments['transactions'];
      if (transactions is! List || transactions.isEmpty) {
        return const Failure('Tidak ada item yang terdeteksi di struk');
      }

      int count = 0;
      for (final tx in transactions) {
        if (tx is! Map) continue;
        final idemKey = UuidHelper.generateIdempotencyKey();
        final result = await _transactionRepository.insertPending(
          idempotencyKey: idemKey,
          itemName: tx['item_name']?.toString() ?? '',
          quantity: (tx['quantity'] as num?)?.toInt() ?? 1,
          amountSen: (tx['total_price_sen'] as num?)?.toInt() ?? 0,
          priceAtTransactionSen: (tx['total_price_sen'] as num?)?.toInt() ?? 0,
          transactionType: 'buy',
          inputMethod: 'image',
          rawInputSource: imagePath,
        );
        if (result is Success) count++;
      }

      return Success(ParseReceiptResult(count, transactions.length));
    }

    return const Failure('Format struk tidak dikenali');
  }

  Future<Result<ParseReceiptResult, String>> _attemptRepair(
    AiFailure error,
  ) async {
    if (error is InvalidJsonOutputFailure) {
      final repairResult = await Level1JsonRepair.attempt(
        aiService: _aiService,
        systemPrompt: _systemPrompt,
        userInput: '',
        rawMalformedOutput: error.rawOutput,
      );
      switch (repairResult) {
        case Success(:final data):
          return _processResult(data, '');
        case Failure():
          return const Failure('Gagal membaca struk setelah perbaikan');
      }
    }
    return Failure(error.message);
  }

  String _qualityMessage(ImageQualityFailReason reason) => switch (reason) {
    ImageQualityFailReason.fileTooSmall => 'Gambar terlalu kecil atau buram',
    ImageQualityFailReason.resolutionTooLow =>
      'Resolusi terlalu rendah — pastikan struk mengisi layar',
    ImageQualityFailReason.tooDark => 'Gambar terlalu gelap — perbaiki cahaya',
  };
}
