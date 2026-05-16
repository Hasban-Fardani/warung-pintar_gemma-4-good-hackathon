import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warung_pintar_cimahi/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen displays Dashboard Stub and FAB', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    expect(find.text('Dashboard Stub'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
