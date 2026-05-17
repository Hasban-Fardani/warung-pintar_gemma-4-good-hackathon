import 'dart:async';

import 'package:logger/logger.dart';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/json_parser.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';

/// Level 1 fallback — JSON malformed output repair (PRD §16.6.1).
///
/// Strategy:
/// 1. Strip markdown fences from raw output
/// 2. Try to parse the cleaned output
/// 3. If still fails → retry inference 1x with stricter prompt
class Level1JsonRepair {
  Level1JsonRepair._();

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Reinforcement suffix appended to system prompt on repair retry.
  static const _jsonRepairSuffix =
      '\n\nPENTING: Output HARUS berupa JSON murni tanpa teks lain, '
      'tanpa markdown code fence, tanpa penjelasan. '
      'Mulai langsung dengan karakter { dan akhiri dengan }.';

  /// Attempt to repair malformed JSON output.
  ///
  /// [rawMalformedOutput] — the raw string that failed to parse.
  /// Returns [Success] if repair succeeds, [Failure] if both attempts fail.
  static Future<Result<ToolCallResult, AiFailure>> attempt({
    required AiService aiService,
    required String systemPrompt,
    required String userInput,
    required String rawMalformedOutput,
    String? imageBase64,
  }) async {
    // Attempt 1: Strip fences and re-parse
    try {
      final cleaned = JsonParser.stripJsonFences(rawMalformedOutput);
      final parsed = JsonParser.parseToolCall(cleaned);

      if (parsed is ToolCallSuccess) {
        _logger.i('Level1JsonRepair: Fence strip succeeded');
        return Success(parsed);
      }
    } catch (_) {
      _logger.d('Level1JsonRepair: Fence strip insufficient');
    }

    // Attempt 2: Retry inference with reinforcement prompt
    _logger.d('Level1JsonRepair: Retrying with reinforcement prompt');
    try {
      final retryResult = await aiService
          .infer(
            systemPrompt: systemPrompt + _jsonRepairSuffix,
            userInput: userInput,
            imageBase64: imageBase64,
          )
          .timeout(const Duration(seconds: 30));

      return retryResult;
    } on TimeoutException {
      _logger.e('Level1JsonRepair: Retry timed out');
      return const Failure<ToolCallResult, AiFailure>(
        InferenceTimeoutFailure(),
      );
    } catch (e) {
      _logger.e('Level1JsonRepair: Retry also failed', error: e);
      return Failure(InvalidJsonOutputFailure(rawMalformedOutput));
    }
  }
}
