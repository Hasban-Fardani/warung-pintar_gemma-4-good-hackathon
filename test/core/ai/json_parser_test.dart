import 'package:flutter_test/flutter_test.dart';
import 'package:warung_pintar_cimahi/core/ai/json_parser.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';

void main() {
  group('JsonParser.stripJsonFences', () {
    test('extracts JSON from markdown code fences', () {
      const raw = '```json\n{"name": "test", "arguments": {}}\n```';
      final result = JsonParser.stripJsonFences(raw);
      expect(result, '{"name":"test","arguments":{}}');
    });

    test('extracts JSON from fences without language tag', () {
      const raw = '```\n{"name": "test", "arguments": {}}\n```';
      final result = JsonParser.stripJsonFences(raw);
      expect(result, '{"name":"test","arguments":{}}');
    });

    test('extracts JSON from plain text with surrounding content', () {
      const raw =
          'Here is the result:\n{"name": "test", "arguments": {}}\nDone.';
      final result = JsonParser.stripJsonFences(raw);
      expect(result, '{"name":"test","arguments":{}}');
    });

    test('extracts JSON when no fences present', () {
      const raw = '{"name": "test", "arguments": {"key": "value"}}';
      final result = JsonParser.stripJsonFences(raw);
      expect(result, '{"name":"test","arguments":{"key":"value"}}');
    });

    test('throws FormatException on empty input', () {
      expect(
        () => JsonParser.stripJsonFences(''),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on whitespace-only input', () {
      expect(
        () => JsonParser.stripJsonFences('   \n\t  '),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when no JSON object found', () {
      expect(
        () => JsonParser.stripJsonFences('This has no JSON at all'),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles nested JSON objects', () {
      const raw = '''
```json
{
  "name": "record_transactions",
  "arguments": {
    "transactions": [
      {"item_name": "Beras", "quantity": 3}
    ]
  }
}
```''';
      final result = JsonParser.stripJsonFences(raw);
      // Should parse and re-serialize without error
      expect(result, contains('"name":"record_transactions"'));
      expect(result, contains('"transactions"'));
    });
  });

  group('JsonParser.parseToolCall', () {
    test('returns ToolCallSuccess for valid tool call JSON', () {
      const raw = '''
{"name": "record_transactions", "arguments": {"transactions": []}}
''';
      final result = JsonParser.parseToolCall(raw);

      expect(result, isA<ToolCallSuccess>());
      final success = result as ToolCallSuccess;
      expect(success.name, 'record_transactions');
      expect(success.arguments, containsPair('transactions', []));
    });

    test('returns ToolCallSuccess from markdown-fenced JSON', () {
      const raw = '''
```json
{"name": "setup_business", "arguments": {"categories": ["Sembako"]}}
```
''';
      final result = JsonParser.parseToolCall(raw);

      expect(result, isA<ToolCallSuccess>());
      final success = result as ToolCallSuccess;
      expect(success.name, 'setup_business');
      expect(
        success.arguments,
        containsPair('categories', ['Sembako']),
      );
    });

    test('returns ToolCallFallback when name field is missing', () {
      const raw = '{"arguments": {"key": "value"}}';
      final result = JsonParser.parseToolCall(raw);

      expect(result, isA<ToolCallFallback>());
      final fallback = result as ToolCallFallback;
      expect(fallback.reason, contains('name'));
    });

    test('returns ToolCallFallback when arguments field is missing', () {
      const raw = '{"name": "test"}';
      final result = JsonParser.parseToolCall(raw);

      expect(result, isA<ToolCallFallback>());
      final fallback = result as ToolCallFallback;
      expect(fallback.reason, contains('arguments'));
    });

    test('returns ToolCallFallback on empty input', () {
      final result = JsonParser.parseToolCall('');

      expect(result, isA<ToolCallFallback>());
      final fallback = result as ToolCallFallback;
      expect(fallback.reason, contains('Empty'));
    });

    test('returns ToolCallFallback on non-JSON input', () {
      final result = JsonParser.parseToolCall('not json at all');

      expect(result, isA<ToolCallFallback>());
    });

    test('handles complex multi-item transaction JSON', () {
      const raw = '''
```json
{
  "name": "record_transactions",
  "arguments": {
    "transactions": [
      {
        "item_name": "Beras",
        "quantity": 3,
        "total_price_sen": 4500000,
        "transaction_type": "sell",
        "needs_clarification": false
      },
      {
        "item_name": "Kopi",
        "quantity": 2,
        "total_price_sen": 300000,
        "transaction_type": "sell",
        "needs_clarification": false
      }
    ]
  }
}
```
''';
      final result = JsonParser.parseToolCall(raw);

      expect(result, isA<ToolCallSuccess>());
      final success = result as ToolCallSuccess;
      expect(success.name, 'record_transactions');

      final transactions =
          success.arguments['transactions'] as List<dynamic>;
      expect(transactions, hasLength(2));
      expect(transactions[0]['item_name'], 'Beras');
      expect(transactions[1]['item_name'], 'Kopi');
    });

    test('handles clarify tool call', () {
      const raw = '{"name": "clarify", "arguments": {"question": "Harga berapa?"}}';
      final result = JsonParser.parseToolCall(raw);

      expect(result, isA<ToolCallSuccess>());
      final success = result as ToolCallSuccess;
      expect(success.name, 'clarify');
      expect(success.arguments['question'], 'Harga berapa?');
    });

    test('handles parse_product_from_image tool call', () {
      const raw = '''
{
  "name": "parse_product_from_image",
  "arguments": {
    "product_name": "Tepung Terigu Segitiga Biru 1 kg",
    "estimated_category": "Sembako",
    "size_or_weight": "1 kg"
  }
}
''';
      final result = JsonParser.parseToolCall(raw);

      expect(result, isA<ToolCallSuccess>());
      final success = result as ToolCallSuccess;
      expect(success.name, 'parse_product_from_image');
      expect(
        success.arguments['product_name'],
        'Tepung Terigu Segitiga Biru 1 kg',
      );
    });
  });
}
