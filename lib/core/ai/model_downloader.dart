import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ModelDownloader {
  static const String _modelFileName = 'gemma-4-E2B-it.litertlm';
  static const int _minExpectedSizeBytes = 2400000000;

  CancelToken? _cancelToken;
  bool _isCancelled = false;

  Future<String> getModelSavePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return path.join(dir.path, _modelFileName);
  }

  Future<bool> isModelComplete(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    final stat = await file.stat();
    return stat.size >= _minExpectedSizeBytes;
  }

  Future<void> downloadWithResume({
    required String url,
    required void Function(double progress, double speedMBps, String eta) onProgress,
    required void Function() onComplete,
    required void Function(String error) onError,
  }) async {
    _isCancelled = false;
    _cancelToken = CancelToken();

    final savePath = await getModelSavePath();
    final file = File(savePath);

    await file.parent.create(recursive: true);

    int existingBytes = 0;
    if (await file.exists()) {
      existingBytes = (await file.stat()).size;
    }

    final dio = Dio();
    dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: Duration(minutes: 60),
      sendTimeout: const Duration(seconds: 30),
    );

    int totalBytes = 0;
    final startTime = DateTime.now();
    int lastBytes = existingBytes;

    try {
      final headResp = await dio.head(url);
      final contentLength = headResp.headers.value('content-length');
      if (contentLength != null) {
        totalBytes = int.parse(contentLength);
      }

      Options downloadOptions;
      if (existingBytes > 0 && totalBytes > existingBytes) {
        downloadOptions = Options(
          headers: {'Range': 'bytes=$existingBytes-$totalBytes'},
        );
      } else {
        downloadOptions = Options();
        existingBytes = 0;
      }

      await dio.download(
        url,
        savePath,
        options: downloadOptions,
        cancelToken: _cancelToken,
        deleteOnError: false,
        onReceiveProgress: (received, total) {
          if (_isCancelled) return;

          final currentBytes = existingBytes + received;
          final actualTotal = total ?? totalBytes;
          final progress = actualTotal > 0 ? currentBytes / actualTotal : 0.0;

          final elapsed = DateTime.now().difference(startTime).inSeconds;
          double speedMBps = 0;
          if (elapsed > 0) {
            speedMBps = (currentBytes - lastBytes) / elapsed / 1024 / 1024;
            if (speedMBps < 0) speedMBps = 0;
            lastBytes = currentBytes;
          }

          String eta = 'menghitung...';
          if (speedMBps > 0 && actualTotal > currentBytes) {
            final remainingBytes = actualTotal - currentBytes;
            final seconds = (remainingBytes / (speedMBps * 1024 * 1024)).round();
            if (seconds < 60) {
              eta = '$seconds detik';
            } else if (seconds < 3600) {
              eta = '${seconds ~/ 60} menit';
            } else {
              final hours = seconds ~/ 3600;
              final mins = (seconds % 3600) ~/ 60;
              eta = '$hours jam $mins menit';
            }
          }

          onProgress(progress, speedMBps, eta);
        },
      );

      if (!_isCancelled) {
        onComplete();
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return;
      }
      onError(e.message ?? 'Download failed');
    } catch (e) {
      onError(e.toString());
    }
  }

  void cancel() {
    _isCancelled = true;
    _cancelToken?.cancel('User cancelled');
  }
}
