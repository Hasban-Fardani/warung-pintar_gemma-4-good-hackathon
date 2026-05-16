import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class SoftDeleteItemUseCase {
  final CatalogRepository _repository;

  const SoftDeleteItemUseCase(this._repository);

  Future<Result<void, String>> call(String stockId) =>
      _repository.softDeleteItem(stockId);
}
