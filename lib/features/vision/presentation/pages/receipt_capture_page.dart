import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/theme/app_theme.dart';
import 'package:warung_pintar_cimahi/features/vision/domain/usecases/parse_receipt_usecase.dart';
import 'package:warung_pintar_cimahi/features/vision/presentation/providers/vision_provider.dart';

class ReceiptCapturePage extends ConsumerStatefulWidget {
  const ReceiptCapturePage({super.key});

  @override
  ConsumerState<ReceiptCapturePage> createState() => _ReceiptCapturePageState();
}

class _ReceiptCapturePageState extends ConsumerState<ReceiptCapturePage> {
  File? _capturedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    setState(() => _capturedImage = file);
    await ref.read(visionProvider.notifier).captureReceipt(file);
  }

  @override
  Widget build(BuildContext context) {
    final visionState = ref.watch(visionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Stok'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          const _SegmentedControl(),
          Expanded(
            child: Stack(
              children: [
                _CameraViewfinder(
                  capturedImage: _capturedImage,
                  onCapture: _pickImage,
                ),
                if (visionState.isProcessing ||
                    visionState.state == VisionState.success ||
                    visionState.state == VisionState.error)
                  _AiParsingOverlay(
                    visionState: visionState,
                    onReset: () {
                      ref.read(visionProvider.notifier).reset();
                      setState(() => _capturedImage = null);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.marginPage,
        vertical: AppTheme.stackSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: const Row(
        children: [
          Expanded(child: _Segment(label: 'Manual', isActive: false)),
          Expanded(child: _Segment(label: 'Kamera', isActive: true)),
          Expanded(child: _Segment(label: 'Suara', isActive: false)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isActive;

  const _Segment({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.touchTargetMin,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceVariant : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      foregroundDecoration: isActive
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primary, width: 2),
              ),
            )
          : null,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CameraViewfinder extends StatelessWidget {
  final File? capturedImage;
  final VoidCallback onCapture;

  const _CameraViewfinder({this.capturedImage, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.marginPage),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (capturedImage != null)
              Image.file(
                capturedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              const _TargetingRectangle(),
            Positioned(
              bottom: AppTheme.stackLg,
              child: GestureDetector(
                onTap: onCapture,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            if (capturedImage == null)
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _InstructionOverlay(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TargetingRectangle extends StatelessWidget {
  const _TargetingRectangle();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 240,
      height: 180,
      child: CustomPaint(painter: _TargetingRectPainter()),
    );
  }
}

class _TargetingRectPainter extends CustomPainter {
  const _TargetingRectPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const cl = 24.0;

    final path = Path()
      ..moveTo(cl, 0)
      ..lineTo(0, 0)
      ..lineTo(0, cl)
      ..moveTo(size.width - cl, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, cl)
      ..moveTo(0, size.height - cl)
      ..lineTo(0, size.height)
      ..lineTo(cl, size.height)
      ..moveTo(size.width, size.height - cl)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - cl, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InstructionOverlay extends StatelessWidget {
  const _InstructionOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.marginPage),
      decoration: BoxDecoration(color: AppColors.inverseSurface.withAlpha(230)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Arahkan kamera ke struk pembelian',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.inverseOnSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pastikan struk terbaca jelas dan pencahayaan cukup',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.inverseOnSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: AppTheme.stackMd),
          const Align(
            alignment: Alignment.centerRight,
            child: _StatusIndicator(),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withAlpha(200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            'Offline \u00b7 AI Gemma',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiParsingOverlay extends StatelessWidget {
  final VisionStateData visionState;
  final VoidCallback onReset;

  const _AiParsingOverlay({required this.visionState, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppTheme.marginPage * 2),
          padding: const EdgeInsets.all(AppTheme.stackLg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (visionState.isProcessing) ...[
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: AppTheme.stackMd),
                Text(
                  'AI Gemma sedang memproses...',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.stackSm),
                Text(
                  'Membaca dan mengekstrak data struk',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ] else if (visionState.state == VisionState.success) ...[
                const Icon(
                  Icons.check_circle,
                  color: AppColors.secondary,
                  size: 48,
                ),
                const SizedBox(height: AppTheme.stackMd),
                Text(
                  'Struk Berhasil Dibaca',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (visionState.result is ParseReceiptResult) ...[
                  const SizedBox(height: AppTheme.stackSm),
                  Text(
                    '${(visionState.result as ParseReceiptResult).insertedCount} dari ${(visionState.result as ParseReceiptResult).totalDetected} item tersimpan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.stackMd),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onReset,
                    child: const Text('Konfirmasi & Simpan'),
                  ),
                ),
              ] else if (visionState.state == VisionState.error) ...[
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: AppTheme.stackMd),
                Text(
                  visionState.errorMessage ?? 'Gagal memproses',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppTheme.stackMd),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReset,
                        child: const Text('Ulangi'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.gutter),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onReset,
                        child: const Text('Input Manual'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
