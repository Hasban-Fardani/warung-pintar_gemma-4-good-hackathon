import 'package:flutter/material.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

/// Dialog shown when id-ID language pack is not installed (PRD §16.4.2).
///
/// Guides user to Android Language Settings to install the pack.
class LanguagePackDialog extends StatelessWidget {
  const LanguagePackDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bahasa Belum Terpasang'),
      content: const Text(
        'Fitur suara membutuhkan paket bahasa Indonesia (id-ID) '
        'yang terpasang di Android. Silakan pasang melalui Pengaturan '
        'Bahasa, lalu restart aplikasi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Nanti'),
        ),
        FilledButton(
          onPressed: () {
            // TODO: Deep link to Android Language Settings when
            // url_launcher is added in a future milestone.
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Buka Pengaturan'),
        ),
      ],
    );
  }

  /// Show the dialog. Returns when user dismisses.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LanguagePackDialog(),
    );
  }
}
