import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class UpdateCategoryUseCase {
  final CatalogRepository _repository;

  const UpdateCategoryUseCase(this._repository);

  Future<Result<void, String>> call({
    required String id,
    required String name,
    String? parentId,
  }) =>
      _repository.updateCategory(id: id, name: name, parentId: parentId);
}
