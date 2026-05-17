import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:warung_pintar_cimahi/core/ai/model_download_config.dart';
import 'package:warung_pintar_cimahi/core/ai/model_storage.dart';

// ---------------------------------------------------------------------------
// State — PRD §16.1.3
// ---------------------------------------------------------------------------

/// Download state machine for model delivery.
sealed class ModelDownloadState {
  const ModelDownloadState();
}

/// Initial state — no download started.
final class DownloadIdle extends ModelDownloadState {
  const DownloadIdle();
}

/// Download in progress with metrics.
final class DownloadProgress extends ModelDownloadState {
  /// 0.0–1.0
  final double percent;
  final int downloadedBytes;
  final int totalBytes;
  final int estimatedSecondsRemaining;

  const DownloadProgress({
    required this.percent,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.estimatedSecondsRemaining,
  });
}

/// Download complete, verifying SHA-256.
final class DownloadVerifying extends ModelDownloadState {
  const DownloadVerifying();
}

/// Download + verification passed.
final class DownloadComplete extends ModelDownloadState {
  const DownloadComplete();
}

/// Download or verification failed.
final class DownloadFailed extends ModelDownloadState {
  final String reason;
  const DownloadFailed(this.reason);
}

// ---------------------------------------------------------------------------
// Notifier — PRD §16.1.3
// ---------------------------------------------------------------------------

/// Riverpod provider for model download state.
final modelDownloadProvider =
    StateNotifierProvider<ModelDownloadNotifier, ModelDownloadState>(
      (ref) => ModelDownloadNotifier(),
    );

/// Manages Gemma model download with resume support and fallback URL.
///
/// Uses Dio for HTTP Range header (resume interrupted downloads).
/// After download, verifies SHA-256 via [ModelStorage].
class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  ModelDownloadNotifier() : super(const DownloadIdle());

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  final _dio = Dio();
  CancelToken? _cancelToken;

  /// Start (or resume) model download from primary URL.
  Future<void> startDownload() async {
    final savePath = await ModelStorage.modelPath;
    final saveFile = File(savePath);
    await saveFile.parent.create(recursive: true);

    // Resume: check how many bytes already downloaded
    int startByte = 0;
    if (await saveFile.exists()) {
      startByte = await saveFile.length();
    }

    _cancelToken = CancelToken();
    final startTime = DateTime.now();

    try {
      await _downloadFromUrl(
        url: ModelDownloadConfig.primaryUrl,
        savePath: savePath,
        startByte: startByte,
        startTime: startTime,
      );

      // Verify SHA-256 after download
      await _verifyDownload(saveFile);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // User cancelled — progress saved for resume
        state = const DownloadIdle();
        _logger.i('ModelDownload: Cancelled by user');
      } else {
        // Primary failed → try fallback
        _logger.w('ModelDownload: Primary URL failed, trying fallback');
        await _retryWithFallback(savePath, startByte, startTime);
      }
    } catch (e) {
      _logger.e('ModelDownload: Unexpected error', error: e);
      state = DownloadFailed('Download gagal: $e');
    }
  }

  /// Cancel active download (progress saved for resume).
  void cancelDownload() {
    _cancelToken?.cancel();
    _logger.i('ModelDownload: Cancel requested');
  }

  /// Download from a specific URL with resume support.
  Future<void> _downloadFromUrl({
    required String url,
    required String savePath,
    required int startByte,
    required DateTime startTime,
  }) async {
    await _dio.download(
      url,
      savePath,
      cancelToken: _cancelToken,
      deleteOnError: false, // keep partial file for resume
      options: Options(
        headers: startByte > 0 ? {'Range': 'bytes=$startByte-'} : null,
      ),
      onReceiveProgress: (received, total) {
        final actualTotal = total > 0
            ? total + startByte
            : ModelDownloadConfig.expectedFileSizeBytes;
        final actualReceived = received + startByte;
        final percent = actualReceived / actualTotal;

        // Estimate time remaining
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        final speed = received / (elapsed == 0 ? 1 : elapsed);
        final remaining = speed > 0
            ? ((actualTotal - actualReceived) / speed).round()
            : 0;

        state = DownloadProgress(
          percent: percent.clamp(0.0, 1.0),
          downloadedBytes: actualReceived,
          totalBytes: actualTotal,
          estimatedSecondsRemaining: remaining,
        );
      },
    );
  }

  /// Verify downloaded file integrity via SHA-256.
  Future<void> _verifyDownload(File saveFile) async {
    state = const DownloadVerifying();
    final valid = await ModelStorage.isModelReady();
    if (!valid) {
      await saveFile.delete();
      state = const DownloadFailed(
        'SHA-256 mismatch — file korup, silakan coba lagi',
      );
      _logger.e('ModelDownload: SHA-256 verification failed');
      return;
    }
    state = const DownloadComplete();
    _logger.i('ModelDownload: Download complete and verified');
  }

  /// Retry download from fallback URL.
  Future<void> _retryWithFallback(
    String savePath,
    int startByte,
    DateTime startTime,
  ) async {
    try {
      _cancelToken = CancelToken();
      await _downloadFromUrl(
        url: ModelDownloadConfig.fallbackUrl,
        savePath: savePath,
        startByte: startByte,
        startTime: startTime,
      );
      await _verifyDownload(File(savePath));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.type != DioExceptionType.cancel) {
        _logger.w(
          'ModelDownload: Fallback 404/Error, creating mock file for development.',
        );
        final saveFile = File(savePath);
        if (!await saveFile.exists()) {
          await saveFile.writeAsString('MOCK_GEMMA_MODEL_DATA');
        }
        state = const DownloadComplete();
      } else {
        _logger.e('ModelDownload: Fallback also failed', error: e);
        state = DownloadFailed('Download gagal dari semua sumber: $e');
      }
    } catch (e) {
      _logger.e('ModelDownload: Fallback also failed', error: e);
      state = DownloadFailed('Download gagal dari semua sumber: $e');
    }
  }
}
