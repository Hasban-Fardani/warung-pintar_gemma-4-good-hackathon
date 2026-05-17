/// Configuration for model download sources (PRD §16.1.2).
///
/// URLs are constants here for hackathon scope.
/// In production, these would come from remote config or app_settings table.
class ModelDownloadConfig {
  ModelDownloadConfig._();

  static const String modelFileName =
      'gemma-4-E2B-it-litertlm-Q4_K_M.litertlm';

  static const String modelSha256 = String.fromEnvironment(
    'MODEL_SHA256',
    defaultValue:
        'a3f8c2d1e9b047f6a1c3e5d7b9f2a4c6e8d0b2f4a6c8e0d2b4f6a8c0e2d4b6f8',
  );

  static const String primaryUrl = String.fromEnvironment(
    'MODEL_PRIMARY_URL',
    defaultValue:
        'https://www.kaggle.com/models/google/gemma-4/frameworks/litert'
        '/variations/gemma-4-e2b-it-litertlm/versions/1/download'
        '/gemma-4-E2B-it-litertlm-Q4_K_M.litertlm',
  );

  static const String fallbackUrl = String.fromEnvironment(
    'MODEL_FALLBACK_URL',
    defaultValue:
        'https://github.com/your-org/warungpintar-models/releases'
        '/download/v1.0.0/gemma-4-E2B-it-litertlm-Q4_K_M.litertlm',
  );

  static const List<String> mirrorUrls = [
    'https://cdn.warungpintar.id/models/gemma-4-E2B-it-litertlm-Q4_K_M.litertlm',
    'https://mirror.example.com/gemma/gemma-4-E2B-it-litertlm-Q4_K_M.litertlm',
  ];

  static const int expectedFileSizeBytes = int.fromEnvironment(
    'MODEL_SIZE_BYTES',
    defaultValue: 2684354560,
  );

  static int get minimumDiskSpaceBytes => expectedFileSizeBytes * 3;

  static const int chunkSizeBytes = 50 * 1024 * 1024;

  static const int parallelChunkCount = 4;

  static const int connectionTimeoutMs = 30000;

  static const int receiveTimeoutMs = 86400000;
}