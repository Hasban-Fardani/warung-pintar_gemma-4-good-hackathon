import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/fallback/level1_json_repair.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';

class MockAiService extends Mock implements AiService {}

void main() {
  late MockAiService mockAiService;

  setUp(() {
    mockAiService = MockAiService();
  });

  group('Level1JsonRepair.attempt', () {
    test('succeeds when fence stripping produces valid JSON', () async {
      const malformed = '```json\n'
          '{"name": "record_transactions", "arguments": {"qty": 1}}\n'
          '```';

      final result = await Level1JsonRepair.attempt(
        aiService: mockAiService,
        systemPrompt: 'test prompt',
        userInput: 'test input',
        rawMalformedOutput: malformed,
      );

      expect(result, isA<Success>());
      final success = result as Success;
      final toolCall = success.data as ToolCallSuccess;
      expect(toolCall.name, 'record_transactions');

      // AiService should NOT be called — strip was enough
      verifyNever(() => mockAiService.infer(
            systemPrompt: any(named: 'systemPrompt'),
            userInput: any(named: 'userInput'),
            imageBase64: any(named: 'imageBase64'),
          ));
    });

    test('retries inference when strip fails', () async {
      const totallyBroken = 'Sure! Here is the result: not json at all';

      when(() => mockAiService.infer(
            systemPrompt: any(named: 'systemPrompt'),
            userInput: any(named: 'userInput'),
            imageBase64: any(named: 'imageBase64'),
          )).thenAnswer(
        (_) async => const Success(
          ToolCallSuccess(
            name: 'record_transactions',
            arguments: {'fixed': true},
          ),
        ),
      );

      final result = await Level1JsonRepair.attempt(
        aiService: mockAiService,
        systemPrompt: 'test prompt',
        userInput: 'test input',
        rawMalformedOutput: totallyBroken,
      );

      expect(result, isA<Success>());
      // Verify inference was retried with reinforcement prompt
      verify(() => mockAiService.infer(
            systemPrompt: any(named: 'systemPrompt'),
            userInput: any(named: 'userInput'),
            imageBase64: any(named: 'imageBase64'),
          )).called(1);
    });

    test('handles JSON with trailing text after valid object', () async {
      const withTrailing =
          '{"name": "setup_business", "arguments": {"name": "Warung"}}'
          '\nHere is the setup configuration above.';

      final result = await Level1JsonRepair.attempt(
        aiService: mockAiService,
        systemPrompt: 'test',
        userInput: 'test',
        rawMalformedOutput: withTrailing,
      );

      expect(result, isA<Success>());
      final toolCall = (result as Success).data as ToolCallSuccess;
      expect(toolCall.name, 'setup_business');
    });
  });
}
