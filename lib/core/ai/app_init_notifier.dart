import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';
import 'package:warung_pintar_cimahi/core/ai/gemma_service.dart';
import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/voice/voice_service_impl.dart';

final appInitProvider = StateNotifierProvider<AppInitNotifier, AppInitState>(
  (ref) => AppInitNotifier(),
);

class AppInitNotifier extends StateNotifier<AppInitState> {
  AppInitNotifier() : super(const AppInitLoading());

  static const String _modelFileName = 'gemma-4-E2B-it.litertlm';
  static const String _zipAssetPath = 'assets/models/gemma.zip';

  static const double _totalSizeMB = 2594.0;
  static const int _windowSize = 5;

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  final List<_SpeedSample> _speedSamples = [];
  DateTime? _lastSampleTime;
  double _lastProgress = 0;

  Future<void> initialize() async {
    _logger.i('AppInitNotifier: Starting initialization...');

    final alreadyOnDisk = await FlutterGemma.isModelInstalled(_modelFileName);

    if (FlutterGemma.hasActiveModel()) {
      _logger.i('AppInitNotifier: Active model found, loading...');
    } else if (alreadyOnDisk) {
      _logger.i('AppInitNotifier: Model file exists on disk but not active, loading...');
    } else {
      state = const AppInitModelDownloading(progress: 0.0);
      _logger.i('AppInitNotifier: Model not found, stitching from bundled chunks...');

      try {
        await FlutterGemma.uninstallModel(_modelFileName);
      } catch (_) {}

      try {
        // Step 1: Stitch chunks from Assets
        final appDir = await getApplicationDocumentsDirectory();
        final targetFile = File('${appDir.path}/$_modelFileName');
        
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        final chunkPaths = manifest.listAssets()
            .where((path) => path.startsWith('assets/models/model_part_'))
            .toList()..sort();
            
        if (chunkPaths.isEmpty) {
          throw Exception('No model chunks found in assets/models/');
        }
        
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await targetFile.create(recursive: true);
        
        for (int i = 0; i < chunkPaths.length; i++) {
          final data = await rootBundle.load(chunkPaths[i]);
          await targetFile.writeAsBytes(data.buffer.asUint8List(), mode: FileMode.append, flush: true);
          
          final progress = (i + 1) / chunkPaths.length * 100.0;
          _updateProgress(progress);
        }

        // Step 2: Install via fromFile
        _logger.i('AppInitNotifier: Chunks stitched to ${targetFile.path}, installing model...');
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        ).fromFile(targetFile.path).install();
        
        // Clean up extracted temp file to save space if FlutterGemma copies it internally
        try {
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
        } catch (_) {}
      } catch (e) {
        _logger.e('AppInitNotifier: Stitching/Installation failed: $e');
        state = AppInitModelFailed(
          'Penyiapan model gagal: $e\n\n'
          'Pastikan ruang penyimpanan cukup dan coba lagi.',
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
