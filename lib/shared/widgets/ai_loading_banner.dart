import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/ai/model_download_service.dart';

/// AI Loading Banner — tampil saat `AppInitModelLoading` atau `AppInitModelDownloading`.
///
/// Menampilkan progress download jika sedang mengunduh, atau status loading jika
/// model sedang dimuat ke memory.
class AiLoadingBanner extends ConsumerWidget {
  const AiLoadingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(modelDownloadProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: Border.all(color: const Color(0xFFFFD54F)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: switch (downloadState) {
        DownloadProgress(
          :final percent,
          :final downloadedBytes,
          :final totalBytes,
          :final downloadSpeedMBps,
          :final estimatedSecondsRemaining
        ) =>
          _buildProgressContent(
            context,
            percent,
            downloadedBytes,
            totalBytes,
            downloadSpeedMBps,
            estimatedSecondsRemaining,
          ),
        DownloadVerifying(:final percent) => _buildVerifyingContent(context, percent),
        _ => _buildLoadingContent(context),
      },
    );
  }

  Widget _buildProgressContent(
    BuildContext context,
    double percent,
    int downloadedBytes,
    int totalBytes,
    double speedMBps,
    int etaSeconds,
  ) {
    final percentText = '${(percent * 100).toStringAsFixed(1)}%';
    final mbDownloaded = (downloadedBytes / 1024 / 1024).toStringAsFixed(0);
    final mbTotal = (totalBytes / 1024 / 1024).toStringAsFixed(0);
    final etaText = _formatEta(etaSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: percent,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBA7517)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mengunduh model AI... $percentText',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF856404),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 4,
            backgroundColor: const Color(0xFFFFD54F).withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBA7517)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$mbDownloaded / $mbTotal MB',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF856404).withValues(alpha: 0.7),
              ),
            ),
            Text(
              '${speedMBps.toStringAsFixed(1)} MB/s · Sisa: $etaText',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF856404).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerifyingContent(BuildContext context, double percent) {
    final percentText = percent > 0 ? '${(percent * 100).toStringAsFixed(0)}%' : '';

    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA7517)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Memverifikasi model... $percentText',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF856404),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA7517)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Sedang memuat modal. Fitur suara dan foto akan segera tersedia',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
              color: const Color(0xFF856404),
            ),
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
