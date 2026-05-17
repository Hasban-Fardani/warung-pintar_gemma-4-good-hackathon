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

class _ExpandableFabState extends ConsumerState<ExpandableFab>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_expanded) _toggle();
  }

  void _showPhotoSourceSheet() {
    _close();
    showModalBottomSheet(
      context: context,
      builder: (context) => const PhotoSourceBottomSheet(),
    );
  }

  void _showAiDisabledSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur membutuhkan AI. AI sedang dimuat.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appInitProvider);
    final isAiReady = appState is AppInitModelReady;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        if (_expanded) _buildBackdrop(),
        if (_expanded) _buildMiniFabs(isAiReady),
        _buildMainFab(),
      ],
    );
  }

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _close,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              color: Colors.black.withValues(alpha: 0.5 * _controller.value),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniFabs(bool isAiReady) {
    return Positioned(
      bottom: 88,
      right: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMiniFab(
                index: 0,
                icon: Icons.edit_outlined,
                label: 'Manual',
                color: Colors.grey.shade700,
                enabled: true,
                onTap: () {
                  _close();
                  context.push('/transaction/new');
                },
              ),
              const SizedBox(height: 12),
              _buildMiniFab(
                index: 1,
                icon: Icons.camera_alt_outlined,
                label: 'Foto',
                color: Colors.green.shade600,
                enabled: isAiReady,
                onTap: isAiReady ? _showPhotoSourceSheet : _showAiDisabledSnackbar,
              ),
              const SizedBox(height: 12),
              _buildMiniFab(
                index: 2,
                icon: Icons.mic,
                label: 'Suara',
                color: AppColors.primary,
                enabled: isAiReady,
                onTap: isAiReady
                    ? () {
                        _close();
                        context.push('/voice-input');
                      }
                    : _showAiDisabledSnackbar,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniFab({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final delay = index * 50;
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay / 250,
        1.0,
        curve: Curves.easeOutCubic,
      ),
    ));

    final fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay / 250,
        1.0,
        curve: Curves.easeIn,
      ),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: _MiniFabItem(
          icon: icon,
          label: label,
          color: color,
          enabled: enabled,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildMainFab() {
    return RotationTransition(
      turns: Tween<double>(begin: 0, end: 0.125).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: _expanded ? 8 : 4,
          child: Icon(_expanded ? Icons.close : Icons.mic),
        ),
      ),
    );
  }
}

class _MiniFabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _MiniFabItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 72),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: enabled
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? AppColors.surfaceContainerLowest
                  : AppColors.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: enabled ? color : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
