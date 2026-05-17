import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/theme/app_theme.dart';
import 'package:warung_pintar_cimahi/features/vision/domain/usecases/parse_product_usecase.dart';
import 'package:warung_pintar_cimahi/features/vision/presentation/providers/vision_provider.dart';

class ProductCapturePage extends ConsumerStatefulWidget {
  const ProductCapturePage({super.key});

  @override
  ConsumerState<ProductCapturePage> createState() => _ProductCapturePageState();
}

class _ProductCapturePageState extends ConsumerState<ProductCapturePage> {
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
    await ref.read(visionProvider.notifier).captureProduct(file);
  }

  @override
  Widget build(BuildContext context) {
    final visionState = ref.watch(visionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Produk Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          _CameraViewfinder(
            capturedImage: _capturedImage,
            onCapture: _pickImage,
          ),
          if (visionState.isProcessing)
            const _ProcessingOverlay()
          else if (visionState.state == VisionState.success &&
              visionState.result is ParseProductResult)
            _AiResultConfirmation(
              result: visionState.result as ParseProductResult,
              onRetake: () {
                ref.read(visionProvider.notifier).reset();
                setState(() => _capturedImage = null);
              },
            )
          else if (visionState.state == VisionState.error)
            _ErrorOverlay(
              message: visionState.errorMessage ?? 'Gagal memproses',
              onRetake: () {
                ref.read(visionProvider.notifier).reset();
                setState(() => _capturedImage = null);
              },
            ),
        ],
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
      margin: const EdgeInsets.fromLTRB(
        AppTheme.marginPage,
        AppTheme.marginPage,
        AppTheme.marginPage,
        0,
      ),
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
              _TargetingRectangle(),
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 240,
        height: 180,
        child: CustomPaint(painter: _TargetingRectPainter()),
      ),
    );
  }
}

class _TargetingRectPainter extends CustomPainter {
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
            'Arahkan kamera ke kemasan produk',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.inverseOnSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pastikan nama produk dan merek terbaca jelas',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.inverseOnSurface.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

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
                'Mengenali produk dari gambar',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiResultConfirmation extends StatelessWidget {
  final ParseProductResult result;
  final VoidCallback onRetake;

  const _AiResultConfirmation({required this.result, required this.onRetake});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.marginPage),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Keyakinan AI: 94%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.stackMd),
            Text(
              'Produk Terdeteksi',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.stackSm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nama Produk',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.productName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.outlineVariant),
            const SizedBox(height: AppTheme.stackSm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.estimatedCategory,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (result.sizeOrWeight != null) ...[
                  const SizedBox(width: AppTheme.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ukuran/Berat',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.sizeOrWeight!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.stackSm),
            Row(
              children: [
                Text(
                  'Jumlah',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppTheme.gutter),
                Text(
                  '0',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.stackMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetake,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.outline),
                    ),
                    child: const Text('Retake Suara'),
                  ),
                ),
                const SizedBox(width: AppTheme.gutter),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    child: const Text('Konfirmasi & Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onRetake;

  const _ErrorOverlay({required this.message, required this.onRetake});

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
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: AppTheme.stackMd),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.error),
              ),
              const SizedBox(height: AppTheme.stackMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRetake,
                      child: const Text('Ulangi'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.gutter),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Input Manual'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
