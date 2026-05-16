import 'dart:async';
import 'dart:isolate';

import 'package:logger/logger.dart';

/// Gemma isolate service for background AI inference (PRD §10.4).
///
/// Runs Gemma 4 model in a separate isolate to prevent UI jank.
/// Singleton — model loaded once, kept alive for app lifetime.
class GemmaIsolateService {
  GemmaIsolateService._();

  static final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static SendPort? _sendPort;
  static Isolate? _isolate;
  static bool _isInitialized = false;

  /// Whether the isolate has been initialized and model is loaded.
  static bool get isInitialized => _isInitialized;

  /// Initialize the Gemma isolate and load the model.
  ///
  /// Must be called once during app startup (in `main.dart`).
  /// No-op if already initialized.
  static Future<void> init() async {
    if (_isInitialized) return;

    _logger.i('GemmaIsolateService: Initializing isolate...');

    try {
      final receivePort = ReceivePort();
      _isolate = await Isolate.spawn(
        _gemmaWorker,
        receivePort.sendPort,
      );

      // First message from worker is its SendPort
      _sendPort = await receivePort.first as SendPort;
      _isInitialized = true;
      _logger.i('GemmaIsolateService: Isolate ready');
    } catch (e) {
      _logger.e('GemmaIsolateService: Failed to initialize', error: e);
      rethrow;
    }
  }

  /// Run inference on the Gemma model in the background isolate.
  ///
  /// Returns raw JSON string from the model.
  /// Throws if isolate is not initialized or inference fails.
  static Future<String> infer(
    String prompt,
    String input,
    String? imageBase64,
  ) async {
    if (!_isInitialized || _sendPort == null) {
      throw StateError(
        'GemmaIsolateService not initialized. Call init() first.',
      );
    }

    final responsePort = ReceivePort();
    _sendPort!.send({
      'prompt': prompt,
      'input': input,
      'image': imageBase64,
      'replyPort': responsePort.sendPort,
    });

    final response = await responsePort.first;

    if (response is String) {
      return response;
    } else if (response is Map && response.containsKey('error')) {
      throw Exception(response['error']);
    }

    throw Exception('Unexpected response from Gemma isolate');
  }

  /// Dispose the isolate and free resources.
  static void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    _isInitialized = false;
    _logger.i('GemmaIsolateService: Disposed');
  }

  /// Worker function running in the background isolate.
  ///
  /// Loads the Gemma model once, then listens for inference requests.
  static void _gemmaWorker(SendPort mainSendPort) async {
    final port = ReceivePort();
    mainSendPort.send(port.sendPort);

    // TODO: Load actual Gemma model when flutter_gemma is available
    // final gemma = await GemmaModel.load(
    //   'assets/gemma-4-E2B-it-litertlm-Q4_K_M.litertlm'
    // );

    await for (final msg in port) {
      final replyPort = msg['replyPort'] as SendPort;

      try {
        // TODO: Replace with actual Gemma inference
        // final result = await gemma.generate(
        //   prompt: msg['prompt'] + msg['input'],
        //   imageBase64: msg['image'],
        //   maxTokens: 512,
        // );
        // replyPort.send(result);

        // Stub: return empty JSON until model is wired
        replyPort.send('{"name": "stub", "arguments": {}}');
      } catch (e) {
        replyPort.send({'error': e.toString()});
      }
    }
  }
}
