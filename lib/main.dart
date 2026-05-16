import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ai/app_init_notifier.dart';
import 'core/database/database_service.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  configureDependencies();

  // Initialize database on startup
  final databaseService = getIt<DatabaseService>();
  await databaseService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger app initialization (model check, download, load)
    ref.listen(appInitProvider, (prev, next) {});
    ref.read(appInitProvider.notifier).initialize();

    return MaterialApp.router(
      title: 'WarungPintar',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
