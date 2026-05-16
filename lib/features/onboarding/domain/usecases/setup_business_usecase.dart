import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/inference_retry.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/failures.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/core/database/database_service.dart';
import 'package:warung_pintar_cimahi/core/utils/uuid_helper.dart';

class SetupBusinessUseCase {
  final AiService _aiService;
  final DatabaseService _db;

  const SetupBusinessUseCase(this._aiService, this._db);

  static const _systemPrompt = '''
Kamu adalah asisten setup WarungPintar. Analisa ucapan pengguna dan panggil fungsi setup.
Gunakan HANYA JSON valid sesuai skema. Jangan tambahkan teks lain selain JSON.
Jika tidak cukup informasi, output: {"name": "clarify", "arguments": {"question": "<pertanyaan>"}}

TOOLS:
- setup_business: Membuat kategori dan inventaris awal warung.
  Parameters: categories (string[]), items ({name, category, default_price_sen}[])
''';

  Future<Result<String, String>> call(String transcript) async {
    final result = await InferenceRetry.runWithRetry(
      aiService: _aiService,
      systemPrompt: _systemPrompt,
      userInput: transcript,
    );

    switch (result) {
      case Success(:final data):
        return _executeSetup(data);
      case Failure(:final error):
        if (error is InvalidJsonOutputFailure) {
          return Failure('Setup gagal: ${error.message}');
        }
        return Failure('AI tidak merespon: ${error.message}');
    }
  }

  Future<Result<String, String>> _executeSetup(ToolCallResult toolCall) async {
    if (toolCall is! ToolCallSuccess) {
      return const Failure('AI tidak mengenali perintah setup');
    }

    if (toolCall.name == 'clarify') {
      return Success('Klarifikasi: ${toolCall.arguments['question']}');
    }

    if (toolCall.name != 'setup_business') {
      return Failure('Perintah tidak dikenal: ${toolCall.name}');
    }

    final categories = toolCall.arguments['categories'];
    final items = toolCall.arguments['items'];

    if (categories is List) {
      for (final cat in categories) {
        await _db.db.insert('categories', {
          'id': UuidHelper.generateId(),
          'name': cat.toString(),
        });
      }
    }

    if (items is List) {
      for (final item in items) {
        if (item is! Map) continue;
        String? categoryId;
        if (item['category'] != null) {
          final rows = await _db.db.query(
            'categories',
            where: 'name = ?',
            whereArgs: [item['category'].toString()],
          );
          if (rows.isNotEmpty) categoryId = rows.first['id'] as String?;
        }

        await _db.db.insert('stock', {
          'id': UuidHelper.generateId(),
          'item_name': item['name'].toString(),
          'default_price_sen':
              (item['default_price_sen'] as num?)?.toInt() ?? 0,
          'category_id': categoryId,
        });
      }
    }

    final catCount = categories is List ? categories.length : 0;
    final itemCount = items is List ? items.length : 0;
    return Success('$catCount kategori dan $itemCount barang ditambahkan');
  }
}
