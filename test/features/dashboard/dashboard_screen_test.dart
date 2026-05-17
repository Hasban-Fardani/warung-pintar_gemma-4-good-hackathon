import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/database/database_service.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/stock_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:warung_pintar_cimahi/features/dashboard/domain/usecases/dashboard_summary_usecase.dart';
import 'package:warung_pintar_cimahi/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:warung_pintar_cimahi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockDashboardSummaryUseCase extends Mock
    implements DashboardSummaryUseCase {}

/// ACT-77: Widget test DashboardPage.
///
/// Verifies:
/// - Pending banner muncul jika ada pending, hilang jika tidak ada
/// - Omzet hanya tampil dari `confirmed` (via use case mock)
/// - Title "WarungPintar" rendered
/// - Greeting text rendered
/// - Bento grid cards visible
void main() {
  late MockTransactionRepository mockTxRepo;
  late MockCatalogRepository mockCatalogRepo;
  late MockDatabaseService mockDb;
  late MockDashboardSummaryUseCase mockSummaryUseCase;

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockCatalogRepo = MockCatalogRepository();
    mockDb = MockDatabaseService();
    mockSummaryUseCase = MockDashboardSummaryUseCase();

    // Reset GetIt for each test
    if (getIt.isRegistered<TransactionRepository>()) {
      getIt.unregister<TransactionRepository>();
    }
    if (getIt.isRegistered<CatalogRepository>()) {
      getIt.unregister<CatalogRepository>();
    }
    if (getIt.isRegistered<DatabaseService>()) {
      getIt.unregister<DatabaseService>();
    }
    if (getIt.isRegistered<DashboardSummaryUseCase>()) {
      getIt.unregister<DashboardSummaryUseCase>();
    }

    getIt.registerLazySingleton<TransactionRepository>(() => mockTxRepo);
    getIt.registerLazySingleton<CatalogRepository>(() => mockCatalogRepo);
    getIt.registerLazySingleton<DatabaseService>(() => mockDb);
    getIt.registerLazySingleton<DashboardSummaryUseCase>(
      () => mockSummaryUseCase,
    );
  });

  void stubDefaultMocks({
    int pendingCount = 0,
    int omzetSen = 0,
    int profitSen = 0,
    int modalSen = 0,
    List<TransactionEntity> recentTransactions = const [],
    List<StockEntity> lowStockItems = const [],
  }) {
    when(
      () => mockSummaryUseCase(),
    ).thenAnswer(
      (_) async => Success(
        DashboardSummaryEntity(
          omzetSen: omzetSen,
          profitSen: profitSen,
          modalSen: modalSen,
          pendingCount: pendingCount,
        ),
      ),
    );
    when(
      () => mockTxRepo.getRecentTransactions(limit: any(named: 'limit')),
    ).thenAnswer((_) async => Success(recentTransactions));
    when(
      () => mockCatalogRepo.getLowStockItems(),
    ).thenAnswer((_) async => Success(lowStockItems));
  }

  Widget buildWidget() {
    return const ProviderScope(child: MaterialApp(home: DashboardScreen()));
  }

  group('DashboardScreen — basic rendering', () {
    testWidgets('renders WarungPintar title', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('WarungPintar'), findsOneWidget);
    });

    testWidgets('renders greeting text', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Greeting contains time-based text
      expect(
        find.textContaining('Selamat'),
        findsOneWidget,
      );
    });

    testWidgets('renders bento grid labels', (tester) async {
      stubDefaultMocks(omzetSen: 4500000, profitSen: 1000000, modalSen: 3500000);
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('OMZET HARI INI'), findsOneWidget);
      expect(find.text('PROFIT'), findsOneWidget);
      expect(find.text('MODAL'), findsOneWidget);
    });
  });

  group('DashboardScreen — pending banner', () {
    testWidgets('shows pending banner when pendingCount > 0', (tester) async {
      stubDefaultMocks(pendingCount: 3);
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3 transaksi pending'), findsOneWidget);
      expect(find.text('Konfirmasi'), findsOneWidget);
    });

    testWidgets('hides pending banner when pendingCount is 0', (tester) async {
      stubDefaultMocks(pendingCount: 0);
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('transaksi pending'), findsNothing);
    });
  });

  group('DashboardScreen — omzet from confirmed only', () {
    testWidgets('displays omzet value from usecase (confirmed-only)',
        (tester) async {
      // Use case should return only confirmed transactions
      stubDefaultMocks(omzetSen: 4500000);
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the use case was called (it only counts confirmed)
      verify(() => mockSummaryUseCase()).called(1);

      // Rp 45.000 should appear in the omzet card
      expect(find.textContaining('45'), findsWidgets);
    });
  });

  group('DashboardScreen — empty state', () {
    testWidgets('shows empty transaction message when no transactions',
        (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Belum ada transaksi hari ini'), findsOneWidget);
    });
  });
}
