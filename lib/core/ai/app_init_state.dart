/// App initialization state machine for AI runtime (PRD §16.2.1).
///
/// Controls the lifecycle of AI model loading and determines
/// which features are available to the user.
///
/// Pure Dart — zero Flutter imports.
sealed class AppInitState {
  const AppInitState();
}

/// Model not yet downloaded — show [ModelDownloadScreen].
final class AppInitModelDownloading extends AppInitState {
  const AppInitModelDownloading();
}

/// Model file exists on disk, being loaded into memory via flutter_gemma.
/// Dashboard accessible but AI features (voice/photo) disabled.
final class AppInitModelLoading extends AppInitState {
  const AppInitModelLoading();
}

/// Model loaded and ready — AI fully operational.
final class AppInitModelReady extends AppInitState {
  const AppInitModelReady();
}

/// Model load failed permanently (RAM insufficient, file corrupt, LiteRT crash).
/// App enters permanent manual mode — all data operations still work via SQLite.
final class AppInitModelFailed extends AppInitState {
  final String reason;
  const AppInitModelFailed(this.reason);
}

/// AI inference failed repeatedly (Level 2 fallback — PRD §16.6.2).
/// Session-scoped — resets on app restart if model loads successfully.
/// Voice/photo FABs disabled, manual input active.
final class AppInitAiDegraded extends AppInitState {
  final String reason;
  const AppInitAiDegraded(this.reason);
}
