/// Configuration for model download sources (PRD §16.1.2).
///
/// URLs are constants here for hackathon scope.
/// In production, these would come from remote config or app_settings table.
class ModelDownloadConfig {
  ModelDownloadConfig._();

  /// Primary: Kaggle Models (prioritized for hackathon submission).
  static const String primaryUrl = String.fromEnvironment(
    'MODEL_PRIMARY_URL',
    defaultValue:
        'https://www.kaggle.com/models/google/gemma-4/frameworks/litert'
        '/variations/gemma-4-e2b-it-litertlm/versions/1/download'
        '/gemma-4-E2B-it-litertlm-Q4_K_M.litertlm',
  );

  /// Fallback: GitHub Releases mirror (if Kaggle is inaccessible).
  static const String fallbackUrl = String.fromEnvironment(
    'MODEL_FALLBACK_URL',
    defaultValue:
        'https://github.com/your-org/warungpintar-models/releases'
        '/download/v1.0.0/gemma-4-E2B-it-litertlm-Q4_K_M.litertlm',
  );

  /// Expected file size in bytes (~2.5 GB) for progress calculation.
  static const int expectedFileSizeBytes = int.fromEnvironment(
    'MODEL_SIZE_BYTES',
    defaultValue: 2684354560,
  );
}
