import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';

/// Abstract AI service interface for testability.
/// All agents access AI through this interface (PRD §6.1).
/// Implementations: [GemmaAiService] (prod), [FakeAiService] (dev).
abstract class AiService {
  /// Perform inference with system prompt, user input, and optional image.
  ///
  /// Returns [Success] with parsed [ToolCallResult] on successful inference,
  /// or [Failure] with [AiFailure] describing what went wrong.
  Future<Result<ToolCallResult, AiFailure>> infer({
    required String systemPrompt,
    required String userInput,
    String? imageBase64,
  });
}
