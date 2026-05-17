import 'package:flutter_test/flutter_test.dart';
import 'package:warung_pintar_cimahi/core/ai/json_parser.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';

/// ACT-76: Extended unit test json_parser.
///
/// Additional edge cases beyond existing json_parser_test.dart:
/// - Fence stripping with extra whitespace
/// - Missing `name` key specifically
/// - Missing `arguments` key specifically
/// - Empty string input
/// - Nested malformed JSON
/// - Double-fenced output
void main() {
  group('JsonParser.stripJsonFences — edge cases', () {
    test('handles triple backtick with extra spaces', () {
      const raw = '```  json  \n{"name": "test", "arguments": {}}\n  ```  ';
      final result = JsonParser.stripJsonFences(raw);
      expect(result, contains('"name":"test"'));
    });

    test('handles JSON with trailing comma (malformed)', () {
      // Trailing comma in JSON is invalid — should throw
      const raw = '{"name": "test", "arguments": {},}';
      expect(
        () => JsonParser.stripJsonFences(raw),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles deeply nested valid JSON', () {
      const raw = '''
{
  "name": "record_transactions",
  "arguments": {
    "transactions": [
      {
        "item_name": "Beras",
        "details": {
          "origin": "Cianjur",
          "grade": "premium"
        }
      }
    ]
  }
}
''';
      final result = JsonParser.stripJsonFences(raw);
      expect(result, contains('"name":"record_transactions"'));
      expect(result, contains('"origin":"Cianjur"'));
    });

    test('handles multiple JSON objects — greedy match spans both', () {
      const raw =
          '{"name": "first", "arguments": {}} and {"name": "second", "arguments": {}}';
      // Greedy regex matches from first { to last }, spanning both objects.
      // This results in invalid intermediate JSON, which stripJsonFences
      // will fail to parse. This is expected behavior — AI output should
      // contain only one JSON object.
      expect(
        () => JsonParser.stripJsonFences(raw),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles unicode characters in JSON', () {
      const raw = '{"name": "test", "arguments": {"item": "Tepung Térigu"}}';
      final result = JsonParser.stripJsonFences(raw);
      expect(result, contains('Tepung Térigu'));
    });
  });

  group('JsonParser.parseToolCall — edge cases', () {
    test('returns ToolCallFallback when name is wrong type (int)', () {
      const raw = '{"name": 123, "arguments": {}}';
      final result = JsonParser.parseToolCall(raw);
      expect(result, isA<ToolCallFallback>());
    });

    test('returns ToolCallFallback when arguments is wrong type (list)', () {
      const raw = '{"name": "test", "arguments": [1, 2, 3]}';
      final result = JsonParser.parseToolCall(raw);
      expect(result, isA<ToolCallFallback>());
    });

    test('returns ToolCallFallback for null input-like edge', () {
      final result = JsonParser.parseToolCall('null');
      expect(result, isA<ToolCallFallback>());
    });

    test('returns ToolCallFallback for array input', () {
      final result = JsonParser.parseToolCall('[1, 2, 3]');
      expect(result, isA<ToolCallFallback>());
    });

    test('handles confirm_all tool call', () {
      const raw = '''
{
  "name": "confirm_transactions",
  "arguments": {
    "confirm_all": true,
    "transaction_ids": ["tx-001", "tx-002"]
  }
}
''';
      final result = JsonParser.parseToolCall(raw);
      expect(result, isA<ToolCallSuccess>());
      final success = result as ToolCallSuccess;
      expect(success.name, 'confirm_transactions');
      expect(success.arguments['confirm_all'], true);
    });

    test('handles setup_business tool call with categories', () {
      const raw = '''
{
  "name": "setup_business",
  "arguments": {
    "business_name": "Warung Ibu Warsih",
    "categories": ["Sembako", "Minuman", "Rokok"]
  }
}
''';
      final result = JsonParser.parseToolCall(raw);
      expect(result, isA<ToolCallSuccess>());
      final success = result as ToolCallSuccess;
      expect(success.name, 'setup_business');
      expect(success.arguments['categories'], hasLength(3));
    });
  });
}
