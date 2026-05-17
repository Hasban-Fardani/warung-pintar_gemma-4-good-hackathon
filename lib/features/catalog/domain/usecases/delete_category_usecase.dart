import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class DeleteCategoryUseCase {
  final CatalogRepository _repository;

  const DeleteCategoryUseCase(this._repository);

  Future<Result<void, String>> call(String id) =>
      _repository.deleteCategory(id);
}
