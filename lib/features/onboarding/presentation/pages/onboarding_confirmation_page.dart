import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/theme/app_theme.dart';
import 'package:warung_pintar_cimahi/features/onboarding/presentation/providers/onboarding_provider.dart';

class OnboardingConfirmationPage extends ConsumerWidget {
  const OnboardingConfirmationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.stackLg),
                    _AiBubble(),
                    const SizedBox(height: AppTheme.stackMd),
                    _SummaryCard(state: state),
                    const SizedBox(height: AppTheme.stackLg),
                    _AiTipBubble(),
                    const SizedBox(height: AppTheme.stackLg),
                    _TipsCard(),
                    const SizedBox(height: AppTheme.stackLg),
                    _PrimaryButton(),
                    const SizedBox(height: AppTheme.stackLg),
                  ],
                ),
              ),
            ),
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
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Langkah 3 dari 4',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppTheme.touchTargetMin),
        ],
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.smart_toy,
            color: AppColors.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: AppTheme.gutter),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.stackMd),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppTheme.radiusXl),
                bottomRight: Radius.circular(AppTheme.radiusXl),
                bottomLeft: Radius.circular(AppTheme.radiusXl),
              ),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Text(
              'Setup hampir selesai! Ini yang sudah Ibu atur:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  final OnboardingState state;

  const _SummaryCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Pengaturan',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: () {},
                constraints: const BoxConstraints(
                  minWidth: AppTheme.touchTargetMin,
                  minHeight: AppTheme.touchTargetMin,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.stackSm),
          _SummaryItem(
            text: 'Warung: ${state.shopName.isNotEmpty ? state.shopName : "-"}',
          ),
          const SizedBox(height: AppTheme.stackSm),
          const _SummaryItem(text: 'Barang: Mie Ayam (10 pcs)'),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String text;

  const _SummaryItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
        const SizedBox(width: AppTheme.stackSm),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
        ),
      ],
    );
  }
}

class _AiTipBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.smart_toy,
            color: AppColors.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: AppTheme.gutter),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.stackMd),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppTheme.radiusXl),
                bottomRight: Radius.circular(AppTheme.radiusXl),
                bottomLeft: Radius.circular(AppTheme.radiusXl),
              ),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sekarang Ibu sudah siap! Cobalah hal ini nanti:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: AppTheme.stackSm),
                Text(
                  '• Catat penjualan dengan suara\n'
                  '• Cek sisa stok barang\n'
                  '• Lihat laporan harian',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: const Border(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.lightbulb,
              color: AppColors.onSecondaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Pertama',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: AppTheme.stackSm),
                Text(
                  'Tekan tombol mikrofon nanti dan bilang:\n'
                  '"Laku mie ayam dua bungkus"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSecondaryContainer,
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

class _PrimaryButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.touchTargetMin,
      child: ElevatedButton(
        onPressed: () {
          ref.read(onboardingProvider.notifier).confirmSetup();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Mulai Catat Transaksi'),
            SizedBox(width: AppTheme.stackSm),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}
