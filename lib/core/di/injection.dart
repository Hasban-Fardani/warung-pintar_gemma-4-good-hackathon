import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/gemma_ai_service.dart';

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
}
