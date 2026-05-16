import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/onboarding/presentation/pages/model_download_screen.dart';
import '../ai/app_init_notifier.dart';
import '../ai/app_init_state.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// GoRouter configuration per PRD §4.1.
/// StatefulShellRoute for 4 bottom tabs with state preservation.
/// Deep linking ready.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    // Check app initialization state — redirect to model download if needed
    final container = ProviderScope.containerOf(context, listen: false);
    final appState = container.read(appInitProvider);

    final isOnModelDownload = state.matchedLocation == '/model-download';
    if (appState is AppInitModelDownloading && !isOnModelDownload) {
      return '/model-download';
    }

    // TODO: Check app_settings for first launch → redirect to /onboarding
    return null;
  },
  routes: [
    // ── Model Download (first launch, PRD §16.1.4) ──
    GoRoute(
      path: '/model-download',
      builder: (context, state) => const ModelDownloadScreen(),
    ),

    // ── Onboarding (first launch only, no bottom nav) ──
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Onboarding — Agent 1')),
      ),
    ),

    // ── Main Shell (4 bottom tabs) ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.pending_actions_outlined),
                selectedIcon: Icon(Icons.pending_actions),
                label: 'Pending',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Katalog',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Setelan',
              ),
            ],
          ),
        );
      },
      branches: [
        // Tab 1: Beranda (Dashboard) — Path: /
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        // Tab 2: Pending — Path: /pending
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pending',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Pending Review')),
              ),
            ),
          ],
        ),
        // Tab 3: Katalog — Path: /catalog
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/catalog',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Katalog Barang')),
              ),
            ),
          ],
        ),
        // Tab 4: Setelan — Path: /settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Setelan')),
              ),
            ),
          ],
        ),
      ],
    ),

    // ── Push routes (non-tab) ──
    GoRoute(
      path: '/item/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return Scaffold(
          body: Center(child: Text('Detail Barang: $id')),
        );
      },
    ),
    GoRoute(
      path: '/transaction/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return Scaffold(
          body: Center(child: Text('Detail Transaksi: $id')),
        );
      },
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Laporan & Histori')),
      ),
    ),
  ],
);
