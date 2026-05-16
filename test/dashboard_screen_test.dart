import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/database/database_service.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/entities/stock_entity.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:warung_pintar_cimahi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockCatalogRepository extends Mock implements CatalogRepository {}
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockTransactionRepository mockTxRepo;
  late MockCatalogRepository mockCatalogRepo;
  late MockDatabaseService mockDb;

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockCatalogRepo = MockCatalogRepository();
    mockDb = MockDatabaseService();

    if (!getIt.isRegistered<TransactionRepository>()) {
      getIt.registerLazySingleton<TransactionRepository>(() => mockTxRepo);
    }
    if (!getIt.isRegistered<CatalogRepository>()) {
      getIt.registerLazySingleton<CatalogRepository>(() => mockCatalogRepo);
    }
    if (!getIt.isRegistered<DatabaseService>()) {
      getIt.registerLazySingleton<DatabaseService>(() => mockDb);
    }

    when(() => mockTxRepo.getRecentTransactions(limit: any(named: 'limit')))
        .thenAnswer((_) async => const Success(<TransactionEntity>[]));
    when(() => mockTxRepo.getPendingTransactions())
        .thenAnswer((_) async => const Success(<TransactionEntity>[]));
    when(() => mockCatalogRepo.getLowStockItems())
        .thenAnswer((_) async => const Success(<StockEntity>[]));
  });

  testWidgets('DashboardScreen renders WarungPintar title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('WarungPintar'), findsOneWidget);
  });
}
