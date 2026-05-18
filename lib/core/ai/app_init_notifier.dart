import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

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
  static const double _minValidSizeBytes = 100 * 1024 * 1024;

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(minutes: 30),
  ));

  Future<void> initialize() async {
    _logger.i('AppInitNotifier: Starting initialization...');

    try {
      final modelFile = await _getModelFile();
      final isValid = await _isModelFileValid(modelFile);

      if (isValid) {
        _logger.i('AppInitNotifier: Valid model found on disk, installing...');
        await _installFromFile(modelFile);
      } else {
        if (await modelFile.exists()) {
          _logger.w('AppInitNotifier: Corrupt/incomplete model found, deleting...');
          await modelFile.delete();
        }
        // Direct download to app documents with resume support
        await _downloadWithResume(modelFile);
      }

      await _loadModel();
    } catch (e, stack) {
      _logger.e('AppInitNotifier: Initialization failed', error: e, stackTrace: stack);
      state = AppInitModelFailed('Inisialisasi gagal: $e');
    }
  }

  Future<File> _getModelFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_modelFileName');
  }

  Future<bool> _isModelFileValid(File file) async {
    if (!await file.exists()) return false;
    final size = await file.length();
    _logger.i('AppInitNotifier: Found model file, size: ${(size / 1024 / 1024).toStringAsFixed(0)} MB');
    return size > _minValidSizeBytes;
  }

  Future<void> _installFromFile(File modelFile) async {
    state = const AppInitLoading();
    try {
      if (!await modelFile.exists()) {
        throw Exception('Model file does not exist');
      }
      final size = await modelFile.length();
      if (size <= _minValidSizeBytes) {
        throw Exception('Model file too small: ${(size / 1024 / 1024).toStringAsFixed(0)} MB');
      }

      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(modelFile.path).install();
      _logger.i('AppInitNotifier: Model installed from file successfully');
    } catch (e) {
      _logger.w('AppInitNotifier: Install from file failed ($e), deleting and re-downloading...');
      if (await modelFile.exists()) {
        await modelFile.delete();
      }
      await _downloadWithResume(modelFile);
    }
  }

  Future<void> _downloadWithResume(File modelFile) async {
    _logger.i('AppInitNotifier: Starting download from $_modelUrl');
    state = const AppInitModelDownloading(progress: 0, speedMBps: 0, eta: 'menghitung...');

    DateTime? lastTime;
    double lastProgress = 0;
    final List<({double speed, DateTime time})> samples = [];

    try {
      int existingSize = 0;
      if (await modelFile.exists()) {
        existingSize = await modelFile.length();
        _logger.i('AppInitNotifier: Resuming from byte: $existingSize');
      }

      final response = await _dio.get<ResponseBody>(
        _modelUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: existingSize > 0 ? {'Range': 'bytes=$existingSize-'} : null,
        ),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Download response body is null');
      }
      final totalBytes = responseData.contentLength ?? 0;
      final startBytes = existingSize;
      final isResume = existingSize > 0 && response.headers.value('content-range') != null;

      if (isResume) {
        _logger.i('AppInitNotifier: Resuming download, starting from: $startBytes bytes');
      } else {
        _logger.i('AppInitNotifier: Total size: ${(totalBytes / 1024 / 1024).toStringAsFixed(0)} MB');
      }

      final sink = modelFile.openWrite(mode: FileMode.writeOnlyAppend);
      int receivedBytes = startBytes;

      try {
        await for (final chunk in responseData.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;

          final contentLength = totalBytes > 0 ? totalBytes : receivedBytes;
          final progress = contentLength > 0 ? receivedBytes / contentLength : 0.0;
          final now = DateTime.now();

          if (lastTime != null) {
            final elapsed = now.difference(lastTime!).inMilliseconds / 1000.0;
            if (elapsed > 0.5) {
              final deltaProgress = progress - lastProgress;
              final speedMBps = (deltaProgress * contentLength / 1024 / 1024) / elapsed;
              samples.add((speed: speedMBps, time: now));
              if (samples.length > 5) samples.removeAt(0);
              lastProgress = progress;
              lastTime = now;
            }
          } else {
            lastTime = now;
          }

          final avgSpeed = samples.isEmpty
              ? 0.0
              : samples.map((s) => s.speed).reduce((a, b) => a + b) / samples.length;

          String eta = 'menghitung...';
          if (avgSpeed > 0.01 && progress > 0.01) {
            final remainingMB = (1 - progress) * contentLength / 1024 / 1024;
            final secs = remainingMB / avgSpeed;
            eta = secs >= 60
                ? '${(secs / 60).floor()}m ${(secs % 60).floor()}d'
                : '${secs.floor()}d';
          }

          state = AppInitModelDownloading(
            progress: progress,
            speedMBps: avgSpeed,
            eta: eta,
          );
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      final downloadedSize = await modelFile.length();
      if (totalBytes > 0 && downloadedSize < totalBytes * 0.99) {
        throw Exception(
          'Download incomplete: ${downloadedSize}/${totalBytes} bytes',
        );
      }

      _logger.i('AppInitNotifier: Download complete, installing...');
      state = const AppInitLoading();

      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(modelFile.path).install();

      _logger.i('AppInitNotifier: Installation complete');
    } catch (e) {
      _logger.e('AppInitNotifier: Download/install failed: $e');
      if (await modelFile.exists()) {
        await modelFile.delete();
        _logger.i('AppInitNotifier: Partial file deleted');
      }
      rethrow;
    }
  }

  Future<void> _loadModel() async {
    state = const AppInitLoading();
    _logger.i('AppInitNotifier: Loading model into memory...');

    try {
      final model = await FlutterGemma.getActiveModel(
        preferredBackend: PreferredBackend.gpu,
      );

      final gemmaService = getIt<GemmaService>();
      await gemmaService.initialize(model);

      _logger.i('AppInitNotifier: Model loaded successfully');
      state = const AppInitModelReady();

      await _initVoiceService();
    } catch (e, stack) {
      _logger.e('AppInitNotifier: Model load failed', error: e, stackTrace: stack);
      state = AppInitModelFailed('Model gagal dimuat: $e');
    }
  }

  Future<void> _initVoiceService() async {
    try {
      final voiceService = getIt<VoiceService>();
      await voiceService.initialize();
    } catch (e) {
      _logger.w('AppInitNotifier: Voice init failed: $e');
    }
  }

  void markAsDegraded(String reason) => state = AppInitAiDegraded(reason);
  void markAsFailed(String reason) => state = AppInitModelFailed(reason);
}
