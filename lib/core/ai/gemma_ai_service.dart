import 'package:logger/logger.dart';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/gemma_isolate_service.dart';
import 'package:warung_pintar_cimahi/core/ai/json_parser.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';

/// Production implementation of [AiService] using Gemma 4 via isolate.
///
/// Delegates inference to [GemmaIsolateService] and parses the raw
/// output through [JsonParser.parseToolCall].
///
/// Requires [GemmaIsolateService.init] to be called before first use.
class GemmaAiService implements AiService {
  final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  @override
  Future<Result<ToolCallResult, AiFailure>> infer({
    required String systemPrompt,
    required String userInput,
    String? imageBase64,
  }) async {
    if (!GemmaIsolateService.isInitialized) {
      _logger.e('GemmaAiService: Isolate not initialized');
      return const Failure(ModelNotLoadedFailure());
    }

    try {
      _logger.d('GemmaAiService: Starting inference...');

      final raw = await GemmaIsolateService.infer(
        systemPrompt,
        userInput,
        imageBase64,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw const TimeoutException(
          'Gemma inference exceeded 60s timeout',
        ),
      );

      _logger.d('GemmaAiService: Raw output length: ${raw.length}');

      final parsed = JsonParser.parseToolCall(raw);

      switch (parsed) {
        case ToolCallSuccess():
          _logger.i('GemmaAiService: Parsed tool call: ${parsed.name}');
          return Success(parsed);
        case ToolCallFallback():
          _logger.w('GemmaAiService: Parse fallback: ${parsed.reason}');
          return Failure(InvalidJsonOutputFailure(raw));
      }
    } on TimeoutException {
      _logger.e('GemmaAiService: Inference timeout');
      return const Failure(InferenceTimeoutFailure());
    } on StateError catch (e) {
      _logger.e('GemmaAiService: State error', error: e);
      return const Failure(ModelNotLoadedFailure());
    } catch (e) {
      _logger.e('GemmaAiService: Unexpected error', error: e);
      return Failure(InvalidJsonOutputFailure(e.toString()));
    }
  }
}

/// Dart core TimeoutException (avoid dart:io dependency).
class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
