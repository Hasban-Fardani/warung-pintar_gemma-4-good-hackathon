import 'package:logger/logger.dart';
import 'package:warung_pintar_cimahi/core/database/database_service.dart';
import 'package:warung_pintar_cimahi/core/utils/uuid_helper.dart';
import 'package:warung_pintar_cimahi/features/catalog/data/models/stock_model.dart';

class CatalogDatasource {
  final DatabaseService _db;

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  const CatalogDatasource(this._db);

  Future<List<StockModel>> getAll({String? categoryId}) async {
    final where = <String>['is_deleted = ?'];
    final args = <dynamic>[0];
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    final rows = await _db.db.query(
      'stock',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'item_name ASC',
    );
    return rows.map((r) => StockModel.fromMap(r)).toList();
  }

  Future<String> insert({
    required String itemName,
    int defaultPriceSen = 0,
    int currentQty = 0,
    String? categoryId,
  }) async {
    final id = UuidHelper.generateId();
    await _db.db.insert('stock', {
      'id': id,
      'item_name': itemName,
      'default_price_sen': defaultPriceSen,
      'current_qty': currentQty,
      'category_id': categoryId,
    });
    _logger.d('CatalogDatasource: Inserted item=$id name=$itemName');
    return id;
  }

  Future<void> insertPriceHistory({
    required String stockId,
    required int priceSen,
    String? reason,
  }) async {
    final id = UuidHelper.generateId();
    await _db.db.insert('price_history', {
      'id': id,
      'stock_id': stockId,
      'price_sen': priceSen,
      'reason': reason,
    });
  }

  Future<void> updateDefaultPrice({
    required String stockId,
    required int newPriceSen,
  }) async {
    await _db.db.update(
      'stock',
      {
        'default_price_sen': newPriceSen,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [stockId],
    );
  }

  Future<void> softDelete(String stockId) async {
    await _db.db.update(
      'stock',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [stockId],
    );
  }

  Future<StockModel?> getById(String id) async {
    final rows = await _db.db.query(
      'stock',
      where: 'id = ? AND is_deleted = ?',
      whereArgs: [id, 0],
    );
    if (rows.isEmpty) return null;
    return StockModel.fromMap(rows.first);
  }

  Future<List<StockModel>> getLowStock() async {
    final rows = await _db.db.rawQuery('''
      SELECT * FROM stock
      WHERE is_deleted = 0
        AND current_qty <= low_stock_threshold
      ORDER BY current_qty ASC
    ''');
    return rows.map((r) => StockModel.fromMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    return _db.db.query('categories', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getCategories({String? parentId}) async {
    if (parentId != null) {
      return _db.db.query(
        'categories',
        where: 'parent_id = ?',
        whereArgs: [parentId],
        orderBy: 'name ASC',
      );
    }
    return _db.db.query(
      'categories',
      where: 'parent_id IS NULL',
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>> getCategoryById(String id) async {
    final rows = await _db.db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.first;
  }

  Future<String> insertCategory(String name, {String? parentId}) async {
    final id = UuidHelper.generateId();
    await _db.db.insert('categories', {
      'id': id,
      'name': name,
      'parent_id': parentId,
    });
    return id;
  }

  Future<void> updateCategory(String id, String name, {String? parentId}) async {
    await _db.db.update(
      'categories',
      {
        'name': name,
        'parent_id': parentId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCategory(String id) async {
    await _db.db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getItemCountByCategory(String categoryId) async {
    final result = await _db.db.rawQuery(
      'SELECT COUNT(*) as count FROM stock WHERE category_id = ? AND is_deleted = 0',
      [categoryId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getSubCategoryCount(String categoryId) async {
    final result = await _db.db.rawQuery(
      'SELECT COUNT(*) as count FROM categories WHERE parent_id = ?',
      [categoryId],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
