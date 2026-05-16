import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

// TODO: Move DatabaseService to core/database/ in ACT-04
abstract class DatabaseService {
  Future<void> init();
}

@LazySingleton(as: DatabaseService)
class DatabaseServiceImpl implements DatabaseService {
  @override
  Future<void> init() async {
    // TODO: SQLite WAL mode setup in ACT-19
  }
}

