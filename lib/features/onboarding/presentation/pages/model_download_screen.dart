import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/ai/model_download_service.dart';
import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

/// Model download screen shown on first launch (PRD §16.1.4).
///
/// Displays progress bar, percentage, estimated time remaining, and retry.
class ModelDownloadScreen extends ConsumerWidget {
  const ModelDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(modelDownloadProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon
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

              // Title
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
              const SizedBox(height: 40),

              // Progress content — varies by state
              _buildContent(context, ref, downloadState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ModelDownloadState state,
  ) {
    return switch (state) {
      DownloadIdle() => _buildStartButton(context, ref),
      DownloadProgress() => _buildProgressIndicator(context, state),
      DownloadVerifying() => _buildVerifying(context),
      DownloadComplete() => _buildComplete(context),
      DownloadFailed(:final reason) => _buildFailed(context, ref, reason),
    };
  }

  Widget _buildStartButton(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Icon(Icons.cloud_download_outlined, size: 48, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          'Ukuran: ~2.5 GB\nDisarankan menggunakan WiFi',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () {
              ref.read(modelDownloadProvider.notifier).startDownload();
            },
            icon: const Icon(Icons.download),
            label: const Text('Mulai Download'),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    DownloadProgress state,
  ) {
    final percentText = '${(state.percent * 100).toStringAsFixed(1)}%';
    final mbDownloaded = (state.downloadedBytes / 1024 / 1024).toStringAsFixed(0);
    final mbTotal = (state.totalBytes / 1024 / 1024).toStringAsFixed(0);
    final etaText = _formatEta(state.estimatedSecondsRemaining);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: state.percent,
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
          '$mbDownloaded MB / $mbTotal MB',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Estimasi: $etaText',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
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

  Widget _buildVerifying(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Memverifikasi integritas file...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildComplete(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 48, color: AppColors.confirmed),
        const SizedBox(height: 16),
        Text(
          'AI siap digunakan!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.confirmed,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildFailed(BuildContext context, WidgetRef ref, String reason) {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          reason,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () {
              ref.read(modelDownloadProvider.notifier).startDownload();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // Skip download — enter permanent manual mode
            // AppInitNotifier will handle via ModelFailed state
          },
          child: const Text(
            'Lewati — gunakan mode manual',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  String _formatEta(int seconds) {
    if (seconds <= 0) return 'menghitung...';
    if (seconds < 60) return '$seconds detik';
    if (seconds < 3600) return '${seconds ~/ 60} menit';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '$hours jam $mins menit';
  }
}
