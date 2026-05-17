import 'dart:typed_data';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GemmaService {
  InferenceModel? _model;

  Future<void> initialize(InferenceModel model) async {
    _model = model;
  }

  bool get isInitialized => _model != null;

  Future<String> infer(String prompt) async {
    if (_model == null) {
      throw StateError('GemmaService not initialized');
    }
    final session = await _model!.createSession();
    await session.addQueryChunk(Message.text(text: prompt));
    final buffer = StringBuffer();
    await for (final chunk in session.getResponseAsync()) {
      buffer.write(chunk);
    }
    await session.close();
    return buffer.toString();
  }

  Future<String> inferWithImage(String prompt, Uint8List imageBytes) async {
    if (_model == null) {
      throw StateError('GemmaService not initialized');
    }
    final session = await _model!.createSession(
      enableVisionModality: true,
    );
    await session.addQueryChunk(Message.withImage(
      text: prompt,
      imageBytes: imageBytes,
    ));
    final buffer = StringBuffer();
    await for (final chunk in session.getResponseAsync()) {
      buffer.write(chunk);
    }
    await session.close();
    return buffer.toString();
  }
}
