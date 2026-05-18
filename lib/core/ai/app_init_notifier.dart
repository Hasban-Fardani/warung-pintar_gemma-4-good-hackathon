import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

  /// Expected model size in bytes (~2.5 GB)
  static const int _expectedModelSize = 2588147712;

  /// Minimum valid model size in bytes (>2 GB)
  static const int _minValidModelSize = 2200000000;

  /// Active model id used by flutter_gemma (uses file name with extension)
  static const String _modelId = 'gemma-4-E2B-it.litertlm';

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(minutes: 30),
  ));

  Future<void> initialize() async {
    _logger.i('AppInitNotifier: Starting initialization...');

    try {
      final modelFile = await _getModelFile();

      // Step 1: Check app documents dir — file must exist AND be valid (>2GB)
      final appDocsValid = await modelFile.exists() && await _isFileValid(modelFile);

      if (appDocsValid) {
        _logger.i('AppInitNotifier: Valid model file found in app docs dir, installing...');
        await _installFromFile(modelFile);
      } else {
        // Step 2: Request storage permission (needed for /sdcard/Download/ access on Android 11+)
        await _requestStoragePermissionIfNeeded();

        // Step 3: Check sideload path (/storage/emulated/0/Download/)
        final sideloadFile = await _getSideloadedModelFile();
        final sideloadValid = sideloadFile != null &&
            await sideloadFile.exists() &&
            await _isFileValid(sideloadFile);

        if (sideloadValid) {
          _logger.i('AppInitNotifier: Valid sideload model found, copying to app docs dir...');
          // Delete old corrupted file if it exists
          if (await modelFile.exists()) {
            await modelFile.delete();
            _logger.i('AppInitNotifier: Deleted old/invalid model from app docs dir');
          }
          // Copy sideloaded model to app docs dir (use streaming to avoid cross-mount Permission denied)
          await _streamingCopy(sideloadFile, modelFile);
          _logger.i('AppInitNotifier: Sideload model copied to app docs dir');

          // Force uninstall stale model metadata so installModel() re-registers
          await _forceUninstallIfNeeded();

          await _installFromFile(modelFile);
        } else {
          // Step 3: Fallback — download from HuggingFace
          _logger.i('AppInitNotifier: No valid model file found locally, downloading...');
          await _downloadWithResume(modelFile);
        }
      }

      // Step 4: Load model into memory
      _logger.i('AppInitNotifier: Model installed, now loading into memory...');
      await _loadModel();
    } catch (e, stack) {
      _logger.e('AppInitNotifier: Initialization failed', error: e, stackTrace: stack);
      state = AppInitModelFailed('Inisialisasi gagal: $e');
    }
  }

  /// Check if a model file is valid based on its size
  Future<bool> _isFileValid(File file) async {
    try {
      final size = await file.length();
      final valid = size >= _minValidModelSize && size <= _expectedModelSize + 1000000;
      if (!valid) {
        _logger.w(
          'AppInitNotifier: Model file too small or size mismatch: '
          '${(size / 1024 / 1024).toStringAsFixed(0)} MB '
          '(expected ~${(_expectedModelSize / 1024 / 1024).toStringAsFixed(0)} MB)',
        );
      }
      return valid;
    } catch (e) {
      _logger.w('AppInitNotifier: Failed to check file size: $e');
      return false;
    }
  }

  /// Forcefully remove stale flutter_gemma metadata so re-install works
  Future<void> _forceUninstallIfNeeded() async {
    try {
      await FlutterGemma.uninstallModel(_modelId);
      _logger.i('AppInitNotifier: Stale model uninstalled from flutter_gemma registry');
    } catch (e) {
      // May throw if model was not previously installed — that's fine
      _logger.i('AppInitNotifier: No stale model to uninstall: $e');
    }
  }

  /// Copy a large file by streaming in chunks.
  /// On Android scoped storage, File.copy() fails across mount points
  /// (e.g. /storage/emulated/0/ → /data/user/0/), but openRead/openWrite works.
  static Future<void> _streamingCopy(File source, File destination) async {
    final reader = source.openRead();
    final writer = destination.openWrite(mode: FileMode.write);
    try {
      await for (final chunk in reader) {
        writer.add(chunk);
      }
      await writer.flush();
    } finally {
      await writer.close();
    }
  }

  Future<File> _getModelFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_modelFileName');
  }

  /// Request broad storage access on Android so we can read from /sdcard/Download/
  Future<bool> _requestStoragePermissionIfNeeded() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) return true;

      _logger.i('AppInitNotifier: Requesting MANAGE_EXTERNAL_STORAGE permission...');
      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) {
        _logger.i('AppInitNotifier: Storage permission granted');
        return true;
      } else {
        _logger.w('AppInitNotifier: Storage permission denied');
        return false;
      }
    }
    return true;
  }

  /// Get sideloaded model file from Downloads folder
  Future<File?> _getSideloadedModelFile() async {
    try {
      final downloadsPath = '/storage/emulated/0/Download/$_modelFileName';
      _logger.i('AppInitNotifier: Checking sideload path: $downloadsPath');
      final file = File(downloadsPath);
      if (await file.exists()) {
        final size = await file.length();
        _logger.i('AppInitNotifier: Sideload file exists, size: ${(size / 1024 / 1024).toStringAsFixed(0)} MB');
      }
      return file;
    } catch (e) {
      _logger.w('AppInitNotifier: Failed to get sideload path: $e');
      return null;
    }
  }

  Future<void> _installFromFile(File modelFile) async {
    state = const AppInitLoading();
    try {
      if (!await modelFile.exists()) {
        throw Exception('Model file does not exist');
      }

      // Force uninstall stale metadata first to ensure fresh installation
      await _forceUninstallIfNeeded();

      _logger.i('AppInitNotifier: Calling FlutterGemma.installModel...');
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(modelFile.path).install();
      _logger.i('AppInitNotifier: Model installed from file successfully');
    } catch (e) {
      _logger.w('AppInitNotifier: Install from file failed ($e)');

      // Try recovery: check sideload path before falling back to download
      final sideloadFile = await _getSideloadedModelFile();
      if (sideloadFile != null && await sideloadFile.exists() && await _isFileValid(sideloadFile)) {
        _logger.i('AppInitNotifier: Retrying install from sideload after failure...');
        try {
          await _streamingCopy(sideloadFile, modelFile);
          await _forceUninstallIfNeeded();
          await FlutterGemma.installModel(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          ).fromFile(modelFile.path).install();
          _logger.i('AppInitNotifier: Install succeeded from sideload retry');
          return;
        } catch (e2) {
          _logger.w('AppInitNotifier: Sideload retry also failed ($e2)');
        }
      }

      // Fallback to download
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
            final elapsed = now.difference(lastTime).inMilliseconds / 1000.0;
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
          'Download incomplete: $downloadedSize/$totalBytes bytes',
        );
      }

      _logger.i('AppInitNotifier: Download complete, installing...');
      state = const AppInitLoading();

      await _forceUninstallIfNeeded();

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
    _logger.i('AppInitNotifier: _loadModel started, current state: $state');
    state = const AppInitLoading();
    _logger.i('AppInitNotifier: Loading model into memory...');

    try {
      _logger.i('AppInitNotifier: Calling FlutterGemma.getActiveModel...');
      final model = await FlutterGemma.getActiveModel(
        preferredBackend: PreferredBackend.gpu,
      );
      _logger.i('AppInitNotifier: getActiveModel returned, model: $model');

      _logger.i('AppInitNotifier: Initializing GemmaService...');
      final gemmaService = getIt<GemmaService>();
      await gemmaService.initialize(model);
      _logger.i('AppInitNotifier: GemmaService initialized');

      _logger.i('AppInitNotifier: Model loaded successfully, setting state to Ready');
      state = const AppInitModelReady();
      _logger.i('AppInitNotifier: State is now: $state');

      await _initVoiceService();
    } catch (e, stack) {
      _logger.e('AppInitNotifier: Model load failed', error: e, stackTrace: stack);

      // Try recovery: if sideload model exists, force re-copy and reinstall
      final recovered = await _tryRecoverFromSideload(e);
      if (recovered) {
        return;
      }

      state = AppInitModelFailed('Model gagal dimuat: $e');
    }
  }

  /// Recovery attempt when model fails to load into memory.
  /// If a valid sideloaded model exists, force recopy and reinstall.
  Future<bool> _tryRecoverFromSideload(dynamic originalError) async {
    try {
      final sideloadFile = await _getSideloadedModelFile();
      if (sideloadFile == null || !(await sideloadFile.exists()) || !(await _isFileValid(sideloadFile))) {
        _logger.w('AppInitNotifier: Recovery skipped — no valid sideload model');
        return false;
      }

      _logger.i('AppInitNotifier: Attempting recovery from sideload model...');

      final modelFile = await _getModelFile();
      if (await modelFile.exists()) {
        await modelFile.delete();
        _logger.i('AppInitNotifier: Deleted invalid model for recovery');
      }

      await _streamingCopy(sideloadFile, modelFile);
      _logger.i('AppInitNotifier: Recovery copy complete');

      await _forceUninstallIfNeeded();

      _logger.i('AppInitNotifier: Reinstalling model from recovered file...');
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(modelFile.path).install();

      _logger.i('AppInitNotifier: Re-attempting model load after recovery...');
      final model = await FlutterGemma.getActiveModel(
        preferredBackend: PreferredBackend.gpu,
      );

      final gemmaService = getIt<GemmaService>();
      await gemmaService.initialize(model);
      state = const AppInitModelReady();
      await _initVoiceService();

      _logger.i('AppInitNotifier: Recovery succeeded!');
      return true;
    } catch (e, stack) {
      _logger.e('AppInitNotifier: Recovery also failed', error: e, stackTrace: stack);
      return false;
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
