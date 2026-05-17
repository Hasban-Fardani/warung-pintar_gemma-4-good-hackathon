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

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        if (_expanded) _buildBackdrop(),
        if (_expanded && isAiReady) _buildMiniFabs(),
        _buildMainFab(isAiDisabled),
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

  Widget _buildMiniFabs() {
    return Positioned(
      bottom: 0,
      right: 32,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(width: 12),
              _buildMiniFab(
                index: 1,
                icon: Icons.mic,
                label: 'Suara',
                color: AppColors.primary,
                enabled: true,
                onTap: () {
                  _close();
                  context.push('/voice-input');
                },
              ),
              const SizedBox(width: 12),
              _buildMiniFab(
                index: 2,
                icon: Icons.camera_alt_outlined,
                label: 'Foto',
                color: Colors.green.shade600,
                enabled: true,
                onTap: () {
                  _close();
                  _showPhotoSourceSheet();
                },
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
      begin: const Offset(1, 0),
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

    final scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay / 250,
        1.0,
        curve: Curves.easeOutBack,
      ),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: _MiniFabItem(
            icon: icon,
            label: label,
            color: color,
            enabled: enabled,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildMainFab(bool isAiDisabled) {
    final rotation = _controller.drive(
      Tween<double>(begin: 0, end: 0.125),
    );

    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: isAiDisabled ? _showAiDisabledSnackbar : _toggle,
        backgroundColor: isAiDisabled
            ? AppColors.surfaceContainerHighest
            : AppColors.primary,
        foregroundColor: isAiDisabled
            ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
            : Colors.white,
        elevation: _expanded ? 8 : (isAiDisabled ? 0 : 4),
        child: AnimatedBuilder(
          animation: rotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: rotation.value * 3.14159 * 2,
              child: Icon(_expanded ? Icons.close : Icons.add),
            );
          },
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
      child: Column(
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
          const SizedBox(height: 8),
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
