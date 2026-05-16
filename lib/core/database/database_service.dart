import 'package:injectable/injectable.dart';

/// Abstract database service interface.
/// Implementations handle SQLite setup, WAL mode, migrations.
abstract class DatabaseService {
  Future<void> init();
}

/// Stub implementation — full SQLite DDL in ACT-19.
@LazySingleton(as: DatabaseService)
class DatabaseServiceImpl implements DatabaseService {
  @override
  Future<void> init() async {
    // TODO: SQLite WAL mode + DDL setup in ACT-19
  }
}
