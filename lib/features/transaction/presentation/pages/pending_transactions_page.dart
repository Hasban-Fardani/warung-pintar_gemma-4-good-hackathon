import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/features/transaction/presentation/providers/pending_transactions_provider.dart';

class PendingTransactionsPage extends ConsumerStatefulWidget {
  const PendingTransactionsPage({super.key});

  @override
  ConsumerState<PendingTransactionsPage> createState() =>
      _PendingTransactionsPageState();
}

class _PendingTransactionsPageState
    extends ConsumerState<PendingTransactionsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(pendingTransactionsProvider.notifier).loadPending());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendingTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Transaksi Menunggu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.outlineVariant, height: 1),
        ),
      ),
      body: _buildBody(state),
      bottomNavigationBar: _buildBottomBar(state),
    );
  }

  Widget _buildBody(PendingTransactionsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(pendingTransactionsProvider.notifier).loadPending(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.batches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak ada transaksi pending',
                style: TextStyle(
                    fontSize: 16, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.pendingBackground,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Text(
            '${state.totalCount} transaksi belum dikonfirmasi',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.pendingText,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.batches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _PendingBatchCard(
                batch: state.batches[index],
                onConfirm: () => _confirmBatch(state.batches[index]),
                onDelete: () => _deleteBatch(state.batches[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(PendingTransactionsState state) {
    if (state.batches.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => context.push('/voice-confirm'),
                icon: const Icon(Icons.mic, size: 24),
                label: const Text(
                  'Konfirmasi Semua via Suara',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _confirmAll(),
                icon: const Icon(Icons.check, size: 20),
                label: Text(
                  'Setujui Semua (${state.totalCount})',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBatch(PendingBatch batch) async {
    await ref
        .read(pendingTransactionsProvider.notifier)
        .confirmBatch(batch.idempotencyKey);
  }

  Future<void> _deleteBatch(PendingBatch batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
            'Yakin ingin menghapus ${batch.items.length} transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(pendingTransactionsProvider.notifier)
          .deleteBatch(batch.idempotencyKey);
    }
  }

  Future<void> _confirmAll() async {
    await ref.read(pendingTransactionsProvider.notifier).confirmAllPending();
  }
}

class _PendingBatchCard extends StatelessWidget {
  final PendingBatch batch;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;

  const _PendingBatchCard({
    required this.batch,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final timeFormat = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.schedule,
                    size: 16, color: AppColors.pendingText),
                const SizedBox(width: 4),
                Text(
                  timeFormat.format(batch.createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.pendingText,
                  ),
                ),
                const Spacer(),
                Text(
                  '${batch.items.length} item',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...batch.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            '${item.quantity} × ${currencyFormat.format(item.priceAtTransactionSen ~/ 100)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.pendingBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.pendingText,
                        ),
                      ),
                      Text(
                        currencyFormat.format(batch.totalSen ~/ 100),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.pendingText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Hapus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Konfirmasi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
