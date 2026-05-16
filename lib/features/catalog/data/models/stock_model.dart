import 'package:warung_pintar_cimahi/features/catalog/domain/entities/stock_entity.dart';

class StockModel {
  final String id;
  final String itemName;
  final int currentQty;
  final int defaultPriceSen;
  final int lowStockThreshold;
  final String? categoryId;
  final int isDeleted;
  final String lastUpdated;

  const StockModel({
    required this.id,
    required this.itemName,
    this.currentQty = 0,
    this.defaultPriceSen = 0,
    this.lowStockThreshold = 5,
    this.categoryId,
    this.isDeleted = 0,
    required this.lastUpdated,
  });

  factory StockModel.fromMap(Map<String, dynamic> map) {
    return StockModel(
      id: map['id'] as String,
      itemName: map['item_name'] as String,
      currentQty: (map['current_qty'] as int?) ?? 0,
      defaultPriceSen: (map['default_price_sen'] as int?) ?? 0,
      lowStockThreshold: (map['low_stock_threshold'] as int?) ?? 5,
      categoryId: map['category_id'] as String?,
      isDeleted: (map['is_deleted'] as int?) ?? 0,
      lastUpdated: map['last_updated'] as String,
    );
  }

  StockEntity toEntity() {
    return StockEntity(
      id: id,
      itemName: itemName,
      currentQty: currentQty,
      defaultPriceSen: defaultPriceSen,
      lowStockThreshold: lowStockThreshold,
      categoryId: categoryId,
      isDeleted: isDeleted == 1,
      lastUpdated: DateTime.parse(lastUpdated),
    );
  }
}

class PriceHistoryModel {
  final String id;
  final String stockId;
  final int priceSen;
  final String? reason;
  final String effectiveFrom;

  const PriceHistoryModel({
    required this.id,
    required this.stockId,
    required this.priceSen,
    this.reason,
    required this.effectiveFrom,
  });

  factory PriceHistoryModel.fromMap(Map<String, dynamic> map) {
    return PriceHistoryModel(
      id: map['id'] as String,
      stockId: map['stock_id'] as String,
      priceSen: map['price_sen'] as int,
      reason: map['reason'] as String?,
      effectiveFrom: map['effective_from'] as String,
    );
  }

  PriceHistoryEntity toEntity() {
    return PriceHistoryEntity(
      id: id,
      stockId: stockId,
      priceSen: priceSen,
      reason: reason,
      effectiveFrom: DateTime.parse(effectiveFrom),
    );
  }
}
