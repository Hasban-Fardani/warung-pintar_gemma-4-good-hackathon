import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/theme/app_theme.dart';
import 'package:warung_pintar_cimahi/features/onboarding/presentation/providers/onboarding_provider.dart';

class OnboardingProcessingPage extends ConsumerStatefulWidget {
  const OnboardingProcessingPage({super.key});

  @override
  ConsumerState<OnboardingProcessingPage> createState() =>
      _OnboardingProcessingPageState();
}

class _OnboardingProcessingPageState
    extends ConsumerState<OnboardingProcessingPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        ref.read(onboardingProvider.notifier).confirmSetup();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background.withAlpha(230),
      body: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.marginPage),
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(AppTheme.stackLg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SpinningIcon(),
              const SizedBox(height: AppTheme.stackLg),
              Text(
                'Saya sedang mengatur...',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: AppTheme.stackMd),
              _ProcessingSteps(),
              const SizedBox(height: AppTheme.stackLg),
              _ProgressBar(),
              const SizedBox(height: AppTheme.stackSm),
              Text(
                'Ini memakan waktu 3-5 detik',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.primaryFixed,
        shape: BoxShape.circle,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Transform.rotate(
          angle: _controller.value * 3.14159 * 2,
          child: child,
        ),
        child: const Icon(
          Icons.sync,
          size: 32,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ProcessingSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const _StepItem(
            icon: Icons.check_circle,
            iconColor: AppColors.primary,
            text: 'Membuat kategori: Sembako',
          ),
          const SizedBox(height: AppTheme.stackSm),
          const _StepItem(
            icon: Icons.check_circle,
            iconColor: AppColors.primary,
            text: 'Menambahkan: Beras, Telur',
          ),
          const SizedBox(height: AppTheme.stackSm),
          const _StepItem(
            icon: Icons.hourglass_empty,
            iconColor: AppColors.outline,
            text: 'Menyiapkan dashboard...',
            textColor: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color? textColor;

  const _StepItem({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: AppTheme.stackSm),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor ?? AppColors.onSurface,
              ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: double.infinity,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.outlineVariant.withAlpha(77),
          ),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 0.66,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
