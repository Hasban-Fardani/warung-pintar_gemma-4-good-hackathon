import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/features/transaction/presentation/providers/voice_transaction_notifier.dart';

class VoiceInputPage extends ConsumerStatefulWidget {
  const VoiceInputPage({super.key});

  @override
  ConsumerState<VoiceInputPage> createState() => _VoiceInputPageState();
}

class _VoiceInputPageState extends ConsumerState<VoiceInputPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceTransactionProvider.notifier).startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceTransactionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(voiceTransactionProvider.notifier).stopListening();
            context.pop();
          },
        ),
        title: const Text('Catat Suara'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isListening
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceContainerHighest,
                  border: Border.all(
                    color: state.isListening
                        ? AppColors.primary
                        : AppColors.outline,
                    width: 3,
                  ),
                ),
                child: Icon(
                  state.isListening ? Icons.mic : Icons.mic_off,
                  size: 56,
                  color: state.isListening
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                state.isListening
                    ? 'Mendengarkan...'
                    : state.isProcessing
                        ? 'Memproses...'
                        : 'Tekan mic untuk mulai',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
              if (state.transcript.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Text(
                    state.transcript,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              if (state.resultMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.pendingBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.resultMessage!,
                    style: const TextStyle(color: AppColors.pendingText),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const Spacer(),
              if (state.resultMessage != null)
                FilledButton(
                  onPressed: () => context.go('/pending'),
                  child: const Text('Lihat Pending'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
