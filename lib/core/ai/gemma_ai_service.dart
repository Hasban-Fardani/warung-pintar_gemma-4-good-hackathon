import 'package:logger/logger.dart';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/ai/gemma_service.dart';
import 'package:warung_pintar_cimahi/core/ai/json_parser.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';

class GemmaAiService implements AiService {
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  GemmaService get _gemmaService => getIt<GemmaService>();

  /// Guard flag — LiteRT-LM is not thread-safe for concurrent inference sessions.
  bool _isInferring = false;

  @override
  Future<Result<ToolCallResult, AiFailure>> infer({
    required String systemPrompt,
    required String userInput,
    String? imageBase64,
  }) async {
    if (!_gemmaService.isInitialized) {
      _logger.e('GemmaAiService: Service not initialized');
      return const Failure(ModelNotLoadedFailure());
    }

    // GUARD: tolak concurrent inference — LiteRT-LM tidak thread-safe
    if (_isInferring) {
      _logger.w('GemmaAiService: Inference already in progress, rejecting duplicate call');
      return const Failure(ConcurrentInferenceFailure());
    }

    _isInferring = true;
    try {
      _logger.d('GemmaAiService: Starting inference...');

      String raw;
      final prompt = systemPrompt + userInput;

      if (imageBase64 != null) {
        final bytes = Uri.parse('data:image/png;base64,$imageBase64')
            .data!
            .contentAsBytes();
        raw = await _gemmaService.inferWithImage(prompt, bytes);
      } else {
        raw = await _gemmaService.infer(prompt);
      }

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
    } finally {
      _isInferring = false;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
