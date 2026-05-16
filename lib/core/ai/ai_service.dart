/// Abstract AI service interface for testability.
/// All agents access AI through this interface (PRD §6.1).
/// Implementations: [GemmaAiService] (prod), [FakeAiService] (dev).
abstract class AiService {
  /// Perform inference with system prompt, user input, and optional image.
  ///
  /// Returns raw JSON string from the model.
  /// Throws on model/inference failures — callers must handle errors.
  Future<String> infer({
    required String systemPrompt,
    required String userInput,
    String? imageBase64,
  });
}
