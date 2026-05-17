import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/theme/app_theme.dart';
import 'package:warung_pintar_cimahi/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:warung_pintar_cimahi/shared/widgets/app_icon.dart';

class OnboardingWelcomePage extends ConsumerWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _TopAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.marginPage,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.stackLg),
                    _HeroIllustration(),
                    const SizedBox(height: AppTheme.stackLg),
                    _HeadlineSection(),
                    const SizedBox(height: AppTheme.stackLg),
                    _BenefitsGrid(),
                    const SizedBox(height: AppTheme.stackLg),
                    _AiBubble(),
                    const SizedBox(height: AppTheme.stackLg),
                  ],
                ),
              ),
            ),
            _BottomAction(ref),
          ],
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.touchTargetMin,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppTheme.marginPage),
          AppIcon(size: 24, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'WarungPintar',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          Text(
            '1/4',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppTheme.marginPage),
        ],
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height:
          ((MediaQuery.of(context).size.width - AppTheme.marginPage * 2) *
                  9 /
                  16)
              .clamp(180, 280),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Center(
        child: Icon(
          Icons.storefront,
          size: 64,
          color: AppColors.primaryFixedDim,
        ),
      ),
    );
  }
}

class _HeadlineSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Halo!',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppTheme.stackSm),
        Text(
          'Mari mulai kelola warung lebih mudah dan pintar.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _BenefitsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _BenefitCard(
          icon: Icons.mic,
          iconBg: AppColors.primaryContainer,
          iconColor: AppColors.onPrimaryContainer,
          title: 'Catat dengan Suara',
          subtitle:
              'Tidak perlu mengetik panjang lebar. Cukup bicarakan transaksi Anda.',
        ),
        SizedBox(height: AppTheme.gutter),
        _BenefitCard(
          icon: Icons.inventory_2,
          iconBg: AppColors.secondaryContainer,
          iconColor: AppColors.onSecondaryContainer,
          title: 'Pantau Stok Akurat',
          subtitle:
              'Ketahui sisa barang secara real-time untuk mencegah kehabisan stok.',
        ),
        SizedBox(height: AppTheme.gutter),
        _BenefitCard(
          icon: Icons.trending_up,
          iconBg: AppColors.tertiaryContainer,
          iconColor: AppColors.onTertiaryContainer,
          title: 'Laporan Laba Jelas',
          subtitle: 'Laporan harian otomatis yang mudah dibaca dan dipahami.',
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _BenefitCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        color: AppColors.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppTheme.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: const Color(0xFF6B21A8).withAlpha(51)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF6B21A8), size: 20),
          const SizedBox(width: AppTheme.stackSm),
          Expanded(
            child: Text(
              'Semua berjalan offline, tanpa internet, aman.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B21A8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends ConsumerWidget {
  final WidgetRef ref;

  const _BottomAction(this.ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.marginPage,
        AppTheme.stackSm,
        AppTheme.marginPage,
        AppTheme.stackLg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppTheme.touchTargetMin,
        child: ElevatedButton(
          onPressed: () {
            ref.read(onboardingProvider.notifier).startOnboarding();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
          ),
          child: const Text('Mulai Setup'),
        ),
      ),
    );
  }
}
