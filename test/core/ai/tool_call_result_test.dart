import 'package:flutter_test/flutter_test.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';

void main() {
  group('ToolCallResult', () {
    group('ToolCallSuccess', () {
      test('stores name and arguments correctly', () {
        const result = ToolCallSuccess(
          name: 'record_transactions',
          arguments: {
            'transactions': [
              {'item_name': 'Beras', 'quantity': 3},
            ],
          },
        );

        expect(result.name, 'record_transactions');
        expect(result.arguments, isA<Map<String, dynamic>>());
        expect(result.arguments['transactions'], isA<List>());
      });

      test('toString includes name and arguments', () {
        const result = ToolCallSuccess(
          name: 'test',
          arguments: {'key': 'value'},
        );

        expect(result.toString(), contains('test'));
        expect(result.toString(), contains('key'));
      });
    });

    group('ToolCallFallback', () {
      test('stores reason correctly', () {
        const result = ToolCallFallback(reason: 'Missing name field');

        expect(result.reason, 'Missing name field');
      });

      test('toString includes reason', () {
        const result = ToolCallFallback(reason: 'parse error');

        expect(result.toString(), contains('parse error'));
      });
    });

    group('exhaustive pattern matching', () {
      test('switch covers all cases', () {
        const ToolCallResult success = ToolCallSuccess(
          name: 'test',
          arguments: {},
        );
        const ToolCallResult fallback = ToolCallFallback(reason: 'error');

        // Exhaustive switch — compile error if case missing
        final successMessage = switch (success) {
          ToolCallSuccess(:final name) => 'Success: $name',
          ToolCallFallback(:final reason) => 'Fallback: $reason',
        };
        expect(successMessage, 'Success: test');

        final fallbackMessage = switch (fallback) {
          ToolCallSuccess(:final name) => 'Success: $name',
          ToolCallFallback(:final reason) => 'Fallback: $reason',
        };
        expect(fallbackMessage, 'Fallback: error');
      });
    });
  });
}
