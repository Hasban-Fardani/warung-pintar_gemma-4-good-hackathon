import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/inference_retry.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';

class MockAiService extends Mock implements AiService {}

void main() {
  late MockAiService mockAiService;

  setUp(() {
    mockAiService = MockAiService();
  });

  group('InferenceRetry.runWithRetry', () {
    test('returns Success on first attempt if inference succeeds', () async {
      when(
        () => mockAiService.infer(
          systemPrompt: any(named: 'systemPrompt'),
          userInput: any(named: 'userInput'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenAnswer(
        (_) async => const Success(
          ToolCallSuccess(
            name: 'record_transactions',
            arguments: {'test': true},
          ),
        ),
      );

      final result = await InferenceRetry.runWithRetry(
        aiService: mockAiService,
        systemPrompt: 'test',
        userInput: 'jual beras 3 kilo',
      );

      expect(result, isA<Success>());
      verify(
        () => mockAiService.infer(
          systemPrompt: any(named: 'systemPrompt'),
          userInput: any(named: 'userInput'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).called(1); // Only 1 call, no retry
    });

    test('retries up to 2 times on ModelNotLoadedFailure', () async {
      when(
        () => mockAiService.infer(
          systemPrompt: any(named: 'systemPrompt'),
          userInput: any(named: 'userInput'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenAnswer((_) async => const Failure(ModelNotLoadedFailure()));

      final result = await InferenceRetry.runWithRetry(
        aiService: mockAiService,
        systemPrompt: 'test',
        userInput: 'test input',
      );

      expect(result, isA<Failure>());
      verify(
        () => mockAiService.infer(
          systemPrompt: any(named: 'systemPrompt'),
          userInput: any(named: 'userInput'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).called(3); // 1 initial + 2 retries
    });

    test('does NOT retry on InvalidJsonOutputFailure', () async {
      when(
        () => mockAiService.infer(
          systemPrompt: any(named: 'systemPrompt'),
          userInput: any(named: 'userInput'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenAnswer(
        (_) async => const Failure(InvalidJsonOutputFailure('bad json')),
      );

      final result = await InferenceRetry.runWithRetry(
        aiService: mockAiService,
        systemPrompt: 'test',
        userInput: 'test input',
      );

      expect(result, isA<Failure>());
      final failure = (result as Failure).error;
      expect(failure, isA<InvalidJsonOutputFailure>());
      verify(
        () => mockAiService.infer(
          systemPrompt: any(named: 'systemPrompt'),
          userInput: any(named: 'userInput'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).called(1); // No retry for JSON failures
    });

    test('returns Success if second attempt succeeds', () async {
      var callCount = 0;
      when(
        () => mockAiService.infer(
          systemPrompt: any(named: 'systemPrompt'),
          userInput: any(named: 'userInput'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return const Failure(ModelNotLoadedFailure());
        }
        return const Success(ToolCallSuccess(name: 'test', arguments: {}));
      });

      final result = await InferenceRetry.runWithRetry(
        aiService: mockAiService,
        systemPrompt: 'test',
        userInput: 'test input',
      );

      expect(result, isA<Success>());
      expect(callCount, 2); // 1 fail + 1 success
    });
  });
}
