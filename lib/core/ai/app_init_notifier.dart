import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';
import 'package:warung_pintar_cimahi/core/ai/gemma_isolate_service.dart';
import 'package:warung_pintar_cimahi/core/ai/model_download_service.dart';
import 'package:warung_pintar_cimahi/core/ai/model_storage.dart';

/// Riverpod provider for app initialization state.
final appInitProvider =
    StateNotifierProvider<AppInitNotifier, AppInitState>(
  (ref) => AppInitNotifier(ref),
);

/// State machine managing AI model lifecycle (PRD §16.2.1).
///
/// Flow:
/// ```
/// APP_LAUNCH
///   → cek ModelStorage.isModelReady()
///     → false → MODEL_DOWNLOADING → DownloadComplete → MODEL_LOADING
///     → true  → MODEL_LOADING
///       → load sukses → MODEL_READY
///       → load gagal  → MODEL_FAILED
/// ```
class AppInitNotifier extends StateNotifier<AppInitState> {
  AppInitNotifier(this._ref) : super(const AppInitModelLoading());

  final Ref _ref;

  static final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  /// Start the initialization sequence.
  ///
  /// Checks model readiness, triggers download if needed, then loads model.
  Future<void> initialize() async {
    _logger.i('AppInitNotifier: Starting initialization...');

    // Step 1: Is model file present and valid?
    final modelReady = await ModelStorage.isModelReady();
    if (!modelReady) {
      state = const AppInitModelDownloading();
      _logger.i('AppInitNotifier: Model not ready, starting download');

      // Listen for download completion
      _ref.listen<ModelDownloadState>(modelDownloadProvider, (_, next) {
        switch (next) {
          case DownloadComplete():
            _loadModel();
          case DownloadFailed(:final reason):
            state = AppInitModelFailed(reason);
            _logger.e('AppInitNotifier: Download failed: $reason');
          default:
            break;
        }
      });

      // Trigger download
      await _ref.read(modelDownloadProvider.notifier).startDownload();
      return;
    }

    // Step 2: Model exists — load into memory
    await _loadModel();
  }

  /// Load model into memory via GemmaIsolateService.
  Future<void> _loadModel() async {
    state = const AppInitModelLoading();
    _logger.i('AppInitNotifier: Loading model into memory...');

    try {
      final modelPath = await ModelStorage.modelPath;
      await GemmaIsolateService.initialize(modelPath: modelPath);
      state = const AppInitModelReady();
      _logger.i('AppInitNotifier: Model ready — AI fully operational');
    } catch (e) {
      _logger.e(
        'AppInitNotifier: Model load failed (RAM/corruption/LiteRT)',
        error: e,
      );
      state = AppInitModelFailed('Model gagal dimuat: $e');
    }
  }

  /// Transition to AI degraded state (Level 2 fallback — PRD §16.6.2).
  ///
  /// Called by agent use cases when inference fails after all retries.
  /// Session-scoped — resets on next [initialize] call.
  void markAsDegraded(String reason) {
    _logger.w('AppInitNotifier: AI degraded — $reason');
    state = AppInitAiDegraded(reason);
  }

  /// Transition to permanent manual mode (Level 3 fallback — PRD §16.6.3).
  ///
  /// Called when model load fails permanently.
  void markAsFailed(String reason) {
    _logger.e('AppInitNotifier: AI permanently failed — $reason');
    state = AppInitModelFailed(reason);
  }
}
