import 'package:get_it/get_it.dart';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/gemma_ai_service.dart';
import 'package:warung_pintar_cimahi/core/database/database_service.dart';
import 'package:warung_pintar_cimahi/core/voice/voice_service_impl.dart';
import 'package:warung_pintar_cimahi/features/catalog/data/datasources/catalog_datasource.dart';
import 'package:warung_pintar_cimahi/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:warung_pintar_cimahi/features/transaction/data/datasources/audit_log_datasource.dart';
import 'package:warung_pintar_cimahi/features/transaction/data/datasources/transaction_datasource.dart';
import 'package:warung_pintar_cimahi/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/usecases/get_pending_transactions_usecase.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Services
  if (!getIt.isRegistered<AiService>()) {
    getIt.registerLazySingleton<AiService>(() => GemmaAiService());
  }
  if (!getIt.isRegistered<VoiceService>()) {
    getIt.registerLazySingleton<VoiceService>(() => VoiceServiceImpl());
  }
  if (!getIt.isRegistered<DatabaseService>()) {
    getIt.registerLazySingleton<DatabaseService>(() => DatabaseServiceImpl());
  }

  // Datasources
  if (!getIt.isRegistered<TransactionDatasource>()) {
    getIt.registerLazySingleton<TransactionDatasource>(
      () => TransactionDatasource(getIt<DatabaseService>()),
    );
  }
  if (!getIt.isRegistered<CatalogDatasource>()) {
    getIt.registerLazySingleton<CatalogDatasource>(
      () => CatalogDatasource(getIt<DatabaseService>()),
    );
  }
  if (!getIt.isRegistered<AuditLogDatasource>()) {
    getIt.registerLazySingleton<AuditLogDatasource>(
      () => AuditLogDatasource(getIt<DatabaseService>()),
    );
  }

  // Repositories
  if (!getIt.isRegistered<TransactionRepository>()) {
    getIt.registerLazySingleton<TransactionRepository>(
      () => TransactionRepositoryImpl(getIt<TransactionDatasource>()),
    );
  }
  if (!getIt.isRegistered<CatalogRepository>()) {
    getIt.registerLazySingleton<CatalogRepository>(
      () => CatalogRepositoryImpl(getIt<CatalogDatasource>()),
    );
  }

  // UseCases
  if (!getIt.isRegistered<GetPendingTransactionsUseCase>()) {
    getIt.registerLazySingleton<GetPendingTransactionsUseCase>(
      () => GetPendingTransactionsUseCase(getIt<TransactionRepository>()),
    );
  }
}
