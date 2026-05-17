import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_notifier.dart';
import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';

class AiLoadingBanner extends ConsumerStatefulWidget {
  const AiLoadingBanner({super.key});

  @override
  ConsumerState<AiLoadingBanner> createState() => _AiLoadingBannerState();
}

class _AiLoadingBannerState extends ConsumerState<AiLoadingBanner>
    with SingleTickerProviderStateMixin {
  DateTime? _downloadStartTime;
  double _lastProgress = 0;
  double _speedMBps = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const double _totalSizeMB = 2594;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updateSpeed(double progress) {
    if (_lastProgress == 0 && progress > 0) {
      _downloadStartTime = DateTime.now();
      _pulseController.repeat(reverse: true);
    }
    if (progress > _lastProgress && _downloadStartTime != null) {
      final elapsed = DateTime.now().difference(_downloadStartTime!).inSeconds;
      if (elapsed > 0) {
        final downloadedMB = progress * _totalSizeMB;
        _speedMBps = downloadedMB / elapsed;
      }
    }
    _lastProgress = progress;
  }

  String _formatEta(double progress) {
    if (_speedMBps <= 0 || progress <= 0) return 'menghitung...';
    final remainingMB = (1 - progress) * _totalSizeMB;
    final seconds = (remainingMB / _speedMBps).round();
    if (seconds < 60) return '$seconds detik';
    if (seconds < 3600) return '${seconds ~/ 60} menit';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '$hours jam $mins menit';
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(appInitProvider);

    return switch (initState) {
      AppInitModelDownloading(:final progress) => _buildDownloadingBanner(context, progress),
      AppInitLoading() => _buildLoadingBanner(context),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildDownloadingBanner(BuildContext context, double progress) {
    _updateSpeed(progress);

    final percentText = '${(progress * 100).toStringAsFixed(1)}%';
    final downloadedMB = (progress * _totalSizeMB).toStringAsFixed(0);
    final speedText = _speedMBps > 0
        ? '${_speedMBps.toStringAsFixed(1)} MB/s'
        : 'menghitung...';
    final etaText = _formatEta(progress);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: Border.all(color: const Color(0xFFFFD54F)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: const _PulsingIcon(),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mengunduh model AI... $percentText',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF856404),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _InfoChip(icon: Icons.speed, text: speedText),
                        const SizedBox(width: 8),
                        _InfoChip(icon: Icons.access_time, text: 'Sisa: $etaText'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBA7517)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$downloadedMB / $_totalSizeMB MB',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF856404).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBanner(BuildContext context) {
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
              'Sedang memuat model. Fitur suara dan foto akan segera tersedia',
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

class _PulsingIcon extends StatelessWidget {
  const _PulsingIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.downloading,
        size: 18,
        color: Color(0xFFBA7517),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFBA7517).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF856404)),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF856404),
            ),
          ),
        ],
      ),
    );
  }
}
