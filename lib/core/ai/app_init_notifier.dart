import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';

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

  static const double _totalSizeMB = 2594.0;
  static const int _windowSize = 5;

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  final List<_SpeedSample> _speedSamples = [];
  DateTime? _lastSampleTime;
  double _lastProgress = 0;

  Future<void> initialize() async {
    _logger.i('AppInitNotifier: Starting initialization...');

    if (!FlutterGemma.hasActiveModel()) {
      state = const AppInitModelDownloading(progress: 0.0);
      _logger.i('AppInitNotifier: Model not installed, downloading via flutter_gemma...');

      try {
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        ).fromNetwork(_modelUrl, foreground: true).withProgress((progress) {
          _updateProgress(progress.toDouble());
        }).install();
      } catch (e) {
        _logger.e('AppInitNotifier: Download failed: $e');
        state = AppInitModelFailed(
          'Download gagal: $e\n\n'
          'Pastikan koneksi internet stabil dan coba lagi.',
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

  void _updateProgress(double progress) {
    final now = DateTime.now();
    final progressFraction = progress / 100.0;

    if (_lastSampleTime != null) {
      final elapsed = now.difference(_lastSampleTime!).inMilliseconds / 1000.0;
      if (elapsed > 0.5) {
        final deltaProgress = progress - _lastProgress;
        final speedMBps = (deltaProgress / elapsed) * (_totalSizeMB / 100);

        _speedSamples.add(_SpeedSample(speedMBps, now));
        if (_speedSamples.length > _windowSize) {
          _speedSamples.removeAt(0);
        }
      }
    }

    _lastSampleTime = now;
    _lastProgress = progress;

    double avgSpeedMBps = 0;
    if (_speedSamples.isNotEmpty) {
      avgSpeedMBps = _speedSamples.map((s) => s.speedMBps).reduce((a, b) => a + b) /
          _speedSamples.length;
    }

    String eta;
    if (avgSpeedMBps > 0.05 && progress > 1) {
      final remainingMB = (_totalSizeMB - (progressFraction * _totalSizeMB));
      final remainingSeconds = remainingMB / avgSpeedMBps;
      if (remainingSeconds >= 60) {
        final mins = (remainingSeconds / 60).floor();
        final secs = (remainingSeconds % 60).floor();
        eta = '${mins}m ${secs}d';
      } else {
        eta = '${remainingSeconds.floor()}d';
      }
    } else {
      eta = 'menghitung...';
    }

    state = AppInitModelDownloading(
      progress: progressFraction,
      speedMBps: avgSpeedMBps,
      eta: eta,
    );
  }
}

class _SpeedSample {
  final double speedMBps;
  final DateTime time;

  _SpeedSample(this.speedMBps, this.time);
}
