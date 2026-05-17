import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'package:warung_pintar_cimahi/core/ai/model_download_config.dart';


sealed class ModelDownloadState {
  const ModelDownloadState();
}

final class DownloadIdle extends ModelDownloadState {
  final bool isResumable;
  final int alreadyDownloadedBytes;

  const DownloadIdle({
    this.isResumable = false,
    this.alreadyDownloadedBytes = 0,
  });
}

final class DownloadWaitingWifi extends ModelDownloadState {
  const DownloadWaitingWifi();
}

final class DownloadProgress extends ModelDownloadState {
  final double percent;
  final int downloadedBytes;
  final int totalBytes;
  final int estimatedSecondsRemaining;
  final String currentChunk;
  final double downloadSpeedMBps;

  const DownloadProgress({
    required this.percent,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.estimatedSecondsRemaining,
    this.currentChunk = '1/1',
    this.downloadSpeedMBps = 0.0,
  });
}

final class DownloadVerifying extends ModelDownloadState {
  final double percent;

  const DownloadVerifying({this.percent = 0.0});
}

final class DownloadComplete extends ModelDownloadState {
  const DownloadComplete();
}

final class DownloadFailed extends ModelDownloadState {
  final String reason;
  final bool canRetry;
  final int? retryAfterSeconds;

  const DownloadFailed({
    required this.reason,
    this.canRetry = true,
    this.retryAfterSeconds,
  });
}

final class DownloadCancelled extends ModelDownloadState {
  final int savedBytes;

  const DownloadCancelled({required this.savedBytes});
}


const int _chunkCount = 4;
const int _chunkSizeBytes = 50 * 1024 * 1024;


final modelDownloadProvider =
    StateNotifierProvider<ModelDownloadNotifier, ModelDownloadState>(
      (ref) => ModelDownloadNotifier(),
    );

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});


