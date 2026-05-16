import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/gemma_ai_service.dart';
import 'package:warung_pintar_cimahi/core/database/database_service.dart';

import 'package:warung_pintar_cimahi/core/voice/voice_service_impl.dart';
import 'package:warung_pintar_cimahi/features/transaction/data/datasources/audit_log_datasource.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() {
  getIt.init();

  // Manual registration — GemmaAiService is the only real impl (PRD §6.1).
  // No fake/mock services in production DI.
  if (!getIt.isRegistered<AiService>()) {
    getIt.registerLazySingleton<AiService>(() => GemmaAiService());
  }

  // Voice service — singleton (STT engine init is expensive).
  if (!getIt.isRegistered<VoiceService>()) {
    getIt.registerLazySingleton<VoiceService>(() => VoiceServiceImpl());
  }

  // Audit log datasource — depends on DatabaseService.
  if (!getIt.isRegistered<AuditLogDatasource>()) {
    getIt.registerLazySingleton<AuditLogDatasource>(
      () => AuditLogDatasource(getIt<DatabaseService>()),
    );
  }
}
