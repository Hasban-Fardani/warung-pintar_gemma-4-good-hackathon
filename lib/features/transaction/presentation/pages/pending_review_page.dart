import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/constant/app_strings.dart';
import 'package:warung_pintar_cimahi/core/utils/money_formatter.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/presentation/providers/pending_confirm_notifier.dart';

class PendingReviewPage extends ConsumerWidget {
  const PendingReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingConfirmProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Pending Review',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.outlineVariant, height: 1),
        ),
      ),
      body: switch (state) {
        PendingConfirmState(isProcessing: true, items: []) => const Center(
          child: CircularProgressIndicator(),
        ),
        PendingConfirmState(error: final error?) => _buildError(
          context,
          ref,
          error,
        ),
        PendingConfirmState(items: []) => _buildEmpty(context),
        _ => _buildList(context, ref, state),
      },
      floatingActionButton: state.items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.read(pendingConfirmProvider.notifier).confirmAll();
              },
              icon: const Icon(Icons.mic),
              label: const Text('Konfirmasi via Suara'),
            )
          : null,
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(pendingConfirmProvider.notifier).loadPending();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.onSurfaceVariant.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada transaksi pending',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    PendingConfirmState state,
  ) {
    final totalPending = state.items.fold<int>(
      0,
      (sum, item) => sum + item.amountSen,
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.pendingBackground,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              Text(
                '${state.items.length} transaksi pending',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.pendingText),
              ),
              const Spacer(),
              Text(
                MoneyFormatter.senToPendingDisplay(totalPending),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.pendingText,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _PendingTransactionItem(item: item);
            },
          ),
        ),
      ],
    );
  }
}

class _PendingTransactionItem extends StatelessWidget {
  final TransactionEntity item;

  const _PendingTransactionItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final isSell = item.type is TransactionSell;

    return InkWell(
      onTap: () => context.push('/pending/${item.id}'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSell
                    ? AppColors.primaryContainer
                    : AppColors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSell
                    ? Icons.shopping_cart_outlined
                    : Icons.shopping_bag_outlined,
                size: 20,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.itemName,
                          style: Theme.of(context).textTheme.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TypeBadge(isSell: isSell),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusBadge(item: item),
                      const SizedBox(width: 8),
                      _MethodBadge(item: item),
                      if (item.quantity > 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${item.quantity}x',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  MoneyFormatter.senToPendingDisplay(item.amountSen),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSell ? AppColors.secondary : AppColors.error,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('HH:mm', 'id').format(item.createdAt),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
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

class _TypeBadge extends StatelessWidget {
  final bool isSell;

  const _TypeBadge({required this.isSell});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSell ? AppColors.secondaryContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isSell ? 'Jual' : 'Beli',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: 11,
          color: isSell
              ? AppColors.onSecondaryContainer
              : AppColors.onErrorContainer,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TransactionEntity item;

  const _StatusBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final isClarify = item.needsClarification;
    final bgColor = isClarify
        ? AppColors.errorContainer
        : AppColors.pendingBackground;
    final textColor = isClarify ? AppColors.error : AppColors.pendingText;
    final label = isClarify
        ? AppStrings.needsClarification
        : AppStrings.pending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isClarify ? Icons.help_outline : Icons.schedule,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontSize: 11, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final TransactionEntity item;

  const _MethodBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;

    if (item.inputMethod is InputVoice) {
      icon = Icons.mic;
      label = AppStrings.inputVoice;
    } else if (item.inputMethod is InputImage) {
      icon = Icons.camera_alt_outlined;
      label = AppStrings.inputImage;
    } else {
      icon = Icons.keyboard;
      label = AppStrings.inputManual;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
