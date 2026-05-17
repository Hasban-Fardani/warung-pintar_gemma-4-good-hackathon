import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

/// Audit log drawer per PRD §9.4 (ACT-70).
///
/// Displays for each transaction:
/// - STT transcript (raw voice input)
/// - Raw AI JSON (Gemma output before parsing)
/// - Idempotency key
/// - Input method (voice / image / manual)
/// - Timestamp chain (capture → inference → insert → confirm)
class AuditLogDrawer extends StatelessWidget {
  final List<AuditLogEntry> entries;

  const AuditLogDrawer({
    super.key,
    required this.entries,
  });

  /// Show as a bottom sheet drawer from any screen.
  static void show(BuildContext context, List<AuditLogEntry> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => AuditLogDrawer._scrollable(
          entries: entries,
          controller: controller,
        ),
      ),
    );
  }

  static Widget _scrollable({
    required List<AuditLogEntry> entries,
    required ScrollController controller,
  }) {
    return Column(
      children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.history, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Audit Log',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Entries list
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada log audit',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 16),
                  itemBuilder: (_, index) {
                    final entry = entries[index];
                    return _AuditEntryCard(entry: entry);
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Use AuditLogDrawer.show() instead
  }
}

class _AuditEntryCard extends StatelessWidget {
  final AuditLogEntry entry;

  const _AuditEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action label + timestamp
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _actionColor(entry.action),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.action,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(entry.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Input method
          if (entry.inputMethod != null) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Input Method', value: entry.inputMethod!),
          ],

          // Idempotency key
          if (entry.idempotencyKey != null) ...[
            const SizedBox(height: 4),
            _InfoRow(label: 'Idempotency Key', value: entry.idempotencyKey!),
          ],

          // STT Transcript
          if (entry.rawInputSource != null &&
              entry.rawInputSource!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _SectionLabel(label: 'STT Transcript'),
            const SizedBox(height: 4),
            _CodeBlock(content: entry.rawInputSource!),
          ],

          // Raw AI JSON
          if (entry.aiRawOutput != null &&
              entry.aiRawOutput!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _SectionLabel(label: 'Raw AI JSON'),
            const SizedBox(height: 4),
            _CodeBlock(content: entry.aiRawOutput!),
          ],

          // State snapshot
          if (entry.stateSnapshot.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _SectionLabel(label: 'State Snapshot'),
            const SizedBox(height: 4),
            _CodeBlock(content: entry.stateSnapshot),
          ],
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    if (action.contains('CONFIRMED')) return AppColors.secondary;
    if (action.contains('CREATED')) return AppColors.primary;
    if (action.contains('EDITED')) return AppColors.tertiary;
    if (action.contains('DELETED')) return AppColors.error;
    if (action.contains('CLARIF')) return AppColors.pendingText;
    return AppColors.onSurfaceVariant;
  }

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m:$s';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String content;

  const _CodeBlock({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          content,
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            height: 16 / 11,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Data model for audit log entries (PRD §9.3).
class AuditLogEntry {
  final String id;
  final String transactionId;
  final String action;
  final String? rawInputSource;
  final String? aiRawOutput;
  final String stateSnapshot;
  final DateTime createdAt;

  // Extra fields for display
  final String? inputMethod;
  final String? idempotencyKey;

  const AuditLogEntry({
    required this.id,
    required this.transactionId,
    required this.action,
    this.rawInputSource,
    this.aiRawOutput,
    required this.stateSnapshot,
    required this.createdAt,
    this.inputMethod,
    this.idempotencyKey,
  });
}
