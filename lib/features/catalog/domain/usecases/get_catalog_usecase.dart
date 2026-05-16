import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/stock_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class GetCatalogUseCase {
  final CatalogRepository _repository;

  const GetCatalogUseCase(this._repository);

  Future<Result<List<StockEntity>, String>> call({String? categoryId}) =>
      _repository.getCatalog(categoryId: categoryId);
}