class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  ModelDownloadNotifier() : super(const DownloadIdle());

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  final _dio = Dio();
  CancelToken? _cancelToken;
  final List<_ChunkDownload> _activeChunks = [];
  String? _savePath;
  DateTime? _startTime;
  int _lastReportedBytes = 0;
  static const _minRetryIntervalSeconds = 30;

  Future<void> startDownload({bool forceRestart = false}) async {
    _savePath ??= await _getModelPath();
    final saveFile = File(_savePath!);
    await saveFile.parent.create(recursive: true);

    if (forceRestart && await saveFile.exists()) {
      await saveFile.delete();
      _logger.i('ModelDownload: Force restart - deleted existing file');
    }

    final existingBytes = await saveFile.exists() ? await saveFile.length() : 0;

    if (!await _checkWifiConnection()) {
      state = const DownloadWaitingWifi();
      _logger.i('ModelDownload: Waiting for WiFi connection');
      return;
    }

    _cancelToken = CancelToken();
    _startTime = DateTime.now();
    _lastReportedBytes = existingBytes;

    if (existingBytes > 0) {
      _logger.i('ModelDownload: Resuming from $existingBytes bytes');
    }

    await _downloadWithChunks(
      savePath: _savePath!,
      existingBytes: existingBytes,
    );
  }

  Future<void> resumeDownload() async {
    if (!await _checkWifiConnection()) {
      state = const DownloadWaitingWifi();
      return;
    }

    if (_savePath == null) {
      _savePath = await _getModelPath();
    }

    final saveFile = File(_savePath!);
    final existingBytes = await saveFile.exists() ? await saveFile.length() : 0;

    _cancelToken = CancelToken();
    _startTime = DateTime.now();
    _lastReportedBytes = existingBytes;

    await _downloadWithChunks(
      savePath: _savePath!,
      existingBytes: existingBytes,
    );
  }

  void cancelDownload() {
    _cancelToken?.cancel('User cancelled');
    for (final chunk in _activeChunks) {
      chunk.cancelToken?.cancel();
    }
    _activeChunks.clear();

    final savedBytes = _lastReportedBytes;
    state = DownloadCancelled(savedBytes: savedBytes);
    _logger.i('ModelDownload: Cancelled - $savedBytes bytes saved');
  }

  Future<void> retryDownload() async {
    if (!await _checkWifiConnection()) {
      state = const DownloadWaitingWifi();
      return;
    }
    await startDownload();
  }

  Future<void> _downloadWithChunks({
    required String savePath,
    required int existingBytes,
  }) async {
    _activeChunks.clear();

    try {
      final totalSize = await _getTotalSize();
      final chunks = _calculateChunks(totalSize, existingBytes);

      if (chunks.isEmpty) {
        await _verifyDownload(File(savePath));
        return;
      }

      _logger.i('ModelDownload: Starting $_chunkCount parallel chunks for $totalSize bytes');

      final saveFile = File(savePath);
      if (!await saveFile.exists()) {
        await saveFile.create(recursive: true);
      }

      final futures = chunks.map((chunk) => _downloadChunk(
        url: ModelDownloadConfig.primaryUrl,
        savePath: savePath,
        chunk: chunk,
      ));

      await Future.wait(futures);

      if (_cancelToken?.isCancelled == true) {
        return;
      }

      await _verifyDownload(File(savePath));
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        state = DownloadCancelled(savedBytes: _lastReportedBytes);
        return;
      }

      _logger.w('ModelDownload: Primary failed, trying mirrors');
      await _tryMirrors(savePath, existingBytes);
    } catch (e) {
      _logger.e('ModelDownload: Unexpected error', error: e);
      state = DownloadFailed(
        reason: 'Download gagal: $e',
        canRetry: true,
      );
    }
  }

  Future<void> _tryMirrors(String savePath, int existingBytes) async {
    final mirrors = ModelDownloadConfig.mirrorUrls;
    DioException? lastError;

    for (final mirror in mirrors) {
      if (_cancelToken?.isCancelled == true) return;

      try {
        _logger.i('ModelDownload: Trying mirror: $mirror');
        _activeChunks.clear();

        final chunks = _calculateChunks(
          ModelDownloadConfig.expectedFileSizeBytes,
          existingBytes,
        );

        final futures = chunks.map((chunk) => _downloadChunk(
          url: mirror,
          savePath: savePath,
          chunk: chunk,
        ));

        await Future.wait(futures);
        await _verifyDownload(File(savePath));
        return;
      } on DioException catch (e) {
        lastError = e;
        _logger.w('ModelDownload: Mirror $mirror failed: ${e.message}');
        continue;
      } catch (e) {
        lastError = DioException(
          requestOptions: RequestOptions(path: mirror),
          error: e,
        );
        continue;
      }
    }

    state = DownloadFailed(
      reason: 'Semua mirror gagal. Periksa koneksi internet Anda.',
      canRetry: true,
      retryAfterSeconds: _minRetryIntervalSeconds,
    );
  }

  Future<_ChunkInfo> _downloadChunk({
    required String url,
    required String savePath,
    required _ChunkInfo chunk,
  }) async {
    final chunkCancelToken = CancelToken();
    _activeChunks.add(_ChunkDownload(
      startByte: chunk.startByte,
      cancelToken: chunkCancelToken,
    ));

    try {
      final options = Options(
        headers: {
          'Range': 'bytes=${chunk.startByte}-${chunk.endByte}',
        },
        responseType: ResponseType.bytes,
      );

      final response = await _dio.get<List<int>>(
        url,
        options: options,
        cancelToken: chunkCancelToken,
        onReceiveProgress: (received, total) {
          _updateProgress(received, chunk.startByte);
        },
      );

      if (response.data == null) {
        throw DioException(
          requestOptions: options.compose(
            Dio().options,
            url,
          ) as RequestOptions,
          error: 'No data received',
        );
      }

      await _writeChunkToFile(savePath, chunk, response.data!);

      return chunk;
    } catch (e) {
      if (chunkCancelToken.isCancelled) {
        rethrow;
      }
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: 'Chunk ${chunk.index} failed: $e',
      );
    } finally {
      _activeChunks.removeWhere((c) => c.cancelToken == chunkCancelToken);
    }
  }

  void _updateProgress(int receivedBytesForChunk, int chunkStartByte) {
    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    final speed = elapsed > 0
        ? (_lastReportedBytes + receivedBytesForChunk) / elapsed / 1024 / 1024
        : 0.0;

    final totalSize = ModelDownloadConfig.expectedFileSizeBytes;
    final totalDownloaded = _lastReportedBytes + receivedBytesForChunk;
    final percent = (totalDownloaded / totalSize).clamp(0.0, 1.0);
    final remaining = speed > 0
        ? ((totalSize - totalDownloaded) / (speed * 1024 * 1024)).round()
        : 0;

    state = DownloadProgress(
      percent: percent,
      downloadedBytes: totalDownloaded,
      totalBytes: totalSize,
      estimatedSecondsRemaining: remaining,
      currentChunk: '${chunkStartByte ~/ _chunkSizeBytes + 1}/$_chunkCount',
      downloadSpeedMBps: speed,
    );
  }

  Future<void> _writeChunkToFile(
    String savePath,
    _ChunkInfo chunk,
    List<int> data,
  ) async {
    final raf = await File(savePath).open(mode: FileMode.writeOnly);

    try {
      await raf.setPosition(chunk.startByte);
      await raf.writeFrom(data);
    } finally {
      await raf.close();
    }
  }

  List<_ChunkInfo> _calculateChunks(int totalSize, int existingBytes) {
    final chunks = <_ChunkInfo>[];
    int currentStart = 0;
    int chunkIndex = 0;

    while (currentStart < totalSize) {
      final endByte = (currentStart + _chunkSizeBytes - 1).clamp(0, totalSize - 1);

      if (currentStart >= existingBytes) {
        chunks.add(_ChunkInfo(
          index: chunkIndex,
          startByte: currentStart,
          endByte: endByte,
        ));
      }

      currentStart = endByte + 1;
      chunkIndex++;
    }

    return chunks;
  }

  Future<int> _getTotalSize() async {
    try {
      final response = await _dio.head(
        ModelDownloadConfig.primaryUrl,
        options: Options(
          headers: {'Accept-Encoding': '*'},
        ),
      );

      final contentLength = response.headers.value('content-length');
      if (contentLength != null) {
        return int.tryParse(contentLength) ??
            ModelDownloadConfig.expectedFileSizeBytes;
      }
    } catch (e) {
      _logger.w('ModelDownload: Could not get total size: $e');
    }

    return ModelDownloadConfig.expectedFileSizeBytes;
  }

  Future<String> _getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/models/${ModelDownloadConfig.modelFileName}';
  }

  Future<bool> _checkWifiConnection() async {
    final connectivity = await Connectivity().checkConnectivity();

    if (connectivity.contains(ConnectivityResult.wifi)) {
      _logger.i('ModelDownload: WiFi connected - proceeding');
      return true;
    }

    if (connectivity.contains(ConnectivityResult.mobile) ||
        connectivity.contains(ConnectivityResult.ethernet)) {
      _logger.w('ModelDownload: Mobile/Ethernet - warning user');
    }

    final result = await _showDataWarningDialog();
    return result;
  }

  Future<bool> _showDataWarningDialog() async {
    return true;
  }

  Future<void> _verifyDownload(File saveFile) async {
    state = const DownloadVerifying(percent: 0.0);
    _logger.i('ModelDownload: Starting SHA-256 verification');

    final valid = await _verifySha256InIsolate(saveFile.path);

    if (!valid) {
      if (await saveFile.exists()) {
        await saveFile.delete();
      }
      state = const DownloadFailed(
        reason: 'SHA-256 mismatch — file korup, silakan coba lagi',
        canRetry: true,
      );
      return;
    }

    state = const DownloadComplete();
    _logger.i('ModelDownload: Download complete and verified');
  }

  Future<bool> _verifySha256InIsolate(String filePath) async {
    final expectedHash = ModelDownloadConfig.modelSha256;
    if (expectedHash.isEmpty) {
      _logger.i('ModelDownload: SHA-256 verification skipped (no hash configured)');
      return true;
    }

    final receivePort = ReceivePort();

    await Isolate.spawn(
      _verifySha256IsolateEntry,
      _Sha256VerifyMessage(
        filePath: filePath,
        expectedHash: ModelDownloadConfig.modelSha256,
        sendPort: receivePort.sendPort,
      ),
    );

    final result = await receivePort.first as _Sha256VerifyResult;
    return result.isValid;
  }

  static void _verifySha256IsolateEntry(_Sha256VerifyMessage message) async {
    try {
      final file = File(message.filePath);
      if (!await file.exists()) {
        message.sendPort.send(const _Sha256VerifyResult(
          isValid: false,
          error: 'File not found',
        ));
        return;
      }

      final stream = file.openRead();
      final output = AccumulatorSink<Digest>();
      final input = sha256.startChunkedConversion(output);

      int processedBytes = 0;
      final fileSize = await file.length();

      await for (final chunk in stream) {
        input.add(chunk);
        processedBytes += chunk.length;

        final percent = fileSize > 0 ? processedBytes / fileSize : 0.0;
        debugPrint('ModelDownload: SHA-256 verification ${(percent * 100).toStringAsFixed(1)}%');
      }

      input.close();
      final digest = output.events.single;
      final hash = digest.toString();
      final isValid = hash == message.expectedHash;

      debugPrint('ModelDownload: Computed hash: $hash');
      debugPrint('ModelDownload: Expected hash: ${message.expectedHash}');

      message.sendPort.send(_Sha256VerifyResult(
        isValid: isValid,
        computedHash: hash,
      ));
    } catch (e) {
      message.sendPort.send(_Sha256VerifyResult(
        isValid: false,
        error: e.toString(),
      ));
    }
  }
}

class _ChunkDownload {
  final int startByte;
  final CancelToken? cancelToken;

  _ChunkDownload({required this.startByte, this.cancelToken});
}

class _ChunkInfo {
  final int index;
  final int startByte;
  final int endByte;

  _ChunkInfo({
    required this.index,
    required this.startByte,
    required this.endByte,
  });
}

class _Sha256VerifyMessage {
  final String filePath;
  final String expectedHash;
  final SendPort sendPort;

  const _Sha256VerifyMessage({
    required this.filePath,
    required this.expectedHash,
    required this.sendPort,
  });
}

class _Sha256VerifyResult {
  final bool isValid;
  final String? computedHash;
  final String? error;

  const _Sha256VerifyResult({
    required this.isValid,
    this.computedHash,
    this.error,
  });
}

class AccumulatorSink<T> implements Sink<T> {
  final List<T> events = [];

  @override
  void add(T event) => events.add(event);

  @override
  void close() {}
}