import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AI Loading Banner — tampil saat `AppInitModelLoading` (ACT-65).
///
/// PRD §16.2.2: Kuning `#FFF3CD`, teks + spinner kecil.
class AiLoadingBanner extends StatelessWidget {
  const AiLoadingBanner({super.key});

  @override
  Widget build(BuildContext context) {
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
              'AI sedang memuat model. Fitur suara dan foto belum tersedia.',
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
