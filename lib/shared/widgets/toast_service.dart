import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

/// Toast system — snackbar/toast per PRD §12.8 (ACT-71).
///
/// - Sukses: auto-dismiss 3s, `bg-secondary`, `text-on-secondary`
/// - Info: auto-dismiss 4s, `bg-primary`, `text-on-primary`
/// - Warning: manual dismiss, `bg-tertiary`, `text-on-tertiary`
/// - Error: manual dismiss, `bg-error`, `text-on-error`
///
/// Toast muncul di bawah TopAppBar, bukan di bottom.
class ToastService {
  ToastService._();

  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: AppColors.secondary,
      textColor: AppColors.onSecondary,
      duration: const Duration(seconds: 3),
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: AppColors.primary,
      textColor: AppColors.onPrimary,
      duration: const Duration(seconds: 4),
    );
  }

  static void warning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber,
      backgroundColor: AppColors.tertiary,
      textColor: AppColors.onTertiary,
      duration: null, // manual dismiss
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: AppColors.error,
      textColor: AppColors.onError,
      duration: null, // manual dismiss — tidak pernah auto (PRD §12.8)
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (duration == null)
              IconButton(
                icon: Icon(Icons.close, color: textColor, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration ?? const Duration(days: 1), // effectively infinite
        dismissDirection:
            duration == null ? DismissDirection.horizontal : DismissDirection.down,
      ),
    );
  }
}
