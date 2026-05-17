/// Dashboard summary data — pure Dart, zero Flutter dependency.
///
/// PRD §7.2: Omzet hanya dari transaksi `status = confirmed`.
class DashboardSummaryEntity {
  final int omzetSen;
  final int profitSen;
  final int modalSen;
  final int pendingCount;

  const DashboardSummaryEntity({
    this.omzetSen = 0,
    this.profitSen = 0,
    this.modalSen = 0,
    this.pendingCount = 0,
  });
}
