import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/utils/money_formatter.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';

class TransactionListTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;

  const TransactionListTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSell = transaction.type is TransactionSell;
    final iconBackground = isSell
        ? AppColors.primaryContainer
        : AppColors.errorContainer;
    final amountColor = isSell ? AppColors.secondary : AppColors.error;
    final icon = isSell
        ? Icons.shopping_cart_outlined
        : Icons.shopping_bag_outlined;
    final timeText = DateFormat('HH:mm', 'id').format(transaction.createdAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.onPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.itemName,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeText,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              MoneyFormatter.senToDisplay(transaction.amountSen),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: amountColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
