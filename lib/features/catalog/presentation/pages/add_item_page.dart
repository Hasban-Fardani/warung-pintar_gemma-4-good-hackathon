import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/constant/app_strings.dart';
import 'package:warung_pintar_cimahi/features/catalog/presentation/providers/catalog_provider.dart';

class AddItemPage extends ConsumerStatefulWidget {
  final bool asBottomSheet;

  const AddItemPage({super.key, this.asBottomSheet = false});

  @override
  ConsumerState<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends ConsumerState<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _skuController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController(text: '0');

  String? _selectedCategoryId;
  String _selectedSatuan = 'pcs';

  final _satuanOptions = ['pcs', 'porsi', 'kg', 'liter', 'pack', 'pasang'];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(catalogProvider.notifier).loadCatalog());
  }

  @override
  void dispose() {
    _namaController.dispose();
    _skuController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  void _batalkan() {
    if (widget.asBottomSheet) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final nama = _namaController.text.trim();
    final hargaText = _hargaController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '');
    final harga = int.tryParse(hargaText) ?? 0;
    final hargaSen = harga * 100;
    final stokText = _stokController.text.trim();
    final stokAwal = int.tryParse(stokText) ?? 0;

    final error = await ref
        .read(catalogProvider.notifier)
        .addItem(
          name: nama,
          price: hargaSen,
          categoryId: _selectedCategoryId,
          qty: stokAwal,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    await ref.read(catalogProvider.notifier).loadCatalog();
    if (!mounted) return;
    _batalkan();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogProvider);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.asBottomSheet) ...[
          AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _batalkan,
            ),
            title: Text(
              'Tambah Barang Baru',
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
          ),
        ] else ...[
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tambah Barang Baru',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 28 / 20,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _batalkan,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    'Nama Barang',
                    _namaController,
                    isRequired: true,
                    hint: 'Contoh: Mie Ayam',
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    'Kode Barang (SKU)',
                    _skuController,
                    isRequired: false,
                    hint: 'Otomatis dibuat',
                  ),
                  const SizedBox(height: 16),
                  _buildKategoriDropdown(state),
                  const SizedBox(height: 16),
                  _buildSatuanDropdown(),
                  const SizedBox(height: 16),
                  _buildHargaField(),
                  const SizedBox(height: 16),
                  _buildStokAwalField(),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.outlineVariant)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _batalkan,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 20 / 16,
                          letterSpacing: 0.16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _simpan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Simpan Barang',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 20 / 16,
                                letterSpacing: 0.16,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.asBottomSheet) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(children: [Expanded(child: body)]),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: body),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 20 / 16,
                letterSpacing: 0.16,
                color: AppColors.onSurface,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextFormField(
            controller: controller,
            validator: isRequired
                ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
                color: AppColors.onSurfaceVariant,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  Widget _buildKategoriDropdown(CatalogState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Kategori',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 20 / 16,
                letterSpacing: 0.16,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              ' *',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            hint: Text(
              'Pilih kategori',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            validator: (v) => v == null ? 'Wajib dipilih' : null,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 24 / 16,
              color: AppColors.onSurface,
            ),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.onSurfaceVariant,
            ),
            items: state.categories.map((cat) {
              final id = cat['id'] as String;
              final name = cat['name'] as String;
              return DropdownMenuItem(value: id, child: Text(name));
            }).toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v),
          ),
        ),
      ],
    );
  }

  Widget _buildSatuanDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Satuan',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 20 / 16,
                letterSpacing: 0.16,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              ' *',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedSatuan,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            validator: (v) => v == null ? 'Wajib dipilih' : null,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 24 / 16,
              color: AppColors.onSurface,
            ),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.onSurfaceVariant,
            ),
            items: _satuanOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedSatuan = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHargaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Harga Jual per Satuan',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 20 / 16,
            letterSpacing: 0.16,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                ),
                child: Text(
                  AppStrings.currencyPrefix.trim(),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 24 / 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 24 / 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
      ],
    );
  }

  Widget _buildStokAwalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stok Awal',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 20 / 16,
            letterSpacing: 0.16,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextFormField(
            controller: _stokController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
                color: AppColors.onSurfaceVariant,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}
