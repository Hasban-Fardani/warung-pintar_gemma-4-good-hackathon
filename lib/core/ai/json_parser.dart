import 'dart:convert';

import 'tool_call_result.dart';

/// Robust JSON parser for AI output (PRD §10.5).
///
/// Handles malformed outputs including:
/// - Markdown code fences (```json ... ```)
/// - Leading/trailing text around JSON
/// - Missing required fields (name, arguments)
///
/// Pure Dart — zero Flutter imports.
class JsonParser {
  JsonParser._();

  /// Strip markdown JSON fences and extract the first valid JSON object.
  ///
  /// Handles:
  /// - ```json\n{...}\n```
  /// - ```\n{...}\n```
  /// - Text before/after JSON
  ///
  /// Throws [FormatException] if no JSON object is found.
  static String stripJsonFences(String raw) {
    if (raw.trim().isEmpty) {
      throw const FormatException('Empty input — no JSON found');
    }

    // Remove markdown code fences
    var clean = raw.replaceAll(RegExp(r'```json\s*'), '');
    clean = clean.replaceAll(RegExp(r'```\s*'), '');

    // Extract first JSON object
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
    if (jsonMatch == null) {
      throw const FormatException('No JSON object found in output');
    }

    // Validate it's parseable JSON
    final extracted = jsonMatch.group(0)!;
    final parsed = jsonDecode(extracted);
    return jsonEncode(parsed);
  }

  /// Parse raw AI output into a [ToolCallResult].
  ///
  /// Returns [ToolCallSuccess] if the output contains valid JSON
  /// with `name` and `arguments` keys per Appendix A schema.
  ///
  /// Returns [ToolCallFallback] if parsing fails for any reason.
  static ToolCallResult parseToolCall(String raw) {
    try {
      final clean = stripJsonFences(raw);
      final map = jsonDecode(clean) as Map<String, dynamic>;

      if (!map.containsKey('name')) {
        return const ToolCallFallback(reason: 'Missing required field: name');
      }
      if (!map.containsKey('arguments')) {
        return const ToolCallFallback(
          reason: 'Missing required field: arguments',
        );
      }

      final name = map['name'] as String;
      final arguments = map['arguments'] as Map<String, dynamic>;

      return ToolCallSuccess(name: name, arguments: arguments);
    } on FormatException catch (e) {
      return ToolCallFallback(reason: e.message);
    } on TypeError catch (e) {
      return ToolCallFallback(reason: 'Type error parsing JSON: $e');
    }
  }
}
