import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/constant/app_strings.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/stock_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:warung_pintar_cimahi/features/catalog/presentation/pages/add_item_page.dart';
import 'package:warung_pintar_cimahi/features/catalog/presentation/pages/category_management_page.dart';
import 'package:warung_pintar_cimahi/shared/widgets/app_top_bar.dart';

class CatalogListPage extends ConsumerStatefulWidget {
  const CatalogListPage({super.key});

  @override
  ConsumerState<CatalogListPage> createState() => _CatalogListPageState();
}

class _CatalogListPageState extends ConsumerState<CatalogListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(catalogProvider.notifier).loadCatalog());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/reports');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: AppStrings.appName),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Text(
                    state.error!,
                    style: GoogleFonts.inter(fontSize: 16, color: AppColors.error),
                  ),
                )
              : _buildContent(state),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: _navigateTo,
              height: 64,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'Riwayat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CatalogState state) {
    final filtered = _searchQuery.isEmpty
        ? state.items
        : state.items
              .where(
                (e) => e.itemName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(state),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildCategoryChips(state),
          const SizedBox(height: 16),
          _buildTable(filtered, state),
        ],
      ),
    );
  }

  Widget _buildStatsRow(CatalogState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Total Barang',
                '${state.totalItems} item',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                'Kategori Aktif',
                '${state.activeCategoryCount} kategori',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _statCard(
            'Barang Tanpa Stok',
            '${state.outOfStockCount} item',
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
              letterSpacing: 0.28,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 28 / 20,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari nama barang...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 24 / 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(CatalogState state) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryChip('Semua', state.selectedCategory == null, null, 'Semua'),
          ...state.categories.map((cat) {
            final id = cat['id'] as String;
            final name = cat['name'] as String;
            return _categoryChip(name, state.selectedCategory == id, id, name);
          }),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, bool isActive, String? categoryId, String categoryName) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          debugPrint('Kategori dipilih: $categoryName (id: $categoryId)');
          ref
              .read(catalogProvider.notifier)
              .loadCatalog(categoryId: categoryId);
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryFixed : AppColors.surface,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
              letterSpacing: 0.28,
              color: isActive
                  ? AppColors.onPrimaryFixed
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<StockEntity> items, CatalogState state) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 56,
            headingRowColor: WidgetStateProperty.all(
              AppColors.surfaceContainerLow,
            ),
            border: const TableBorder(
              horizontalInside: BorderSide(
                color: AppColors.outlineVariant,
                width: 0.5,
              ),
            ),
            columnSpacing: 24,
            columns: [
              DataColumn(
                label: Text(
                  'Nama Barang',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 18 / 14,
                    letterSpacing: 0.28,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Kategori',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 18 / 14,
                    letterSpacing: 0.28,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Satuan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 18 / 14,
                    letterSpacing: 0.28,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Harga',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 18 / 14,
                    letterSpacing: 0.28,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 18 / 14,
                    letterSpacing: 0.28,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            rows: items.map((item) {
              final categoryName =
                  state.categories
                      .where((c) => c['id'] == item.categoryId)
                      .map((c) => c['name'] as String)
                      .firstOrNull ??
                  '-';
              return DataRow(
                color: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered)
                      ? AppColors.surfaceContainerLowest
                      : null,
                ),
                cells: [
                  DataCell(
                    Text(
                      item.itemName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 20 / 16,
                        letterSpacing: 0.16,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      categoryName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 24 / 16,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '-',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 24 / 16,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      NumberFormat.decimalPattern(
                        'id',
                      ).format(item.defaultPriceSen ~/ 100),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 24 / 16,
                        color: AppColors.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  DataCell(_statusBadge(item)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(StockEntity item) {
    final isActive = !item.isOutOfStock && !item.isLowStock;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.secondaryContainer
            : AppColors.errorContainer,
        border: Border.all(
          color: isActive ? AppColors.secondaryFixedDim : AppColors.error,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        isActive ? 'Aktif' : (item.isOutOfStock ? 'Habis' : 'Menipis'),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 18 / 14,
          letterSpacing: 0.28,
          color: isActive
              ? AppColors.onSecondaryContainer
              : AppColors.onErrorContainer,
        ),
      ),
    );
  }


}
