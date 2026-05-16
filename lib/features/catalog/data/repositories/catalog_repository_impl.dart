import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/data/datasources/catalog_datasource.dart';
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
}
