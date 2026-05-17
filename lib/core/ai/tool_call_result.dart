/// Parsed AI tool call result (PRD §10.5).
///
/// Represents the outcome of parsing raw AI JSON output
/// into a structured tool call. Used by all 5 agents.
///
/// Pure Dart — zero Flutter imports.
sealed class ToolCallResult {
  const ToolCallResult();
}

/// Successfully parsed tool call with name and arguments.
///
/// Example:
/// ```json
/// {"name": "record_transactions", "arguments": {"transactions": [...]}}
/// ```
final class ToolCallSuccess extends ToolCallResult {
  /// Tool function name (e.g. "record_transactions", "setup_business").
  final String name;

  /// Parsed JSON arguments matching Appendix A schema.
  final Map<String, dynamic> arguments;

  const ToolCallSuccess({required this.name, required this.arguments});

  @override
  String toString() => 'ToolCallSuccess(name: $name, arguments: $arguments)';
}

/// Parsing failed — raw output could not be parsed into a valid tool call.
final class ToolCallFallback extends ToolCallResult {
  /// Human-readable reason for the parsing failure.
  final String reason;

  const ToolCallFallback({required this.reason});

  @override
  String toString() => 'ToolCallFallback(reason: $reason)';
}
