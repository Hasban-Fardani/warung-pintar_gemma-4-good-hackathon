import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class AddItemUseCase {
  final CatalogRepository _repository;

  const AddItemUseCase(this._repository);

  Future<Result<String, String>> call({
    required String itemName,
    int defaultPriceSen = 0,
    int currentQty = 0,
    String? categoryId,
  }) =>
      _repository.addItem(
        itemName: itemName,
        defaultPriceSen: defaultPriceSen,
        currentQty: currentQty,
        categoryId: categoryId,
      );
}
