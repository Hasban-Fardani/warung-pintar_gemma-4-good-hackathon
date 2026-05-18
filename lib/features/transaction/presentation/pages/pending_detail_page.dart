import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/utils/money_formatter.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/presentation/providers/pending_confirm_notifier.dart';

class PendingDetailPage extends ConsumerStatefulWidget {
  final String transactionId;

  const PendingDetailPage({super.key, required this.transactionId});

  @override
  ConsumerState<PendingDetailPage> createState() => _PendingDetailPageState();
}

class _PendingDetailPageState extends ConsumerState<PendingDetailPage> {
  TransactionEntity? _transaction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    // First, check the pendingConfirmProvider state
    final pendingState = ref.read(pendingConfirmProvider);
    final found = pendingState.items.where(
      (item) => item.id == widget.transactionId,
    );

    if (found.isNotEmpty) {
      setState(() {
        _transaction = found.first;
        _isLoading = false;
      });
      return;
    }

    // If not in provider state, load pending items and find it
    await ref.read(pendingConfirmProvider.notifier).loadPending();
    final updatedState = ref.read(pendingConfirmProvider);
    final refound = updatedState.items.where(
      (item) => item.id == widget.transactionId,
    );

    if (refound.isNotEmpty) {
      setState(() {
        _transaction = refound.first;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmThis(BuildContext context) async {
    await ref.read(pendingConfirmProvider.notifier).confirmSingle(
      widget.transactionId,
    );
    if (context.mounted) {
      context.pop();
    }
  }

  Future<void> _deleteThis(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Transaksi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(pendingConfirmProvider.notifier).deleteItem(
        widget.transactionId,
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi Pending'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        surfaceTintColor: AppColors.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
          ? const Center(child: Text('Transaksi tidak ditemukan'))
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final tx = _transaction!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailCard(transaction: tx),
          if (tx.rawInputSource != null) ...[
            const SizedBox(height: 24),
            _TranscriptCard(rawInputSource: tx.rawInputSource!),
          ],
          const SizedBox(height: 24),
          _AiOutputCard(aiRawOutput: tx.aiRawOutput),
          const SizedBox(height: 32),
          _ActionButtons(
            transactionId: tx.id,
            onConfirm: () => _confirmThis(context),
            onDelete: () => _deleteThis(context),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final TransactionEntity transaction;

  const _DetailCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isSell = transaction.type is TransactionSell;
    final inputLabel = switch (transaction.inputMethod) {
      InputVoice() => 'Suara',
      InputImage() => 'Foto',
      InputManual() => 'Manual',
    };
    final statusLabel = switch (transaction.status) {
      TransactionStatus.pending => 'Pending',
      TransactionStatus.confirmed => 'Terkonfirmasi',
      TransactionStatus.deleted => 'Dihapus',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  transaction.itemName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _TypeBadge(isSell: isSell),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Jumlah',
                  value: '${transaction.quantity}x',
                ),
              ),
              Expanded(
                child: _DetailField(
                  label: 'Harga Satuan',
                  value: MoneyFormatter.senToDisplay(
                    transaction.priceAtTransactionSen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Total',
                  value: MoneyFormatter.senToDisplay(transaction.amountSen),
                ),
              ),
              Expanded(
                child: _DetailField(
                  label: 'Waktu',
                  value: DateFormat('dd MMM yyyy HH:mm', 'id').format(
                    transaction.createdAt,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DetailField(label: 'Input', value: inputLabel),
              ),
              Expanded(
                child: _DetailField(label: 'Status', value: statusLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isSell;

  const _TypeBadge({required this.isSell});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSell
            ? AppColors.secondaryContainer
            : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isSell ? 'Jual' : 'Beli',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSell
              ? AppColors.onSecondaryContainer
              : AppColors.onErrorContainer,
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  final String rawInputSource;

  const _TranscriptCard({required this.rawInputSource});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Transcript Suara',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rawInputSource,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiOutputCard extends StatelessWidget {
  final String? aiRawOutput;

  const _AiOutputCard({required this.aiRawOutput});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            const Icon(
              Icons.code,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Raw AI Output',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        collapsedBackgroundColor: AppColors.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SelectableText(
              aiRawOutput ?? 'Tidak tersedia',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final String transactionId;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;

  const _ActionButtons({
    required this.transactionId,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/transaction/edit/$transactionId'),
            icon: const Icon(Icons.edit, size: 20),
            label: const Text(
              'Edit Manual',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check, size: 24),
            label: const Text(
              'Konfirmasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.error,
            ),
            label: const Text(
              'Hapus Transaksi',
              style: TextStyle(fontSize: 16, color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}
