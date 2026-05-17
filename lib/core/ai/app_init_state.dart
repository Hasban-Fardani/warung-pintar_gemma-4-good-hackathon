sealed class AppInitState {
  const AppInitState();
}

final class AppInitLoading extends AppInitState {
  const AppInitLoading();
}

final class AppInitModelDownloading extends AppInitState {
  final double progress;
  const AppInitModelDownloading({this.progress = 0.0});
}

final class AppInitModelReady extends AppInitState {
  const AppInitModelReady();
}

final class AppInitModelFailed extends AppInitState {
  final String reason;
  const AppInitModelFailed(this.reason);
}

final class AppInitAiDegraded extends AppInitState {
  final String reason;
  const AppInitAiDegraded(this.reason);
}
