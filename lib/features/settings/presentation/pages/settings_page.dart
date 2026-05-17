import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/theme/app_theme.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _warningThreshold = 5;
  final Set<String> _selectedCategories = {'Sembako', 'Minuman'};
  int _fontSizeIndex = 1;
  bool _aiConfidence = true;
  double _voiceSensitivity = 0.7;

  final _namaWarungController = TextEditingController(text: 'Warung Sejahtera');
  final _namaPemilikController = TextEditingController(text: 'Budi Santoso');
  final _alamatController = TextEditingController(
    text: 'Jl. Merdeka No. 123, Bandung',
  );
  final _noTeleponController = TextEditingController(text: '081234567890');

  final _kategoriList = [
    'Sembako',
    'Minuman',
    'Snack',
    'Rokok',
    'Alat Tulis',
    'Obat',
  ];

  @override
  void dispose() {
    _namaWarungController.dispose();
    _namaPemilikController.dispose();
    _alamatController.dispose();
    _noTeleponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.storefront, color: AppColors.primary),
          onPressed: () => context.go('/'),
        ),
        centerTitle: true,
        title: Text(
          'Pengaturan',
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
          TextButton(
            onPressed: () {},
            child: Text(
              'Simpan',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.marginPage),
        children: [
          _ProfilUsahaSection(
            namaWarungController: _namaWarungController,
            namaPemilikController: _namaPemilikController,
            alamatController: _alamatController,
            noTeleponController: _noTeleponController,
          ),
          const SizedBox(height: AppTheme.stackMd),
          _PengaturanStokSection(
            warningThreshold: _warningThreshold,
            onThresholdChanged: (v) => setState(() => _warningThreshold = v),
            selectedCategories: _selectedCategories,
            onCategoryToggled: (cat) {
              setState(() {
                if (_selectedCategories.contains(cat)) {
                  _selectedCategories.remove(cat);
                } else {
                  _selectedCategories.add(cat);
                }
              });
            },
            kategoriList: _kategoriList,
          ),
          const SizedBox(height: AppTheme.stackMd),
          _TampilanSection(
            fontSizeIndex: _fontSizeIndex,
            onFontSizeChanged: (v) => setState(() => _fontSizeIndex = v),
          ),
          const SizedBox(height: AppTheme.stackMd),
          _PengaturanAISection(
            aiConfidence: _aiConfidence,
            onAiConfidenceChanged: (v) => setState(() => _aiConfidence = v),
            voiceSensitivity: _voiceSensitivity,
            onVoiceSensitivityChanged: (v) =>
                setState(() => _voiceSensitivity = v),
          ),
          const SizedBox(height: AppTheme.stackMd),
          const _DataBackupSection(),
          const SizedBox(height: AppTheme.stackMd),
          const _TentangSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.marginPage),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.stackMd),
          child,
        ],
      ),
    );
  }
}

class _ProfilUsahaSection extends StatelessWidget {
  final TextEditingController namaWarungController;
  final TextEditingController namaPemilikController;
  final TextEditingController alamatController;
  final TextEditingController noTeleponController;

  const _ProfilUsahaSection({
    required this.namaWarungController,
    required this.namaPemilikController,
    required this.alamatController,
    required this.noTeleponController,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Profil Usaha',
      child: Column(
        children: [
          _FormField(label: 'Nama Warung*', controller: namaWarungController),
          const SizedBox(height: AppTheme.stackMd),
          _FormField(label: 'Nama Pemilik', controller: namaPemilikController),
          const SizedBox(height: AppTheme.stackMd),
          _FormField(
            label: 'Alamat',
            controller: alamatController,
            maxLines: 3,
          ),
          const SizedBox(height: AppTheme.stackMd),
          _FormField(
            label: 'No Telepon',
            controller: noTeleponController,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int? maxLines;
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.marginPage,
              vertical: 12,
            ),
            isDense: true,
          ),
          style: GoogleFonts.inter(fontSize: 16),
        ),
      ],
    );
  }
}

class _PengaturanStokSection extends StatelessWidget {
  final int warningThreshold;
  final ValueChanged<int> onThresholdChanged;
  final Set<String> selectedCategories;
  final ValueChanged<String> onCategoryToggled;
  final List<String> kategoriList;

