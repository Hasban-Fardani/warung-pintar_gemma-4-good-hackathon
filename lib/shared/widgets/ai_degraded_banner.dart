import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

/// AI Degraded Banner — tampil saat `AppInitAiDegraded` (ACT-66).
///
/// PRD §16.6.2: Warna `#FFEDED`, icon warning + teks + tombol "Coba Lagi"
/// yang trigger `AppInitNotifier.initialize()`.
class AiDegradedBanner extends StatelessWidget {
  final String reason;
  final VoidCallback? onRetry;

  const AiDegradedBanner({
    super.key,
    required this.reason,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDED),
        border: Border.all(color: const Color(0xFFE57373)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Color(0xFFD32F2F), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI tidak tersedia: $reason',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: const Color(0xFF721C24),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
