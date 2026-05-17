import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

/// Permanent Manual Mode Banner — tampil saat `AppInitModelFailed` (ACT-67).
///
/// PRD §16.6.3: Warna `#424242` (inverse-surface), teks putih permanen.
/// Tidak ada tombol dismiss — ini bersifat permanen.
class PermanentManualModeBanner extends StatelessWidget {
  final String reason;

  const PermanentManualModeBanner({
    super.key,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.phonelink_erase, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode manual aktif. AI tidak tersedia: $reason',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
