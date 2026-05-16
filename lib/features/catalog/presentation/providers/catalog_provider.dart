import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/data/datasources/catalog_datasource.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/stock_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class CatalogState {
  final List<StockEntity> items;
  final List<StockEntity> lowStockItems;
  final String? selectedCategory;
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> categories;

  const CatalogState({
    this.items = const [],
    this.lowStockItems = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.error,
    this.categories = const [],
  });

  int get totalItems => items.length;
  int get activeCategoryCount {
    final ids = <String>{};
    for (final item in items) {
      if (item.categoryId != null) ids.add(item.categoryId!);
    }
    return ids.length;
  }

  int get outOfStockCount => items.where((e) => e.isOutOfStock).length;

  CatalogState copyWith({
    List<StockEntity>? items,
    List<StockEntity>? lowStockItems,
    String? selectedCategory,
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? categories,
    bool clearError = false,
  }) {
    return CatalogState(
      items: items ?? this.items,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      categories: categories ?? this.categories,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final CatalogRepository _repository;
  final CatalogDatasource _datasource;

  CatalogNotifier(this._repository, this._datasource) : super(const CatalogState());

  static final _getIt = GetIt.instance;

  static CatalogNotifier create() {
    return CatalogNotifier(
      _getIt<CatalogRepository>(),
      _getIt<CatalogDatasource>(),
    );
  }

  Future<void> loadCatalog({String? categoryId}) async {
    state = state.copyWith(isLoading: true, selectedCategory: categoryId, clearError: true);

    final catalogResult = await _repository.getCatalog(categoryId: categoryId);
    final lowStockResult = await _repository.getLowStockItems();
    final categories = await _datasource.getCategories();

    switch (catalogResult) {
      case Success(:final data):
        final lowStockItems = switch (lowStockResult) {
          Success(:final data) => data,
          Failure() => <StockEntity>[],
        };
        state = state.copyWith(
          items: data,
          lowStockItems: lowStockItems,
          categories: categories,
          isLoading: false,
        );
      case Failure(:final error):
        state = state.copyWith(error: error, isLoading: false);
    }
  }

  Future<String?> addItem({
    required String name,
    required int price,
    String? categoryId,
    int qty = 0,
  }) async {
    final result = await _repository.addItem(
      itemName: name,
      defaultPriceSen: price,
      currentQty: qty,
      categoryId: categoryId,
    );
    return switch (result) {
      Success() => null,
      Failure(:final error) => error,
    };
  }

  Future<String?> updatePrice(String stockId, int newPriceSen, {String? reason}) async {
    final result = await _repository.updateItemPrice(
      stockId: stockId,
      newPriceSen: newPriceSen,
      reason: reason,
    );
    return switch (result) {
      Success() => null,
      Failure(:final error) => error,
    };
  }

  Future<String?> deleteItem(String stockId) async {
    final result = await _repository.softDeleteItem(stockId);
    return switch (result) {
      Success() => null,
      Failure(:final error) => error,
    };
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>(
  (ref) => CatalogNotifier.create(),
);
