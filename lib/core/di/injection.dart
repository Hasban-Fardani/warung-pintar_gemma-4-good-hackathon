import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

abstract class AiService {
  Future<dynamic> infer({
    required String systemPrompt,
    required String userInput,
    String? imageBase64,
  });
}

abstract class DatabaseService {
  Future<void> init();
}

@LazySingleton(as: DatabaseService)
class DatabaseServiceImpl implements DatabaseService {
  @override
  Future<void> init() async {
    // SQLite WAL mode placeholder
  }
}