  const _PengaturanStokSection({
    required this.warningThreshold,
    required this.onThresholdChanged,
    required this.selectedCategories,
    required this.onCategoryToggled,
    required this.kategoriList,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Pengaturan Stok',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batas Peringatan',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.stackSm),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: warningThreshold > 1
                    ? () => onThresholdChanged(warningThreshold - 1)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
                ),
                child: Text(
                  '$warningThreshold pcs',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: warningThreshold < 50
                    ? () => onThresholdChanged(warningThreshold + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.stackMd),
          Text(
            'Kategori Stok Kritis',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.stackSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kategoriList.map((cat) {
              final isSelected = selectedCategories.contains(cat);
              return GestureDetector(
                onTap: () => onCategoryToggled(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryContainer
                          : AppColors.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TampilanSection extends StatelessWidget {
  final int fontSizeIndex;
  final ValueChanged<int> onFontSizeChanged;

  const _TampilanSection({
    required this.fontSizeIndex,
    required this.onFontSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['Kecil', 'Sedang', 'Besar'];
    final sizes = [14.0, 16.0, 20.0];

    return _SettingsCard(
      title: 'Tampilan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ukuran Tulisan',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.stackSm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: List.generate(3, (i) {
                final isActive = i == fontSizeIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onFontSizeChanged(i),
                    child: Container(
                      height: AppTheme.touchTargetMin,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.surfaceVariant
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                      child: Text(
                        labels[i],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppTheme.stackMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.marginPage),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contoh Teks',
                  style: GoogleFonts.inter(
                    fontSize: sizes[fontSizeIndex] * 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                  style: GoogleFonts.inter(fontSize: sizes[fontSizeIndex]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PengaturanAISection extends StatefulWidget {
  final bool aiConfidence;
  final ValueChanged<bool> onAiConfidenceChanged;
  final double voiceSensitivity;
  final ValueChanged<double> onVoiceSensitivityChanged;

  const _PengaturanAISection({
    required this.aiConfidence,
    required this.onAiConfidenceChanged,
    required this.voiceSensitivity,
    required this.onVoiceSensitivityChanged,
  });

  @override
  State<_PengaturanAISection> createState() => _PengaturanAISectionState();
}

class _PengaturanAISectionState extends State<_PengaturanAISection> {
  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Pengaturan AI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Keyakinan AI',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Switch(
                value: widget.aiConfidence,
                onChanged: widget.onAiConfidenceChanged,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: AppTheme.stackSm),
          Text(
            'Sensitivitas Suara',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.stackSm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.outlineVariant,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withAlpha(20),
            ),
            child: Slider(
              value: widget.voiceSensitivity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(widget.voiceSensitivity * 100).round()}%',
              onChanged: widget.onVoiceSensitivityChanged,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(widget.voiceSensitivity * 100).round()}%',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.stackSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Konfirmasi sebelum simpan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Switch(
                value: true,
                onChanged: (v) {},
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataBackupSection extends StatelessWidget {
  const _DataBackupSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Data & Backup',
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.file_download_outlined,
            label: 'Ekspor CSV',
            onTap: () {},
          ),
          const Divider(color: AppColors.outlineVariant),
          _ActionRow(
            icon: Icons.cloud_upload_outlined,
            label: 'Backup',
            onTap: () {},
          ),
          const Divider(color: AppColors.outlineVariant),
          _ActionRow(
            icon: Icons.cloud_download_outlined,
            label: 'Pulihkan',
            onTap: () {},
          ),
          const Divider(color: AppColors.outlineVariant),
          _ActionRow(
            icon: Icons.delete_forever_outlined,
            label: 'Hapus Semua Data',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.stackSm),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppColors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: AppTheme.stackMd),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TentangSection extends StatelessWidget {
  const _TentangSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Tentang',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoRow(label: 'Versi', value: 'v1.0.0'),
          const SizedBox(height: AppTheme.stackSm),
          const _InfoRow(label: 'Model AI', value: 'AI Gemma'),
          const SizedBox(height: AppTheme.stackMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Panduan Penggunaan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
