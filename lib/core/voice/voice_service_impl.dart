import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:warung_pintar_cimahi/core/voice/voice_config.dart';
import 'package:warung_pintar_cimahi/core/voice/voice_init_result.dart';

/// Abstract voice service interface for testability.
abstract class VoiceService {
  Future<VoiceInitResult> initialize();
  Future<void> startListening({required Function(String) onResult});
  Future<void> stopListening();
  bool get isListening;
}

/// Production STT implementation using Android SpeechRecognizer (PRD §16.4.1).
///
/// On-device — no network call during recognition.
/// Requires id-ID language pack installed on device.
class VoiceServiceImpl implements VoiceService {
  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  @override
  bool get isListening => _stt.isListening;

  @override
  Future<VoiceInitResult> initialize() async {
    // Request microphone permission first
    final micStatus = await Permission.microphone.request();
    debugPrint('VoiceService: Microphone permission status: $micStatus');
    if (!micStatus.isGranted) {
      _logger.w('VoiceService: Microphone permission denied');
      return const VoiceInitFailed('Izin mikrofon ditolak');
    }

    _isInitialized = await _stt.initialize(
      onStatus: (status) {
        debugPrint('STT Status: $status');
        _onStatus(status);
      },
      onError: (error) {
        debugPrint('STT Error: $error');
        _onError(error);
      },
    );

    if (!_isInitialized) {
      _logger.e('VoiceService: STT engine not available');
      debugPrint('STT FAILED TO INITIALIZE');
      return const VoiceInitFailed('STT engine tidak tersedia di device ini');
    }

    // Check id-ID locale availability
    final locales = await _stt.locales();
    final hasIndonesian = locales.any(
      (locale) => locale.localeId.startsWith('id'),
    );

    if (!hasIndonesian) {
      _logger.w('VoiceService: id-ID language pack not installed');
      return const VoiceInitMissingPack();
    }

    _logger.i('VoiceService: Initialized with id-ID support');
    return const VoiceInitSuccess();
  }

  @override
  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isInitialized) {
      _logger.e('VoiceService: Not initialized');
      return;
    }

    await _stt.listen(
      localeId: VoiceConfig.localeId,
      listenFor: const Duration(milliseconds: VoiceConfig.maxListenDurationMs),
      pauseFor: const Duration(milliseconds: VoiceConfig.vadSilenceThresholdMs),
      onResult: (result) {
        if (result.finalResult &&
            result.confidence >= VoiceConfig.minConfidenceScore) {
          onResult(result.recognizedWords);
        }
      },
    );

    _logger.d('VoiceService: Listening started');
  }

  @override
  Future<void> stopListening() async {
    await _stt.stop();
    _logger.d('VoiceService: Listening stopped');
  }

  void _onStatus(String status) {
    _logger.d('VoiceService status: $status');
  }

  void _onError(dynamic error) {
    _logger.e('VoiceService error: $error');
  }
}
