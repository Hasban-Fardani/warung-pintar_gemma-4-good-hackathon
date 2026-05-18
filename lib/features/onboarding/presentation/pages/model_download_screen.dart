import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_notifier.dart';
import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';
import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(appInitProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(context, initState),
              const SizedBox(height: 48),
              _buildContent(context, ref, initState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppInitState state) {
    final isDownloading = state is AppInitModelDownloading;
    final progress = isDownloading ? state.progress : 0.0;

    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: isDownloading ? progress : null,
                  strokeWidth: 6,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              _AnimatedRobotIcon(isDownloading: isDownloading),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Menyiapkan AI Pintar',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          isDownloading
              ? 'Menyatukan model AI...'
              : 'Memuat model AI...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppInitState state,
  ) {
    return switch (state) {
      AppInitLoading() => _buildLoading(context),
      AppInitModelDownloading(:final progress, :final speedMBps, :final eta) =>
        _buildDownloading(context, progress, speedMBps, eta),
      AppInitModelReady() => _buildComplete(context),
      AppInitModelFailed(:final reason) => _buildFailed(context, reason),
      AppInitAiDegraded(:final reason) => _buildDegraded(context, reason),
    };
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          'Mempersiapkan...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildDownloading(BuildContext context, double progress, double speedMBps, String eta) {
    final percentText = '${(progress * 100).toStringAsFixed(1)}%';
    final downloadedMB = (progress * 2594).toStringAsFixed(0);
    final speedText = speedMBps > 0
        ? '${speedMBps.toStringAsFixed(1)} MB/s'
        : 'menghitung...';

    return Column(
      children: [
        Text(
          percentText,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.speed,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  speedText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 10,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Sisa: $eta',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$downloadedMB / 2594 MB',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Jangan tutup aplikasi selama proses berlangsung',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildComplete(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.confirmed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppColors.confirmed,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'AI siap digunakan!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.confirmed,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Model AI berhasil disiapkan dan diverifikasi.\n'
          'Fitur suara dan foto sekarang aktif.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildFailed(BuildContext context, String reason) {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          reason,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
        ),
        const SizedBox(height: 24),
        Text(
          'Silakan coba lagi nanti atau gunakan mode manual.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildDegraded(BuildContext context, String reason) {
    return Column(
      children: [
        const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
        const SizedBox(height: 16),
        Text(
          'AI degraded: $reason',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.orange),
        ),
      ],
    );
  }
}

class _AnimatedRobotIcon extends StatefulWidget {
  final bool isDownloading;

  const _AnimatedRobotIcon({required this.isDownloading});

  @override
  State<_AnimatedRobotIcon> createState() => _AnimatedRobotIconState();
}

class _AnimatedRobotIconState extends State<_AnimatedRobotIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isDownloading) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedRobotIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDownloading && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isDownloading && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isDownloading ? _pulseAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.isDownloading ? _rotateAnimation.value : 0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 40,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
