import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the on-device Gemma model file location and integrity (PRD §16.1.1).
///
/// Model is stored in app documents directory (not cache — survives
/// cache clears). SHA-256 verification ensures file integrity after download.
class ModelStorage {
  ModelStorage._();

  static final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static const String _modelFileName =
      'gemma-4-E2B-it-litertlm-Q4_K_M.litertlm';

  /// Placeholder SHA-256 — replace with official hash when model file
  /// is publicly available from Kaggle.
  static const String _modelSha256 =
      'a3f8c2d1e9b047f6a1c3e5d7b9f2a4c6'
      'e8d0b2f4a6c8e0d2b4f6a8c0e2d4b6f8';

  /// Full path to model file in app internal storage.
  static Future<String> get modelPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/models/$_modelFileName';
  }

  /// Check whether the model file exists and passes SHA-256 verification.
  static Future<bool> isModelReady() async {
    try {
      final path = await modelPath;
      final file = File(path);

      if (!await file.exists()) {
        _logger.d('ModelStorage: Model file not found at $path');
        return false;
      }

      final verified = await _verifySha256(file);
      if (!verified) {
        _logger.w('ModelStorage: SHA-256 mismatch — file may be corrupt');
      }
      return verified;
    } catch (e) {
      _logger.e('ModelStorage: Error checking model readiness', error: e);
      return false;
    }
  }

  /// Delete corrupt or partial model file.
  static Future<void> deleteModel() async {
    final path = await modelPath;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      _logger.i('ModelStorage: Deleted model file at $path');
    }
  }

  /// Verify SHA-256 hash of model file.
  ///
  /// Reads file as stream to avoid loading full 2.5GB into memory.
  static Future<bool> _verifySha256(File file) async {
    _logger.d('ModelStorage: Verifying SHA-256...');
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    final hash = digest.toString();
    _logger.d('ModelStorage: Computed hash: $hash');
    return hash == _modelSha256;
  }
}
