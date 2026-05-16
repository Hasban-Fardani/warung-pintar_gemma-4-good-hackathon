import 'dart:convert';

import 'package:logger/logger.dart';

import 'package:warung_pintar_cimahi/core/database/database_service.dart';
import 'package:warung_pintar_cimahi/core/utils/uuid_helper.dart';

/// Append-only datasource for audit logs (PRD §9).
///
/// Rules:
/// - Only INSERT is exposed — no UPDATE or DELETE methods.
/// - Every transaction action produces exactly one audit row.
/// - Raw AI output and STT transcript stored verbatim.
class AuditLogDatasource {
  final DatabaseService _db;

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  const AuditLogDatasource(this._db);

  /// Insert a new audit log entry.
  ///
  /// [transactionId] — FK to transactions table.
  /// [action] — one of the 9 action types from PRD §9.2.
  /// [stateSnapshot] — JSON dump of the transaction row at this point.
  /// [rawInputSource] — STT transcript or image file path (nullable).
  /// [aiRawOutput] — raw JSON string from Gemma before parsing (nullable).
  Future<void> insert({
    required String transactionId,
    required String action,
    required Map<String, dynamic> stateSnapshot,
    String? rawInputSource,
    String? aiRawOutput,
  }) async {
    final id = UuidHelper.generateId();
    final snapshotJson = jsonEncode(stateSnapshot);

    await _db.db.insert('audit_logs', {
      'id': id,
      'transaction_id': transactionId,
      'action': action,
      'raw_input_source': rawInputSource,
      'ai_raw_output': aiRawOutput,
      'state_snapshot': snapshotJson,
    });

    _logger.d('AuditLog: Inserted [$action] for tx=$transactionId');
  }

  /// Get all audit logs for a specific transaction, ordered by created_at.
  Future<List<Map<String, dynamic>>> getByTransactionId(
    String transactionId,
  ) async {
    return _db.db.query(
      'audit_logs',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'created_at ASC',
    );
  }

  /// Get the full audit trail, most recent first.
  /// [limit] caps the number of rows returned.
  Future<List<Map<String, dynamic>>> getRecent({int limit = 50}) async {
    return _db.db.query('audit_logs', orderBy: 'created_at DESC', limit: limit);
  }
}
