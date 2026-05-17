import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:warung_pintar_cimahi/shared/widgets/audit_log_drawer.dart';

/// ACT-78: Widget test AuditLogDrawer.
///
/// Verifies:
/// - STT transcript + raw JSON tampil
/// - Entries rendered
/// - Empty state shown when no entries
void main() {
  group('AuditLogDrawer — static show method', () {
    testWidgets('shows drawer with entries', (tester) async {
      final entries = [
        AuditLogEntry(
          id: 'audit-001',
          transactionId: 'tx-001',
          action: 'CREATED_BY_AI_VOICE',
          rawInputSource: 'Jual beras 3 kilo 45 ribu',
          aiRawOutput:
              '{"name":"record_transactions","arguments":{"transactions":[{"item_name":"Beras","quantity":3}]}}',
          stateSnapshot: '{"status":"pending","item":"Beras"}',
          createdAt: DateTime(2026, 5, 17, 10, 30),
          inputMethod: 'voice',
          idempotencyKey: 'idem-key-001',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AuditLogDrawer.show(context, entries),
                child: const Text('Open Drawer'),
              ),
            ),
          ),
        ),
      );

      // Tap to open drawer
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Audit Log'), findsOneWidget);

      // Verify action label
      expect(find.text('CREATED_BY_AI_VOICE'), findsOneWidget);

      // Verify STT Transcript section
      expect(find.text('STT Transcript'), findsOneWidget);
      expect(
        find.text('Jual beras 3 kilo 45 ribu'),
        findsOneWidget,
      );

      // Verify Raw AI JSON section
      expect(find.text('Raw AI JSON'), findsOneWidget);
      expect(find.textContaining('record_transactions'), findsOneWidget);

      // Verify input method
      expect(find.text('Input Method'), findsOneWidget);
      expect(find.text('voice'), findsOneWidget);

      // Verify idempotency key
      expect(find.text('Idempotency Key'), findsOneWidget);
      expect(find.text('idem-key-001'), findsOneWidget);
    });

    testWidgets('shows empty state when no entries', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AuditLogDrawer.show(context, []),
                child: const Text('Open Drawer'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Audit Log'), findsOneWidget);
      expect(find.text('Belum ada log audit'), findsOneWidget);
    });
  });
}
