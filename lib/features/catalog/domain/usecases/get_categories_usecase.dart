import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/category_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class GetCategoriesUseCase {
  final CatalogRepository _repository;

  const GetCategoriesUseCase(this._repository);

  Future<Result<List<CategoryEntity>, String>> call({String? parentId}) =>
      _repository.getCategories(parentId: parentId);
}
