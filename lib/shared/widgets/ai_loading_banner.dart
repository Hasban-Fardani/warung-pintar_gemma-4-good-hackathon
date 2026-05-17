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
      AppInitModelDownloading(:final progress) =>
        _buildDownloadingBanner(context, progress),
      AppInitLoading() => _buildLoadingBanner(context),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildDownloadingBanner(BuildContext context, double progress) {
    final percentText = '${(progress * 100).toStringAsFixed(1)}%';

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
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress,
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
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFFFD54F).withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBA7517)),
            ),
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
