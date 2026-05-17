import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_notifier.dart';
import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';
import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

class ModelDownloadScreen extends ConsumerWidget {
  const ModelDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(context),
              const SizedBox(height: 40),
              _buildContent(context, ref, initState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            size: 40,
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Menyiapkan AI Pintar',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mengunduh model AI agar fitur suara dan foto bisa '
          'digunakan tanpa internet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppInitState state,
  ) {
    return switch (state) {
      AppInitLoading() => _buildLoading(context),
      AppInitModelDownloading(:final progress) =>
        _buildDownloading(context, progress),
      AppInitModelReady() => _buildComplete(context),
      AppInitModelFailed(:final reason) => _buildFailed(context, reason),
      AppInitAiDegraded(:final reason) => _buildDegraded(context, reason),
    };
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(),
        ),
        const SizedBox(height: 24),
        Text(
          'Memuat model AI...',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildDownloading(BuildContext context, double progress) {
    final percentText = '${(progress * 100).toStringAsFixed(1)}%';

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: AppColors.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          percentText,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mengunduh model AI...',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          'Proses berjalan di background — Anda bisa tutup layar ini',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  Widget _buildComplete(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.confirmed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 48,
            color: AppColors.confirmed,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'AI siap digunakan!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.confirmed,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Model AI berhasil diunduh dan diverifikasi.\n'
          'Fitur suara dan foto sekarang aktif.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildFailed(BuildContext context, String reason) {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          reason,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
        ),
        const SizedBox(height: 24),
        Text(
          'Silakan coba lagi nanti atau gunakan mode manual.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildDegraded(BuildContext context, String reason) {
    return Column(
      children: [
        const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
        const SizedBox(height: 16),
        Text(
          'AI degraded: $reason',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.orange),
        ),
      ],
    );
  }
}
