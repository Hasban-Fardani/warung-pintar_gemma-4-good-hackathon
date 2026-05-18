/// AI failure hierarchy using sealed class (Dart 3).
/// Source: PRD §6.2 — exhaustive pattern matching for all AI error cases.
///
/// Pure Dart — zero Flutter imports.
sealed class AiFailure {
  final String message;
  const AiFailure(this.message);
}

/// Model failed to load or is not available.
final class ModelNotLoadedFailure extends AiFailure {
  const ModelNotLoadedFailure() : super('Model AI gagal dimuat');
}

/// AI inference exceeded timeout threshold.
final class InferenceTimeoutFailure extends AiFailure {
  const InferenceTimeoutFailure() : super('Proses AI timeout');
}

/// AI output is not valid JSON or missing required fields.
final class InvalidJsonOutputFailure extends AiFailure {
  final String rawOutput;
  const InvalidJsonOutputFailure(this.rawOutput)
    : super('Output AI bukan JSON valid');
}

/// Image provided to vision agent is unreadable.
final class ImageUnreadableFailure extends AiFailure {
  const ImageUnreadableFailure() : super('Gambar tidak terbaca');
}

/// Inference already in progress — LiteRT-LM is not thread-safe for concurrent sessions.
final class ConcurrentInferenceFailure extends AiFailure {
  const ConcurrentInferenceFailure()
    : super('Inferensi sedang berjalan. Tunggu sebentar lalu coba lagi.');
}
