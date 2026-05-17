import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/ai/model_download_service.dart';
import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

/// Model download screen shown on first launch (PRD §16.1.4).
///
/// Displays progress bar, percentage, estimated time remaining, and retry.
/// Handles WiFi warning, parallel chunk download progress, and verification.
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
              _buildHeader(context),
              const SizedBox(height: 40),
              _buildContent(context, ref, downloadState),
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
    ModelDownloadState state,
  ) {
    return switch (state) {
      DownloadIdle(:final isResumable, :final alreadyDownloadedBytes) =>
        _buildStartButton(context, ref, isResumable, alreadyDownloadedBytes),
      DownloadWaitingWifi() => _buildWaitingWifi(context, ref),
      DownloadProgress() => _buildProgressIndicator(context, ref, state),
      DownloadVerifying(:final percent) => _buildVerifying(context, percent),
      DownloadComplete() => _buildComplete(context),
      DownloadFailed(:final reason, :final canRetry, :final retryAfterSeconds) =>
        _buildFailed(context, ref, reason, canRetry, retryAfterSeconds),
      DownloadCancelled(:final savedBytes) =>
        _buildCancelled(context, ref, savedBytes),
    };
  }

  Widget _buildStartButton(
    BuildContext context,
    WidgetRef ref,
    bool isResumable,
    int alreadyDownloadedBytes,
  ) {
    return Column(
      children: [
        const Icon(
          Icons.cloud_download_outlined,
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        if (isResumable && alreadyDownloadedBytes > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history,
                  size: 20,
                  color: AppColors.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatBytes(alreadyDownloadedBytes)} sudah diunduh',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSecondaryContainer,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Ukuran: ~2.5 GB\nDisarankan menggunakan WiFi',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
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
            label: Text(isResumable ? 'Lanjutkan Download' : 'Mulai Download'),
          ),
        ),
        if (isResumable) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                ref
                    .read(modelDownloadProvider.notifier)
                    .startDownload(forceRestart: true);
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Mulai Ulang'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWaitingWifi(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.errorContainer,
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.wifi_off,
            size: 40,
            color: AppColors.onErrorContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'WiFi Tidak Tersedia',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Download model (~2.5 GB) menggunakan data seluler '
          'akan memakan banyak paket data.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () {
              ref.read(modelDownloadProvider.notifier).resumeDownload();
            },
            icon: const Icon(Icons.wifi),
            label: const Text('Download dengan WiFi'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            ref.read(modelDownloadProvider.notifier).startDownload();
          },
          child: const Text(
            'Tetap download dengan data seluler',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    WidgetRef ref,
    DownloadProgress state,
  ) {
    final percentText = '${(state.percent * 100).toStringAsFixed(1)}%';
    final mbDownloaded = (state.downloadedBytes / 1024 / 1024).toStringAsFixed(
      0,
    );
    final mbTotal = (state.totalBytes / 1024 / 1024).toStringAsFixed(0);
    final etaText = _formatEta(state.estimatedSecondsRemaining);
    final speedText =
        '${state.downloadSpeedMBps.toStringAsFixed(1)} MB/s';

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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.speed,
              size: 14,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              speedText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            const Icon(
              Icons.access_time,
              size: 14,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Sisa: $etaText',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Chunk ${state.currentChunk}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () {
                ref.read(modelDownloadProvider.notifier).cancelDownload();
              },
              icon: const Icon(Icons.pause, size: 18),
              label: const Text('Batal'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
              ),
            ),
          ],
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

  Widget _buildVerifying(BuildContext context, double percent) {
    final percentText = '${(percent * 100).toStringAsFixed(0)}%';

    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percent > 0 ? percent : null,
                strokeWidth: 6,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
              if (percent > 0)
                Text(
                  percentText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                )
              else
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          percent > 0 ? 'Memverifikasi file...' : 'Memverifikasi integritas file...',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mohon tunggu, proses ini memastikan file tidak korup',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
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

  Widget _buildFailed(
    BuildContext context,
    WidgetRef ref,
    String reason,
    bool canRetry,
    int? retryAfterSeconds,
  ) {
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
        if (retryAfterSeconds != null) ...[
          const SizedBox(height: 8),
          Text(
            'Bisa dicoba lagi dalam $retryAfterSeconds detik',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 24),
        if (canRetry)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: retryAfterSeconds == null
                  ? () {
                      ref.read(modelDownloadProvider.notifier).retryDownload();
                    }
                  : null,
              icon: const Icon(Icons.refresh),
              label: Text(
                retryAfterSeconds == null ? 'Coba Lagi' : 'Mohon tunggu...',
              ),
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

  Widget _buildCancelled(BuildContext context, WidgetRef ref, int savedBytes) {
    return Column(
      children: [
        const Icon(
          Icons.pause_circle_outline,
          size: 48,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          'Download Dibatalkan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        if (savedBytes > 0)
          Text(
            '${_formatBytes(savedBytes)} sudah diunduh dan tersimpan.\n'
            'Download bisa dilanjutkan kapan saja.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          )
        else
          Text(
            'Download bisa dimulai kapan saja.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () {
              ref.read(modelDownloadProvider.notifier).resumeDownload();
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Lanjutkan'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // Skip download — enter permanent manual mode
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}