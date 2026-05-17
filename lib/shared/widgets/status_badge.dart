import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';

/// Reusable status badge widget (ACT-64).
///
/// Two types:
/// - **Input method**: voice (primary-container), image (secondary-container), manual (surface-variant)
/// - **Transaction status**: confirmed (secondary-container), pending (#FAEEDA), clarify (error-container)
///
/// PRD §12.5, DESIGN.md token compliance.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  /// Badge for input method (voice / image / manual).
  factory StatusBadge.inputMethod(InputMethod method) {
    return switch (method) {
      InputVoice() => const StatusBadge(
        label: 'Suara',
        backgroundColor: AppColors.primaryFixed,
        textColor: AppColors.onPrimaryFixed,
        icon: Icons.mic,
      ),
      InputImage() => const StatusBadge(
        label: 'Foto',
        backgroundColor: AppColors.secondaryFixed,
        textColor: AppColors.onSecondaryFixed,
        icon: Icons.photo_camera,
      ),
      InputManual() => const StatusBadge(
        label: 'Manual',
        backgroundColor: AppColors.surfaceVariant,
        textColor: AppColors.onSurfaceVariant,
        icon: Icons.edit_document,
      ),
    };
  }

  /// Badge for transaction status (confirmed / pending / clarify).
  factory StatusBadge.transactionStatus(
    TransactionStatus status, {
    bool needsClarification = false,
  }) {
    if (needsClarification) {
      return const StatusBadge(
        label: 'Perlu Klarifikasi',
        backgroundColor: AppColors.errorContainer,
        textColor: AppColors.onErrorContainer,
        icon: Icons.help_outline,
      );
    }
    return switch (status) {
      TransactionStatus.confirmed => const StatusBadge(
        label: 'Terkonfirmasi',
        backgroundColor: Color(0xFFDCF5DC),
        textColor: Color(0xFF059669),
        icon: Icons.check_circle_outline,
      ),
      TransactionStatus.pending => const StatusBadge(
        label: 'Pending',
        backgroundColor: AppColors.pendingBackground,
        textColor: AppColors.pendingText,
        icon: Icons.hourglass_empty,
      ),
      TransactionStatus.deleted => const StatusBadge(
        label: 'Dihapus',
        backgroundColor: AppColors.surfaceVariant,
        textColor: AppColors.onSurfaceVariant,
        icon: Icons.delete_outline,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      height: 24,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              letterSpacing: 0.5,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
