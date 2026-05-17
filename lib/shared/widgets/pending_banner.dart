import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

/// Pending transaction banner — reactive via Riverpod (ACT-63).
///
/// PRD §12.4: Muncul hanya jika ada pending, angka update real-time.
/// Style: `bg-error-container border-error rounded-lg`.
class PendingBanner extends StatelessWidget {
  final int pendingCount;
  final VoidCallback? onConfirmTap;

  const PendingBanner({
    super.key,
    required this.pendingCount,
    this.onConfirmTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pendingBackground,
        border: Border.all(color: AppColors.pendingText),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty, color: AppColors.pendingText, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$pendingCount transaksi pending',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 20 / 16,
                color: AppColors.pendingText,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: TextButton.icon(
              onPressed: onConfirmTap,
              icon: const Icon(Icons.mic, size: 18),
              label: Text(
                'Konfirmasi',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.pendingText,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
