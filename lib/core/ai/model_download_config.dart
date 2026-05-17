/// Configuration for model download sources (PRD §16.1.2).
///
/// URLs are constants here for hackathon scope.
/// In production, these would come from remote config or app_settings table.
class ModelDownloadConfig {
  ModelDownloadConfig._();

  static const String modelFileName =
      'gemma-4-E2B-it-litert-lm.litertlm';

  static const String modelSha256 = String.fromEnvironment(
    'MODEL_SHA256',
    defaultValue: '',
  );

  static const String primaryUrl = String.fromEnvironment(
    'MODEL_PRIMARY_URL',
    defaultValue:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it-litert-lm.litertlm',
  );

  static const String fallbackUrl = String.fromEnvironment(
    'MODEL_FALLBACK_URL',
    defaultValue: '',
  );

  static const List<String> mirrorUrls = [];

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
