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
import 'package:warung_pintar_cimahi/features/transaction/domain/usecases/confirm_transaction_usecase.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/usecases/get_pending_transactions_usecase.dart';
import 'package:warung_pintar_cimahi/features/transaction/domain/usecases/record_voice_transaction_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/add_category_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/add_item_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/delete_category_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/get_catalog_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/get_categories_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/soft_delete_item_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/update_category_usecase.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/usecases/update_item_price_usecase.dart';
import 'package:warung_pintar_cimahi/features/dashboard/domain/usecases/dashboard_summary_usecase.dart';
import 'package:warung_pintar_cimahi/features/vision/domain/usecases/parse_product_usecase.dart';
import 'package:warung_pintar_cimahi/features/vision/domain/usecases/parse_receipt_usecase.dart';

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
  if (!getIt.isRegistered<ConfirmTransactionUseCase>()) {
    getIt.registerLazySingleton<ConfirmTransactionUseCase>(
      () => ConfirmTransactionUseCase(
        getIt<AiService>(),
        getIt<TransactionRepository>(),
      ),
    );
  }
  if (!getIt.isRegistered<GetPendingTransactionsUseCase>()) {
    getIt.registerLazySingleton<GetPendingTransactionsUseCase>(
      () => GetPendingTransactionsUseCase(getIt<TransactionRepository>()),
    );
  }
  if (!getIt.isRegistered<RecordVoiceTransactionUseCase>()) {
    getIt.registerLazySingleton<RecordVoiceTransactionUseCase>(
      () => RecordVoiceTransactionUseCase(
        getIt<AiService>(),
        getIt<TransactionRepository>(),
      ),
    );
  }
  if (!getIt.isRegistered<DashboardSummaryUseCase>()) {
    getIt.registerLazySingleton<DashboardSummaryUseCase>(
      () => DashboardSummaryUseCase(getIt<TransactionRepository>()),
    );
  }

  // Category use cases
  if (!getIt.isRegistered<GetCategoriesUseCase>()) {
    getIt.registerLazySingleton<GetCategoriesUseCase>(
      () => GetCategoriesUseCase(getIt<CatalogRepository>()),
    );
  }
  if (!getIt.isRegistered<AddCategoryUseCase>()) {
    getIt.registerLazySingleton<AddCategoryUseCase>(
      () => AddCategoryUseCase(getIt<CatalogRepository>()),
    );
  }
  if (!getIt.isRegistered<UpdateCategoryUseCase>()) {
    getIt.registerLazySingleton<UpdateCategoryUseCase>(
      () => UpdateCategoryUseCase(getIt<CatalogRepository>()),
    );
  }
  if (!getIt.isRegistered<DeleteCategoryUseCase>()) {
    getIt.registerLazySingleton<DeleteCategoryUseCase>(
      () => DeleteCategoryUseCase(getIt<CatalogRepository>()),
    );
  }

  // Catalog use cases
  if (!getIt.isRegistered<AddItemUseCase>()) {
    getIt.registerLazySingleton<AddItemUseCase>(
      () => AddItemUseCase(getIt<CatalogRepository>()),
    );
  }
  if (!getIt.isRegistered<UpdateItemPriceUseCase>()) {
    getIt.registerLazySingleton<UpdateItemPriceUseCase>(
      () => UpdateItemPriceUseCase(getIt<CatalogRepository>()),
    );
  }
  if (!getIt.isRegistered<GetCatalogUseCase>()) {
    getIt.registerLazySingleton<GetCatalogUseCase>(
      () => GetCatalogUseCase(getIt<CatalogRepository>()),
    );
  }
  if (!getIt.isRegistered<SoftDeleteItemUseCase>()) {
    getIt.registerLazySingleton<SoftDeleteItemUseCase>(
      () => SoftDeleteItemUseCase(getIt<CatalogRepository>()),
    );
  }

  // Vision use cases
  if (!getIt.isRegistered<ParseReceiptUseCase>()) {
    getIt.registerLazySingleton<ParseReceiptUseCase>(
      () => ParseReceiptUseCase(
        getIt<AiService>(),
        getIt<TransactionRepository>(),
      ),
    );
  }
  if (!getIt.isRegistered<ParseProductUseCase>()) {
    getIt.registerLazySingleton<ParseProductUseCase>(
      () => ParseProductUseCase(
        getIt<AiService>(),
        getIt<CatalogRepository>(),
      ),
    );
  }
}
