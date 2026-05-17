import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalog/presentation/pages/catalog_list_page.dart';
import '../../features/catalog/presentation/pages/category_management_page.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_welcome_page.dart';
import '../../features/onboarding/presentation/pages/model_download_screen.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transaction/presentation/pages/pending_review_page.dart';
import '../../features/transaction/presentation/pages/voice_input_page.dart';
import '../../features/transaction/presentation/pages/transaction_form_page.dart';
import '../../features/vision/presentation/pages/receipt_capture_page.dart';
import '../../features/vision/presentation/pages/product_capture_page.dart';
import '../ai/app_init_notifier.dart';
import '../ai/app_init_state.dart';
import '../../shared/widgets/expandable_fab.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context, listen: false);
    final appState = container.read(appInitProvider);

    final isOnModelDownload = state.matchedLocation == '/model-download';
    if (appState is AppInitModelDownloading && !isOnModelDownload) {
      return '/model-download';
    }

    final isOnOnboarding = state.matchedLocation == '/onboarding';
    if (appState is AppInitModelReady &&
        !isOnOnboarding &&
        !isOnModelDownload) {}

    return null;
  },
  routes: [
    GoRoute(
      path: '/model-download',
      builder: (context, state) => const ModelDownloadScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingWelcomePage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Consumer(
          builder: (context, ref, _) {
            return Scaffold(
              body: navigationShell,
              bottomNavigationBar: SizedBox(
                height: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    NavigationBar(
                      selectedIndex: navigationShell.currentIndex,
                      onDestinationSelected: (index) {
                        navigationShell.goBranch(
                          index,
                          initialLocation: index == navigationShell.currentIndex,
                        );
                      },
                      height: 64,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: 'Beranda',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.assessment_outlined),
                          selectedIcon: Icon(Icons.assessment),
                          label: 'Rekap',
                        ),
                      ],
                    ),
                    const Positioned(
                      top: -28,
                      child: ExpandableFab(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/catalog',
              builder: (context, state) => const CatalogListPage(),
            ),
            GoRoute(
              path: '/category-management',
              builder: (context, state) => const CategoryManagementPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/pending',
      builder: (context, state) => const PendingReviewPage(),
    ),
    GoRoute(
      path: '/voice-input',
      builder: (context, state) => const VoiceInputPage(),
    ),
    GoRoute(
      path: '/transaction/new',
      builder: (context, state) => const TransactionFormPage(),
    ),
    GoRoute(
      path: '/receipt-capture',
      builder: (context, state) => const ReceiptCapturePage(),
    ),
    GoRoute(
      path: '/product-capture',
      builder: (context, state) => const ProductCapturePage(),
    ),
    GoRoute(
      path: '/item/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return Scaffold(body: Center(child: Text('Detail Barang: $id')));
      },
    ),
    GoRoute(
      path: '/transaction/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return Scaffold(body: Center(child: Text('Detail Transaksi: $id')));
      },
    ),
  ],
);
