import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:warung_pintar_cimahi/core/ai/app_init_notifier.dart';
import 'package:warung_pintar_cimahi/core/ai/app_init_state.dart';
import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/constant/app_strings.dart';
import 'package:warung_pintar_cimahi/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/shared/widgets/ai_aware_fab.dart';
import 'package:warung_pintar_cimahi/shared/widgets/ai_degraded_banner.dart';
import 'package:warung_pintar_cimahi/shared/widgets/ai_loading_banner.dart';
import 'package:warung_pintar_cimahi/shared/widgets/pending_banner.dart';
import 'package:warung_pintar_cimahi/shared/widgets/permanent_manual_mode_banner.dart';
import 'package:warung_pintar_cimahi/shared/widgets/status_badge.dart';

/// Dashboard — Beranda screen (ACT-62 + ACT-69).
///
/// Full implementation per `docs/design/Home - Dashboard with Transactions & Toast.html`.
/// Integrates:
/// - TopAppBar: storefront icon, title, AI status dot
/// - AI banners stack: PermanentManualMode → AiDegraded → AiLoading
/// - Low stock alert banner
/// - Pending banner (reactive)
/// - Bento grid: Omzet (col-span-2), Profit, Modal Keluar
/// - Recent transactions list with status badges
/// - AI-aware FAB
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).loadSummary());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final appState = ref.watch(appInitProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(appState),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(state, appState),
      floatingActionButton: AiAwareFab(
        onVoiceTap: () {
          // TODO: Navigate to voice input
        },
        onCameraTap: () {
          // TODO: Show camera bottom sheet (struk / kemasan)
        },
        onManualTap: () {
          // TODO: Navigate to manual form
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppInitState appState) {
    final isAiReady = appState is AppInitModelReady;
    final isAiDegraded = appState is AppInitAiDegraded;
    final isAiFailed = appState is AppInitModelFailed;

    // AI status dot color
    Color dotColor;
    if (isAiReady) {
      dotColor = AppColors.secondary; // Green — ready
    } else if (isAiDegraded || isAiFailed) {
      dotColor = AppColors.error; // Red — failed/degraded
    } else {
      dotColor = AppColors.pendingText; // Yellow — loading
    }

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      ref.read(dashboardProvider.notifier).loadSummary(),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.storefront,
                      color: AppColors.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  AppStrings.appName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 28 / 20,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.smart_toy,
                        color: AppColors.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(DashboardState state, AppInitState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner stack (PRD §16 — ACT-69):
          // PermanentManualModeBanner → AiDegradedBanner → AiLoadingBanner
          _buildAiBanners(appState),

          // Low stock alert banner
          if (state.lowStockItems.isNotEmpty) ...[
            _buildLowStockBanner(state),
            const SizedBox(height: 16),
          ],

          // Pending banner (ACT-63)
          if (state.pendingCount > 0) ...[
            PendingBanner(
              pendingCount: state.pendingCount,
              onConfirmTap: () => context.go('/pending'),
            ),
            const SizedBox(height: 16),
          ],

          // Greeting
          _buildGreeting(),
          const SizedBox(height: 24),

          // Bento grid
          _buildBentoGrid(state),
          const SizedBox(height: 24),

          // Recent transactions
          _buildTransactionList(state),
        ],
      ),
    );
  }

  /// AI banners stack per ACT-69.
  /// Order: PermanentManualMode → AiDegraded → AiLoading.
  /// Only one shows at a time (mutually exclusive states).
  Widget _buildAiBanners(AppInitState appState) {
    return switch (appState) {
      AppInitModelFailed(:final reason) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: PermanentManualModeBanner(reason: reason),
      ),
      AppInitAiDegraded(:final reason) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AiDegradedBanner(
          reason: reason,
          onRetry: () => ref.read(appInitProvider.notifier).initialize(),
        ),
      ),
      AppInitModelLoading() => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: AiLoadingBanner(),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildLowStockBanner(DashboardState state) {
    final names = state.lowStockItems.take(3).map((e) => e.itemName).join(', ');
    final suffix = state.lowStockItems.length > 3 ? ', ...' : '';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        border: Border.all(color: AppColors.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Perhatian: Stok Menipis ($names$suffix)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 20 / 14,
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 10) {
      greeting = 'Selamat Pagi';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, Ibu Warsih',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 28 / 20,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cek performa warung Anda hari ini.',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 24 / 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid(DashboardState state) {
    return Column(
      children: [
        // Omzet Hari Ini (col-span-2)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.payments,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'OMZET HARI INI',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 20 / 14,
                      letterSpacing: 0.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatRupiah(state.omzetSen),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: AppColors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Profit & Modal (2 columns)
        Row(
          children: [
            // Profit
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PROFIT',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 16 / 12,
                              letterSpacing: 0.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRupiah(state.profitSen),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 28 / 20,
                        color: AppColors.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Modal Keluar
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.outbound,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'MODAL',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 16 / 12,
                              letterSpacing: 0.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRupiah(state.modalSen),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 28 / 20,
                        color: AppColors.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionList(DashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaksi Terakhir',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 28 / 20,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (state.recentTransactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Belum ada transaksi hari ini',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(state.recentTransactions.length, (i) {
                  final tx = state.recentTransactions[i];
                  final isLast = i == state.recentTransactions.length - 1;
                  return _transactionRow(tx, isLast);
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _transactionRow(TransactionEntity tx, bool isLast) {
    final isSell = tx.type is TransactionSell;
    final icon = isSell ? Icons.shopping_bag : Icons.receipt_long;
    final bgColor = isSell
        ? AppColors.primaryContainer
        : AppColors.errorContainer;
    final amountColor = isSell ? AppColors.secondary : AppColors.error;
    final sign = isSell ? '+' : '-';

    // Pending amounts show tilde prefix (PRD §12.7)
    final isPending = tx.status == TransactionStatus.pending;
    final prefix = isPending ? '~' : '';

    final timeDiff = DateTime.now().difference(tx.createdAt);
    String timeAgo;
    if (timeDiff.inMinutes < 1) {
      timeAgo = 'Baru saja';
    } else if (timeDiff.inMinutes < 60) {
      timeAgo = '${timeDiff.inMinutes} menit yang lalu';
    } else if (timeDiff.inHours < 24) {
      timeAgo = '${timeDiff.inHours} jam yang lalu';
    } else {
      timeAgo = '${timeDiff.inDays} hari yang lalu';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          // Icon circle 40×40
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: isSell ? AppColors.primary : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Name + time + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.itemName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 20 / 16,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 18 / 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                // Status badges (ACT-64)
                Row(
                  children: [
                    StatusBadge.inputMethod(tx.inputMethod),
                    const SizedBox(width: 4),
                    StatusBadge.transactionStatus(
                      tx.status,
                      needsClarification: tx.needsClarification,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '$prefix$sign${_formatCompactRupiah(tx.amountSen)}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 20 / 16,
              color: amountColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(int sen) {
    final rupiah = sen ~/ 100;
    return 'Rp ${NumberFormat.decimalPattern('id').format(rupiah)}';
  }

  String _formatCompactRupiah(int sen) {
    final rupiah = sen ~/ 100;
    if (rupiah >= 1000000) {
      final juta = rupiah / 1000000;
      return 'Rp${juta.toStringAsFixed(juta == juta.roundToDouble() ? 0 : 1)}jt';
    }
    return 'Rp${NumberFormat.decimalPattern('id').format(rupiah)}';
  }
}
