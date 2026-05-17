import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';
import 'package:background_downloader/background_downloader.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';
import 'package:warung_pintar_cimahi/core/ai/gemma_service.dart';
import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/voice/voice_service_impl.dart';

final appInitProvider = StateNotifierProvider<AppInitNotifier, AppInitState>(
  (ref) => AppInitNotifier(),
);

class AppInitNotifier extends StateNotifier<AppInitState> {
  AppInitNotifier() : super(const AppInitLoading());

  static const String _modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

  static const String _modelFileName = 'gemma-4-E2B-it.litertlm';

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  Future<void> _clearStaleDownload() async {
    try {
      final taskId = _generateTaskId();
      final task = await FileDownloader().taskForId(taskId);
      if (task != null) {
        _logger.i('AppInitNotifier: Found stale task, removing...');
        await FileDownloader().cancelTaskWithId(taskId);
      }
    } catch (e) {
      _logger.w('AppInitNotifier: Could not clear stale task: $e');
    }
  }

  String _generateTaskId() {
    const targetPath = '/data/user/0/com.example.warung_pintar_cimahi/app_flutter/models/$_modelFileName';
    return '${_modelUrl.hashCode.toUnsigned(32).toRadixString(16)}_${targetPath.hashCode.toUnsigned(32).toRadixString(16)}';
  }

  Future<void> initialize() async {
    _logger.i('AppInitNotifier: Starting initialization...');

    if (!FlutterGemma.hasActiveModel()) {
      state = const AppInitModelDownloading(progress: 0.0);
      _logger.i('AppInitNotifier: Model not installed, clearing stale downloads...');

      await _clearStaleDownload();

      const maxRetries = 3;
      Object? lastError;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          _logger.i('AppInitNotifier: Download attempt $attempt/$maxRetries');
          await FlutterGemma.installModel(modelType: ModelType.gemma4)
              .fromNetwork(_modelUrl, foreground: true)
              .withProgress((progress) {
            state = AppInitModelDownloading(progress: progress / 100.0);
          }).install();
          lastError = null;
          break;
        } catch (e) {
          lastError = e;
          _logger.w('AppInitNotifier: Download attempt $attempt failed: $e');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 5));
            await _clearStaleDownload();
          }
        }
      }

      if (lastError != null) {
        _logger.e('AppInitNotifier: All download attempts failed');
        state = AppInitModelFailed(
          'Download gagal setelah $maxRetries percobaan.\n\n'
          'Error: $lastError\n\n'
          'Solusi:\n'
          '1. Restart aplikasi dan coba lagi\n'
          '2. Jika tetap gagal, download manual dari:\n'
          '   $_modelUrl\n'
          '3. Letakkan file di folder Downloads dengan nama:\n'
          '   $_modelFileName',
        );
        return;
      }
    }

    await _loadModel();
  }

  Future<void> _loadModel() async {
    state = const AppInitLoading();
    _logger.i('AppInitNotifier: Loading model into memory...');

    try {
      final model = await FlutterGemma.getActiveModel(
        preferredBackend: PreferredBackend.gpu,
      );

      debugPrint('MODEL: Load SUCCESS');

      final gemmaService = getIt<GemmaService>();
      await gemmaService.initialize(model);

      _logger.i('AppInitNotifier: Model loaded successfully');
      state = const AppInitModelReady();

      await _initVoiceService();

      _logger.i('AppInitNotifier: Model ready — AI fully operational');
    } catch (e, stack) {
      debugPrint('MODEL: Load FAILED — $e');
      debugPrint('STACK: $stack');
      _logger.e(
        'AppInitNotifier: Model load failed',
        error: e,
      );
      state = AppInitModelFailed('Model gagal dimuat: $e');
    }
  }

  Future<void> _initVoiceService() async {
    try {
      final voiceService = getIt<VoiceService>();
      final result = await voiceService.initialize();
      _logger.i('AppInitNotifier: Voice service init result: $result');
    } catch (e) {
      _logger.w('AppInitNotifier: Voice service init failed: $e');
    }
  }

  void markAsDegraded(String reason) {
    _logger.w('AppInitNotifier: AI degraded — $reason');
    state = AppInitAiDegraded(reason);
  }

  void markAsFailed(String reason) {
    _logger.e('AppInitNotifier: AI permanently failed — $reason');
    state = AppInitModelFailed(reason);
  }
}
