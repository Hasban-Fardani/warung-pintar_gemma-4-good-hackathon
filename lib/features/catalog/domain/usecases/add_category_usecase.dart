import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/category_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class AddCategoryUseCase {
  final CatalogRepository _repository;

  const AddCategoryUseCase(this._repository);

  Future<Result<CategoryEntity, String>> call({
    required String name,
    String? parentId,
  }) =>
      _repository.addCategory(name: name, parentId: parentId);
}
