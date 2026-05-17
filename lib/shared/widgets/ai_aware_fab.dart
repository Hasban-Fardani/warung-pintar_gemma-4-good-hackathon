import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_notifier.dart';
import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';
import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

/// AI-aware FAB with 3 sub-FABs (ACT-68).
///
/// PRD §12.3: Suara, Kamera, Manual.
/// Reads `AppInitState` — disables AI-dependent FABs when model not ready.
/// Main FAB: 56×56 `bg-primary-container text-on-primary-container`.
/// Overlay dim saat expand.
class AiAwareFab extends ConsumerStatefulWidget {
  final VoidCallback? onVoiceTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onManualTap;

  const AiAwareFab({
    super.key,
    this.onVoiceTap,
    this.onCameraTap,
    this.onManualTap,
  });

  @override
  ConsumerState<AiAwareFab> createState() => _AiAwareFabState();
}

class _AiAwareFabState extends ConsumerState<AiAwareFab>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _close() {
    if (_expanded) _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appInitProvider);
    final isAiReady = appState is AppInitModelReady;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Dim overlay
        if (_expanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: Container(color: Colors.black26),
            ),
          ),

        // FAB column
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Sub-FABs
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SubFab(
                    icon: Icons.mic,
                    label: isAiReady ? 'Suara' : 'AI sedang memuat...',
                    enabled: isAiReady,
                    onTap: () {
                      _close();
                      widget.onVoiceTap?.call();
                    },
                  ),
                  const SizedBox(height: 8),
                  _SubFab(
                    icon: Icons.photo_camera,
                    label: isAiReady ? 'Kamera' : 'AI sedang memuat...',
                    enabled: isAiReady,
                    onTap: () {
                      _close();
                      widget.onCameraTap?.call();
                    },
                  ),
                  const SizedBox(height: 8),
                  _SubFab(
                    icon: Icons.edit_document,
                    label: 'Manual',
                    enabled: true, // Manual always enabled
                    onTap: () {
                      _close();
                      widget.onManualTap?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Main FAB
            SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: _toggle,
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                elevation: _expanded ? 8 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: AppColors.primaryFixedDim),
                ),
                child: AnimatedRotation(
                  turns: _expanded ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(_expanded ? Icons.close : Icons.add),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _SubFab({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label tooltip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
              letterSpacing: 0.28,
              color: enabled
                  ? AppColors.onSurfaceVariant
                  : AppColors.outlineVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Sub-FAB button
        SizedBox(
          width: 40,
          height: 40,
          child: FloatingActionButton.small(
            heroTag: 'sub_fab_${icon.codePoint}',
            onPressed: enabled ? onTap : null,
            backgroundColor:
                enabled ? AppColors.surface : AppColors.surfaceContainerHigh,
            foregroundColor: enabled ? AppColors.primary : AppColors.outline,
            elevation: 2,
            shape: CircleBorder(
              side: BorderSide(
                color: enabled
                    ? AppColors.outlineVariant
                    : AppColors.surfaceContainerHigh,
              ),
            ),
            child: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }
}
