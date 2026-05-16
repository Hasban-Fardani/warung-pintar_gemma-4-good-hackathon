import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    // Auth redirect stub (always allow for dev mode)
    return null;
  },
  routes: [
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
              NavigationDestination(icon: Icon(Icons.home), label: 'Beranda'),
              NavigationDestination(icon: Icon(Icons.pending), label: 'Pending'),
              NavigationDestination(icon: Icon(Icons.list), label: 'Katalog'),
              NavigationDestination(icon: Icon(Icons.settings), label: 'Setelan'),
            ],
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'Home - Dashboard with Transactions & Toast',
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pending',
              builder: (context, state) => const Scaffold(body: Center(child: Text('Pending'))),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'Master Data Barang - List View',
              path: '/catalog',
              builder: (context, state) => const Scaffold(body: Center(child: Text('Katalog'))),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'Settings & Profil Usaha - Poppins Edition',
              path: '/settings',
              builder: (context, state) => const Scaffold(body: Center(child: Text('Setelan'))),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      name: 'Guided Onboarding - Welcome',
      path: '/guided-onboarding-welcome',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Guided Onboarding - Welcome'))),
    ),
    GoRoute(
      name: 'Guided Onboarding - Profile Setup',
      path: '/guided-onboarding-profile-setup',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Guided Onboarding - Profile Setup'))),
    ),
    GoRoute(
      name: 'Guided Onboarding - Initial Stock',
      path: '/guided-onboarding-initial-stock',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Guided Onboarding - Initial Stock'))),
    ),
    GoRoute(
      name: 'Guided Onboarding - Confirmation',
      path: '/guided-onboarding-confirmation',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Guided Onboarding - Confirmation'))),
    ),
    GoRoute(
      name: 'Onboarding - AI Processing',
      path: '/onboarding-ai-processing',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Onboarding - AI Processing'))),
    ),
    GoRoute(
      name: 'Input Transaksi - Manual Default',
      path: '/input-transaksi-manual-default',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Input Transaksi - Manual Default'))),
    ),
    GoRoute(
      name: 'Input Transaksi - Modern Error State',
      path: '/input-transaksi-modern-error-state',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Input Transaksi - Modern Error State'))),
    ),
    GoRoute(
      name: 'Input Transaksi - Voice Mode',
      path: '/input-transaksi-voice-mode',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Input Transaksi - Voice Mode'))),
    ),
    GoRoute(
      name: 'Master Data - Tambah Barang Form',
      path: '/master-data-tambah-barang-form',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Master Data - Tambah Barang Form'))),
    ),
    GoRoute(
      name: 'Update Stok - Kamera Mode',
      path: '/update-stok-kamera-mode',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Update Stok - Kamera Mode'))),
    ),
    GoRoute(
      name: 'Update Stok - Manual Input',
      path: '/update-stok-manual-input',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Update Stok - Manual Input'))),
    ),
    GoRoute(
      name: 'Update Stok - Voice Confirmation',
      path: '/update-stok-voice-confirmation',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Update Stok - Voice Confirmation'))),
    ),
    GoRoute(
      name: 'WarungPintar History & Analytics',
      path: '/warungpintar-history-analytics',
      builder: (context, state) => const Scaffold(body: Center(child: Text('WarungPintar History & Analytics'))),
    ),
  ],
);
