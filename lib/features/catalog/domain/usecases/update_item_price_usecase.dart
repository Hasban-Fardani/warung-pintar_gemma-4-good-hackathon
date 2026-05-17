import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class UpdateItemPriceUseCase {
  final CatalogRepository _repository;

  const UpdateItemPriceUseCase(this._repository);

  Future<Result<void, String>> call({
    required String stockId,
    required int newPriceSen,
    String? reason,
  }) => _repository.updateItemPrice(
    stockId: stockId,
    newPriceSen: newPriceSen,
    reason: reason,
  );
}
