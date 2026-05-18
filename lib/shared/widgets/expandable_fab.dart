import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_notifier.dart';
import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';
import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/shared/widgets/photo_source_bottom_sheet.dart';

class ExpandableFab extends ConsumerStatefulWidget {
  const ExpandableFab({super.key});

  @override
  ConsumerState<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends ConsumerState<ExpandableFab> {
  void _showActionSheet() {
    final appState = ref.read(appInitProvider);
    final isAiReady = appState is AppInitModelReady;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Manual
                _SheetItem(
                  icon: Icons.edit_outlined,
                  label: 'Transaksi Manual',
                  subtitle: 'Input barang satu per satu',
                  enabled: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/transaction/new');
                  },
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                // Foto
                _SheetItem(
                  icon: Icons.camera_alt_outlined,
                  label: 'Foto Struk / Barang',
                  subtitle: 'AI baca struk atau kemasan',
                  enabled: isAiReady,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showPhotoSourceSheet();
                  },
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                // Suara
                _SheetItem(
                  icon: Icons.mic,
                  label: 'Transaksi Suara',
                  subtitle: 'Rekam suara, AI catat otomatis',
                  enabled: isAiReady,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/voice-input');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const PhotoSourceBottomSheet(),
    );
  }

  void _showAiDisabledSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur suara menunggu model AI selesai diunduh.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appInitProvider);
    final isAiReady = appState is AppInitModelReady;
    final isAiDisabled = !isAiReady;

    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: isAiDisabled ? _showAiDisabledSnackbar : _showActionSheet,
        backgroundColor: isAiDisabled
            ? AppColors.surfaceContainerHighest
            : AppColors.primary,
        foregroundColor: isAiDisabled
            ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
            : Colors.white,
        elevation: isAiDisabled ? 0 : 4,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _SheetItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.surfaceContainerLow
              : AppColors.surfaceContainerHighest,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled
              ? AppColors.primary
              : AppColors.onSurfaceVariant.withValues(alpha: 0.38),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant.withValues(alpha: 0.38),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? AppColors.onSurfaceVariant : AppColors.onSurfaceVariant.withValues(alpha: 0.38),
        ),
      ),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}
