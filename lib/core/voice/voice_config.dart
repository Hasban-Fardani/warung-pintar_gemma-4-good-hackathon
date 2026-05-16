/// STT configuration constants (PRD §16.4.3).
///
/// These values are tuned for Ibu Warsih's usage pattern:
/// - Long pauses between items (2s VAD threshold)
/// - Maximum 30 seconds per listening session
/// - Minimum 0.5 confidence to avoid noise-only transcripts
class VoiceConfig {
  VoiceConfig._();

  /// Silence threshold (ms) before STT considers speech ended.
  /// 2000ms allows natural pauses when listing multiple items.
  static const int vadSilenceThresholdMs = 2000;

  /// Target locale for Indonesian speech recognition.
  static const String localeId = 'id-ID';

  /// Maximum duration of a single listening session (ms).
  /// After 30s, auto-submit and process whatever was captured.
  static const int maxListenDurationMs = 30000;

  /// Minimum confidence score (0.0–1.0) to accept STT result.
  /// Below this → ask user to repeat.
  static const double minConfidenceScore = 0.5;
}
