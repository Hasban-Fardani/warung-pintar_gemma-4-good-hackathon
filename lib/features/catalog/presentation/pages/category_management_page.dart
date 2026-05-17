import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/category_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/add_category_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/delete_category_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/get_categories_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/update_category_usecase.dart';

class CategoryManagementPage extends ConsumerStatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  ConsumerState<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends ConsumerState<CategoryManagementPage> {
  final _getCategoriesUseCase = getIt<GetCategoriesUseCase>();
  final _addCategoryUseCase = getIt<AddCategoryUseCase>();
  final _updateCategoryUseCase = getIt<UpdateCategoryUseCase>();
  final _deleteCategoryUseCase = getIt<DeleteCategoryUseCase>();

  List<CategoryEntity> _mainCategories = [];
  final Set<String> _expandedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final result = await _getCategoriesUseCase();
    result.when(
      success: (categories) => setState(() {
        _mainCategories = categories;
        _isLoading = false;
      }),
      failure: (error) => setState(() => _isLoading = false),
    );
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  Future<void> _showAddEditCategory({CategoryEntity? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final String? selectedParentId = existing?.parentId;

    final allCategories = await _getCategoriesUseCase();
    final mainCategories = allCategories.maybeWhen(
      success: (cats) => cats.where((c) => c.isMainCategory && c.id != existing?.id).toList(),
      orElse: () => <CategoryEntity>[],
    );

    if (!mounted) return;

    final formResult = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String? localParentId = selectedParentId;

        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Tambah Kategori' : 'Edit Kategori',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: localParentId,
                  decoration: InputDecoration(
                    labelText: 'Induk Kategori (opsional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tidak ada (kategori utama)')),
                    ...mainCategories.map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    )),
                  ],
                  onChanged: (v) => setSheetState(() => localParentId = v),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          Navigator.of(ctx).pop({
                            'name': nameController.text.trim(),
                            'parentId': localParentId,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (formResult != null && formResult['name'] != null) {
      final name = formResult['name'] as String;
      final parentId = formResult['parentId'] as String?;

      final saveResult = existing == null
          ? await _addCategoryUseCase.call(name: name, parentId: parentId)
          : await _updateCategoryUseCase.call(id: existing.id, name: name, parentId: parentId);

      saveResult.when(
        success: (_) => unawaited(_loadCategories()),
        failure: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: AppColors.error),
            );
          }
        },
      );
    }
  }

  Future<void> _deleteCategory(CategoryEntity category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _deleteCategoryUseCase(category.id);
      result.when(
        success: (_) => unawaited(_loadCategories()),
        failure: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: AppColors.error),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Kelola Kategori',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.outlineVariant, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showAddEditCategory(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mainCategories.isEmpty
          ? Center(
              child: Text(
                'Belum ada kategori',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _mainCategories.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.outlineVariant),
              itemBuilder: (context, index) {
                final cat = _mainCategories[index];
                final isExpanded = _expandedIds.contains(cat.id);
                return _buildCategoryTile(cat, isExpanded);
              },
            ),
    );
  }

  Widget _buildCategoryTile(CategoryEntity category, bool isExpanded) {
    return Column(
      children: [
        _CategoryTileRow(
          category: category,
          isExpanded: isExpanded,
          onExpand: () => _toggleExpand(category.id),
          onEdit: () => _showAddEditCategory(existing: category),
          onDelete: () => _deleteCategory(category),
        ),
        if (isExpanded)
          FutureBuilder<List<CategoryEntity>>(
            future: _getCategoriesUseCase(parentId: category.id).then((r) => r.maybeWhen(
              success: (cats) => cats,
              orElse: () => [],
            )),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
                  child: Text(
                    'Tidak ada sub-kategori',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return Column(
                children: snapshot.data!.map((sub) => _SubCategoryRow(
                  category: sub,
                  onEdit: () => _showAddEditCategory(existing: sub),
                  onDelete: () => _deleteCategory(sub),
                )).toList(),
              );
            },
          ),
      ],
    );
  }
}

class _CategoryTileRow extends StatelessWidget {
  final CategoryEntity category;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTileRow({
    required this.category,
    required this.isExpanded,
    required this.onExpand,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
            onPressed: onExpand,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Kategori utama',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SubCategoryRow extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubCategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 20, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
