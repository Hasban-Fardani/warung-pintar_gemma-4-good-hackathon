import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/category_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/stock_entity.dart';

abstract class CatalogRepository {
  Future<Result<List<StockEntity>, String>> getCatalog({String? categoryId});

  Future<Result<String, String>> addItem({
    required String itemName,
    int defaultPriceSen = 0,
    int currentQty = 0,
    String? categoryId,
    String? rawInputSource,
    String? aiRawOutput,
  });

  Future<Result<void, String>> updateItemPrice({
    required String stockId,
    required int newPriceSen,
    String? reason,
  });

  Future<Result<void, String>> softDeleteItem(String stockId);

  Future<Result<List<StockEntity>, String>> getLowStockItems();

  Future<Result<StockEntity?, String>> getItemById(String id);

  Future<Result<List<CategoryEntity>, String>> getCategories({String? parentId});

  Future<Result<CategoryEntity, String>> addCategory({
    required String name,
    String? parentId,
  });

  Future<Result<void, String>> updateCategory({
    required String id,
    required String name,
    String? parentId,
  });

  Future<Result<void, String>> deleteCategory(String id);
}
