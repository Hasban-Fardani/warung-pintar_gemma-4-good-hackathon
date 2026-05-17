import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_notifier.dart';
import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';
import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

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
        if (_expanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),

        if (_expanded)
          Positioned(
            bottom: 88,
            right: 16,
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SubFabItem(
                    icon: Icons.mic,
                    label: 'Suara',
                    enabled: isAiReady,
                    onTap: () {
                      _close();
                      widget.onVoiceTap?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                  _SubFabItem(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    enabled: isAiReady,
                    onTap: () {
                      _close();
                      widget.onCameraTap?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                  _SubFabItem(
                    icon: Icons.edit_document,
                    label: 'Manual',
                    enabled: true,
                    onTap: () {
                      _close();
                      widget.onManualTap?.call();
                    },
                  ),
                ],
              ),
            ),
          ),

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
    );
  }
}

class _SubFabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _SubFabItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
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
              fontWeight: FontWeight.w500,
              color: enabled
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF414752).withValues(alpha: 0.38),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? const Color(0xFFF6F3F2)
                  : const Color(0xFFE5E2E1),
              border: Border.all(color: const Color(0xFFE0E0E0)),
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
              size: 22,
              color: enabled
                  ? const Color(0xFF005DAC)
                  : const Color(0xFF414752).withValues(alpha: 0.38),
            ),
          ),
        ),
      ],
    );
  }
}
