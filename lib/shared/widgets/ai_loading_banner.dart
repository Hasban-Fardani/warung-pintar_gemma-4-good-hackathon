import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_notifier.dart';
import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';

class AiLoadingBanner extends ConsumerWidget {
  const AiLoadingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitProvider);

    return switch (initState) {
      AppInitModelDownloading(:final progress, :final speedMBps, :final eta) =>
        _buildDownloadingBanner(context, progress, speedMBps, eta),
      AppInitLoading() => _buildLoadingBanner(context),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildDownloadingBanner(
    BuildContext context,
    double progress,
    double speedMBps,
    String eta,
  ) {
    final percentText = '${(progress * 100).toStringAsFixed(1)}%';
    final downloadedMB = (progress * 2594).toStringAsFixed(0);
    final speedText = speedMBps > 0
        ? '${speedMBps.toStringAsFixed(1)} MB/s'
        : 'menghitung...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: Border.all(color: const Color(0xFFFFD54F)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const _PulsingIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mengunduh model AI... $percentText',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF856404),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _InfoChip(icon: Icons.speed, text: speedText),
                        const SizedBox(width: 8),
                        _InfoChip(icon: Icons.access_time, text: 'Sisa: $eta'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBA7517)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$downloadedMB / 2594 MB',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF856404).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: Border.all(color: const Color(0xFFFFD54F)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
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
              'Sedang memuat model. Fitur suara dan foto akan segera tersedia',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: const Color(0xFF856404),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatelessWidget {
  const _PulsingIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.downloading,
        size: 18,
        color: Color(0xFFBA7517),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFBA7517).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF856404)),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF856404),
            ),
          ),
        ],
      ),
    );
  }
}
