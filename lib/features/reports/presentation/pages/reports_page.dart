import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/theme/app_theme.dart';
import 'package:warung_pintar_cimahi/core/utils/money_formatter.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/shared/widgets/app_top_bar.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  int _periodIndex = 0;
  final _searchController = TextEditingController();
  final _categories = ['Semua', 'Sembako', 'Minuman', 'Snack', 'Rokok'];
  String _selectedCategory = 'Semua';

  final _barData = [120.0, 95.0, 150.0, 80.0, 135.0, 110.0, 145.0];
  final _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Riwayat & Analisis'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.marginPage,
          AppTheme.stackSm,
          AppTheme.marginPage,
          80,
        ),
        children: [
          _PeriodToggle(
            selectedIndex: _periodIndex,
            onChanged: (i) => setState(() => _periodIndex = i),
          ),
          const SizedBox(height: AppTheme.stackMd),
          _RevenueChart(barData: _barData, dayLabels: _dayLabels),
          const SizedBox(height: AppTheme.stackMd),
          const _QuickStats(),
          const SizedBox(height: AppTheme.stackMd),
          _SearchAndFilter(
            searchController: _searchController,
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategoryChanged: (c) => setState(() => _selectedCategory = c),
          ),
          const SizedBox(height: AppTheme.stackSm),
          const _TransactionList(),
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _PeriodToggle({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = ['Harian', 'Mingguan', 'Bulanan'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                height: AppTheme.touchTargetMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.surfaceVariant
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                foregroundDecoration: isActive
                    ? const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      )
                    : null,
                child: Text(
                  labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<double> barData;
  final List<String> dayLabels;

  const _RevenueChart({required this.barData, required this.dayLabels});

  @override
  Widget build(BuildContext context) {
    final maxY = (barData.reduce((a, b) => a > b ? a : b) / 50).ceil() * 50.0;
    final step = maxY / 3;

    return Container(
      padding: const EdgeInsets.all(AppTheme.marginPage),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendapatan',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.stackMd),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayLabels[idx],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return Text(
                            '0',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          );
                        }
                        final val = (value * 100).toInt();
                        if (val >= 100000) {
                          return Text(
                            'Rp${(val ~/ 1000)}rb',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          );
                        }
                        return Text(
                          'Rp${(val ~/ 1000)}rb',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: step,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.outlineVariant.withAlpha(100),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(barData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: barData[i],
                        color: const Color(0xFF1976D2),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.marginPage),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        children: [
          const Expanded(
            child: _StatItem(label: 'Produk Terlaris', value: 'Mie Instant'),
          ),
          Container(width: 1, height: 48, color: AppColors.outlineVariant),
          const Expanded(
            child: _StatItem(label: 'Rata-rata Transaksi', value: 'Rp 45.000'),
          ),
          Container(width: 1, height: 48, color: AppColors.outlineVariant),
          const Expanded(
            child: _StatItem(label: 'Total Transaksi', value: '128'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const _SearchAndFilter({
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Cari transaksi...',
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.marginPage,
              vertical: 12,
            ),
            isDense: true,
          ),
          style: GoogleFonts.inter(fontSize: 16),
        ),
        const SizedBox(height: AppTheme.stackSm),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isActive = cat == selectedCategory;
              return GestureDetector(
                onTap: () => onCategoryChanged(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryContainer
                        : Colors.transparent,
                    border: Border.all(
                      color: isActive
                          ? AppColors.primaryContainer
                          : AppColors.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList();

  @override
  Widget build(BuildContext context) {
    const transactions = [
      _TransactionItemData(
        name: 'Mie Instant Goreng',
        qty: 10,
        timestamp: 'Hari ini, 10:30',
        type: TransactionSell(),
        amountSen: 2500000,
      ),
      _TransactionItemData(
        name: 'Minyak Goreng 1L',
        qty: 5,
        timestamp: 'Hari ini, 09:15',
        type: TransactionBuy(),
        amountSen: 8750000,
      ),
      _TransactionItemData(
        name: 'Gula Pasir 1kg',
        qty: 20,
        timestamp: 'Kemarin, 14:20',
        type: TransactionSell(),
        amountSen: 2600000,
      ),
      _TransactionItemData(
        name: 'Beras 5kg',
        qty: 3,
        timestamp: 'Kemarin, 11:00',
        type: TransactionBuy(),
        amountSen: 4500000,
      ),
      _TransactionItemData(
        name: 'Telur 1kg',
        qty: 15,
        timestamp: '2 hari lalu, 16:45',
        type: TransactionSell(),
        amountSen: 4500000,
      ),
      _TransactionItemData(
        name: 'Kopi Sachet',
        qty: 50,
        timestamp: '2 hari lalu, 08:30',
        type: TransactionSell(),
        amountSen: 1250000,
      ),
      _TransactionItemData(
        name: 'Sabun Mandi',
        qty: 12,
        timestamp: '3 hari lalu, 10:00',
        type: TransactionBuy(),
        amountSen: 1800000,
      ),
    ];

    return Column(
      children: transactions.map((tx) => _TransactionCard(data: tx)).toList(),
    );
  }
}

class _TransactionItemData {
  final String name;
  final int qty;
  final String timestamp;
  final TransactionType type;
  final int amountSen;

  const _TransactionItemData({
    required this.name,
    required this.qty,
    required this.timestamp,
    required this.type,
    required this.amountSen,
  });
}

class _TransactionCard extends StatelessWidget {
  final _TransactionItemData data;

  const _TransactionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isSell = data.type is TransactionSell;
    final amountColor = isSell ? AppColors.secondary : AppColors.error;
    final badgeColor = isSell
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    final badgeTextColor = isSell
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final badgeLabel = isSell ? 'Jual' : 'Beli';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.stackSm),
      padding: const EdgeInsets.all(AppTheme.marginPage),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.name} x${data.qty}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      data.timestamp,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            MoneyFormatter.senToDisplay(data.amountSen),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
