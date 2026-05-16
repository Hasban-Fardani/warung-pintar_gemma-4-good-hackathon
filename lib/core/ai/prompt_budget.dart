/// Token budget constants for Gemma 4 E2B inference (PRD §16.3.1).
///
/// Context window: 8192 tokens total.
/// Budget allocation limits prompt + output to stay within safe bounds.
class PromptBudget {
  PromptBudget._();

  /// Full context window of Gemma 4 architecture.
  static const int contextWindowTokens = 8192;

  /// Maximum tokens for prompt (system + user input + stock context).
  /// ~73% of context window — leaves room for output + safety margin.
  static const int maxPromptTokens = 6000;

  /// Maximum tokens for model output (JSON response).
  /// 512 tokens ≈ 17 transaction items — more than enough for
  /// typical Ibu Warsih usage (10–12 items per utterance).
  static const int maxOutputTokens = 512;

  /// Safety margin — unused buffer to prevent truncation.
  static const int safetyMarginTokens = 1680;
}
