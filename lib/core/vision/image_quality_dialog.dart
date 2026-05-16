import 'package:flutter/material.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/vision/image_quality_gate.dart';

/// Dialog feedback for failed image quality validation (PRD §16.7.3).
///
/// Shows a reason-specific message and offers "Foto Ulang" or "Batal".
class ImageQualityFailDialog extends StatelessWidget {
  final ImageQualityFailReason reason;
  const ImageQualityFailDialog({super.key, required this.reason});

  String get _message => switch (reason) {
        ImageQualityFailReason.fileTooSmall =>
          'Foto tidak terbaca — mungkin terlalu buram atau tidak tertangkap '
              'kamera. Coba ambil foto lagi.',
        ImageQualityFailReason.resolutionTooLow =>
          'Foto terlalu kecil. Pastikan struk atau kemasan mengisi '
              'sebagian besar layar kamera.',
        ImageQualityFailReason.tooDark =>
          'Foto terlalu gelap. Coba lagi dengan cahaya lebih baik — '
              'dekat jendela atau nyalakan lampu.',
      };

  String get _title => switch (reason) {
        ImageQualityFailReason.fileTooSmall => 'Foto Tidak Terdeteksi',
        ImageQualityFailReason.resolutionTooLow => 'Foto Terlalu Kecil',
        ImageQualityFailReason.tooDark => 'Foto Terlalu Gelap',
      };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            color: AppColors.pendingText,
          ),
          const SizedBox(width: 8),
          Text(_title),
        ],
      ),
      content: Text(_message, style: const TextStyle(fontSize: 15)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Foto Ulang'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  /// Returns `true` if user chose "Foto Ulang", `false` if "Batal".
  static Future<bool> show(
    BuildContext context,
    ImageQualityFailReason reason,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImageQualityFailDialog(reason: reason),
    );
    return result ?? false;
  }
}
