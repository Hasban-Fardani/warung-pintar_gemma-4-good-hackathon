import 'dart:async';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';

/// Retry wrapper with exponential backoff for [AiService.infer()] (PRD §16.5.3).
///
/// Used by ALL agent use cases — never call `AiService.infer()` directly.
///
/// Strategy:
/// - Voice inference timeout: 30 seconds
/// - Vision inference timeout: 45 seconds
/// - Max 2 retries after first failure
/// - Backoff: 1s → 3s
/// - InvalidJsonOutputFailure is NOT retried here (handled by Level1JsonRepair)
class InferenceRetry {
  InferenceRetry._();

  static const int _maxRetries = 2;
  static const int _firstBackoffMs = 1000;
  static const int _secondBackoffMs = 3000;

  static const int _voiceTimeoutSec = 30;
  static const int _visionTimeoutSec = 45;

  /// Run inference with retry and timeout.
  ///
  /// [isVision] is auto-detected from presence of [imageBase64].
  static Future<Result<ToolCallResult, AiFailure>> runWithRetry({
    required AiService aiService,
    required String systemPrompt,
    required String userInput,
    String? imageBase64,
  }) async {
    final timeoutDuration = Duration(
      seconds: imageBase64 != null ? _visionTimeoutSec : _voiceTimeoutSec,
    );

    int attempt = 0;
    AiFailure? lastFailure;

    while (attempt <= _maxRetries) {
      try {
        final result = await aiService
            .infer(
              systemPrompt: systemPrompt,
              userInput: userInput,
              imageBase64: imageBase64,
            )
            .timeout(timeoutDuration);

        // If success, return immediately — no retry needed
        switch (result) {
          case Success():
            return result;
          case Failure(:final error):
            // InvalidJsonOutputFailure → don't retry here, let Level1 handle
            if (error is InvalidJsonOutputFailure) {
              return result;
            }
            lastFailure = error;
        }
      } on TimeoutException {
        lastFailure = const InferenceTimeoutFailure();
      } catch (e) {
        lastFailure = const ModelNotLoadedFailure();
      }

      // Backoff before retry
      if (attempt < _maxRetries) {
        final backoffMs =
            attempt == 0 ? _firstBackoffMs : _secondBackoffMs;
        await Future.delayed(Duration(milliseconds: backoffMs));
      }

      attempt++;
    }

    // All retries exhausted
    return Failure(lastFailure ?? const ModelNotLoadedFailure());
  }
}
