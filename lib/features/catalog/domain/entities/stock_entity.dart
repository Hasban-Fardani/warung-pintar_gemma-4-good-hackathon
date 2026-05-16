class StockEntity {
  final String id;
  final String itemName;
  final int currentQty;
  final int defaultPriceSen;
  final int lowStockThreshold;
  final String? categoryId;
  final bool isDeleted;
  final DateTime lastUpdated;

  const StockEntity({
    required this.id,
    required this.itemName,
    this.currentQty = 0,
    this.defaultPriceSen = 0,
    this.lowStockThreshold = 5,
    this.categoryId,
    this.isDeleted = false,
    required this.lastUpdated,
  });

  bool get isLowStock => currentQty <= lowStockThreshold && currentQty > 0;

  bool get isOutOfStock => currentQty == 0;
}

class PriceHistoryEntity {
  final String id;
  final String stockId;
  final int priceSen;
  final String? reason;
  final DateTime effectiveFrom;

  const PriceHistoryEntity({
    required this.id,
    required this.stockId,
    required this.priceSen,
    this.reason,
    required this.effectiveFrom,
  });
}
