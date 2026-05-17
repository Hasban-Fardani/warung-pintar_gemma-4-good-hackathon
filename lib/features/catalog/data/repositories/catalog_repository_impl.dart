import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/data/datasources/catalog_datasource.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/category_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/stock_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogDatasource _datasource;

  const CatalogRepositoryImpl(this._datasource);

  @override
  Future<Result<List<StockEntity>, String>> getCatalog({
    String? categoryId,
  }) async {
    try {
      final models = await _datasource.getAll(categoryId: categoryId);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Failure('Gagal memuat katalog: $e');
    }
  }

  @override
  Future<Result<String, String>> addItem({
    required String itemName,
    int defaultPriceSen = 0,
    int currentQty = 0,
    String? categoryId,
    String? rawInputSource,
    String? aiRawOutput,
  }) async {
    try {
      final id = await _datasource.insert(
        itemName: itemName,
        defaultPriceSen: defaultPriceSen,
        currentQty: currentQty,
        categoryId: categoryId,
      );
      return Success(id);
    } catch (e) {
      return Failure('Gagal menambah barang: $e');
    }
  }

  @override
  Future<Result<void, String>> updateItemPrice({
    required String stockId,
    required int newPriceSen,
    String? reason,
  }) async {
    try {
      await _datasource.insertPriceHistory(
        stockId: stockId,
        priceSen: newPriceSen,
        reason: reason,
      );
      await _datasource.updateDefaultPrice(
        stockId: stockId,
        newPriceSen: newPriceSen,
      );
      return const Success(null);
    } catch (e) {
      return Failure('Gagal memperbarui harga: $e');
    }
  }

  @override
  Future<Result<void, String>> softDeleteItem(String stockId) async {
    try {
      await _datasource.softDelete(stockId);
      return const Success(null);
    } catch (e) {
      return Failure('Gagal menghapus barang: $e');
    }
  }

  @override
  Future<Result<List<StockEntity>, String>> getLowStockItems() async {
    try {
      final models = await _datasource.getLowStock();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Failure('Gagal memuat stok menipis: $e');
    }
  }

  @override
  Future<Result<StockEntity?, String>> getItemById(String id) async {
    try {
      final model = await _datasource.getById(id);
      return Success(model?.toEntity());
    } catch (e) {
      return Failure('Gagal memuat detail barang: $e');
    }
  }

  @override
  Future<Result<List<CategoryEntity>, String>> getCategories({String? parentId}) async {
    try {
      final models = await _datasource.getCategories(parentId: parentId);
      return Success(models.map((m) => CategoryEntity(
        id: m['id'] as String,
        name: m['name'] as String,
        parentId: m['parent_id'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      )).toList());
    } catch (e) {
      return Failure('Gagal memuat kategori: $e');
    }
  }

  @override
  Future<Result<CategoryEntity, String>> addCategory({
    required String name,
    String? parentId,
  }) async {
    try {
      final id = await _datasource.insertCategory(name, parentId: parentId);
      final row = await _datasource.getCategoryById(id);
      return Success(CategoryEntity(
        id: row['id'] as String,
        name: row['name'] as String,
        parentId: row['parent_id'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      ));
    } catch (e) {
      return Failure('Gagal menambah kategori: $e');
    }
  }

  @override
  Future<Result<void, String>> updateCategory({
    required String id,
    required String name,
    String? parentId,
  }) async {
    try {
      await _datasource.updateCategory(id, name, parentId: parentId);
      return const Success(null);
    } catch (e) {
      return Failure('Gagal memperbarui kategori: $e');
    }
  }

  @override
  Future<Result<void, String>> deleteCategory(String id) async {
    try {
      final itemCount = await _datasource.getItemCountByCategory(id);
      if (itemCount > 0) {
        return Failure('Kategori ini digunakan oleh $itemCount barang. Pindahkan dulu sebelum menghapus.');
      }
      final subCount = await _datasource.getSubCategoryCount(id);
      if (subCount > 0) {
        return const Failure('Hapus sub-kategori terlebih dahulu sebelum menghapus kategori ini.');
      }
      await _datasource.deleteCategory(id);
      return const Success(null);
    } catch (e) {
      return Failure('Gagal menghapus kategori: $e');
    }
  }
}
