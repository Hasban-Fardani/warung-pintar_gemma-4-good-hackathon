import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/features/transaction/presentation/providers/pending_transactions_provider.dart';
import 'package:warung_pintar_cimahi/features/transaction/presentation/widgets/waveform_widget.dart';

enum VoiceConfirmState { listening, processing, done }

class VoiceConfirmResult {
  final int confirmedCount;
  final int deletedCount;
  final int skippedCount;

  const VoiceConfirmResult({
    required this.confirmedCount,
    required this.deletedCount,
    required this.skippedCount,
  });
}

class VoiceConfirmPage extends ConsumerStatefulWidget {
  const VoiceConfirmPage({super.key});

  @override
  ConsumerState<VoiceConfirmPage> createState() => _VoiceConfirmPageState();
}

class _VoiceConfirmPageState extends ConsumerState<VoiceConfirmPage>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();

  VoiceConfirmState _state = VoiceConfirmState.listening;
  bool _isListening = false;
  bool _isInitialized = false;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _currentIndex = 0;

  int _confirmedCount = 0;
  int _deletedCount = 0;
  int _skippedCount = 0;

  List<PendingBatch> _batches = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _initializeAndStart();
  }

  Future<void> _initializeAndStart() async {
    final result = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) {},
    );

    if (!result) {
      _showError('Speech recognition not available');
      return;
    }

    setState(() => _isInitialized = true);

    await ref
        .read(pendingTransactionsProvider.notifier)
        .loadPending();
    final pendingState = ref.read(pendingTransactionsProvider);

    if (pendingState.batches.isEmpty) {
      context.pop();
      return;
    }

    _batches = pendingState.batches;
    _startListening();
  }

  void _startListening() {
    if (!_isInitialized || _currentIndex >= _batches.length) {
      _finish();
      return;
    }

    setState(() {
      _state = VoiceConfirmState.listening;
      _isListening = true;
      _elapsedSeconds = 0;
    });

    _startTimer();

    _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'id_ID',
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
    );
  }

  void _onSpeechStatus(String status) {
    if ((status == 'done' || status == 'notListening') &&
        _isListening &&
        mounted) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_isListening && _state == VoiceConfirmState.listening) {
          _restartListening();
        }
      });
    }
  }

  Future<void> _restartListening() async {
    if (!_isListening || !mounted) return;

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'id_ID',
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      _processCommand(result.recognizedWords);
    }
  }

  String _parseVoiceCommand(String transcript) {
    final t = transcript.toLowerCase();
    if (t.contains('semua benar') ||
        t.contains('semua iya') ||
        t.contains('setuju semua')) {
      return 'confirm_all';
    }
    if (t.contains('benar') ||
        t.contains('iya') ||
        t.contains('ya') ||
        t.contains('betul') ||
        t.contains('ok') ||
        t.contains('oke')) {
      return 'confirm';
    }
    if (t.contains('salah') ||
        t.contains('hapus') ||
        t.contains('batal') ||
        t.contains('tidak') ||
        t.contains('nggak')) {
      return 'delete';
    }
    if (t.contains('skip') || t.contains('lewat') || t.contains('selesai')) {
      return 'skip';
    }
    return 'unknown';
  }

  Future<void> _processCommand(String transcript) async {
    _stopListening();

    final command = _parseVoiceCommand(transcript);

    setState(() => _state = VoiceConfirmState.processing);

    switch (command) {
      case 'confirm':
        await _confirmCurrent();
        break;
      case 'delete':
        await _deleteCurrent();
        break;
      case 'skip':
        await _skipCurrent();
        break;
      case 'confirm_all':
        await _confirmAllRemaining();
        break;
      case 'unknown':
      default:
        _showUnknownAndContinue();
        return;
    }
  }

  Future<void> _confirmCurrent() async {
    final batch = _batches[_currentIndex];
    final notifier = ref.read(pendingTransactionsProvider.notifier);

    await notifier.confirmBatch(batch.idempotencyKey);

    setState(() => _confirmedCount++);
    _moveToNext();
  }

  Future<void> _deleteCurrent() async {
    final batch = _batches[_currentIndex];
    final notifier = ref.read(pendingTransactionsProvider.notifier);

    await notifier.deleteBatch(batch.idempotencyKey);

    setState(() => _deletedCount++);
    _moveToNext();
  }

  Future<void> _skipCurrent() async {
    setState(() => _skippedCount++);
    _moveToNext();
  }

  Future<void> _confirmAllRemaining() async {
    setState(() => _confirmedCount += _batches.length - _currentIndex);
    _finish();
  }

  void _showUnknownAndContinue() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _startListening();
      }
    });
  }

  void _moveToNext() {
    _currentIndex++;
    if (_currentIndex >= _batches.length) {
      _finish();
    } else {
      _startListening();
    }
  }

  void _finish() {
    _stopListening();
    setState(() => _state = VoiceConfirmState.done);
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _stopTimer();
    _speech.stop();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    context.pop();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () {
            _stopListening();
            context.pop();
          },
        ),
        title: const Text(
          'Konfirmasi via Suara',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.outlineVariant, height: 1),
        ),
      ),
      body: SafeArea(
        child: _state == VoiceConfirmState.done
            ? _buildDoneState()
            : _buildListeningState(),
      ),
    );
  }

  Widget _buildListeningState() {
    if (_currentIndex >= _batches.length) {
      return _buildDoneState();
    }

    final batch = _batches[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          FadeTransition(
            opacity: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Transaksi ${_currentIndex + 1} dari ${_batches.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...batch.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            '${item.quantity} × ${currencyFormat.format(item.priceAtTransactionSen ~/ 100)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      currencyFormat.format(batch.totalSen ~/ 100),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Katakan:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '"benar" / "iya" → konfirmasi',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
                Text(
                  '"salah" / "hapus" → hapus',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
                Text(
                  '"skip" → lewati',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
                Text(
                  '"semua benar" → konfirmasi semua',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FakeWaveformWidget(isListening: _isListening),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isListening) ...[
                const Icon(Icons.mic, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '⏱ ${_formatDuration(_elapsedSeconds)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteCurrent(),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Hapus Manual'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _skipCurrent(),
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: const Text('Skip'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _confirmCurrent(),
              icon: const Icon(Icons.check, size: 24),
              label: const Text(
                'Konfirmasi Manual',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 48,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Selesai!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                _ResultRow(
                  label: 'Dikonfirmasi',
                  value: '$_confirmedCount transaksi',
                  color: AppColors.secondary,
                ),
                const Divider(),
                _ResultRow(
                  label: 'Dihapus',
                  value: '$_deletedCount transaksi',
                  color: AppColors.error,
                ),
                const Divider(),
                _ResultRow(
                  label: 'Dilewati',
                  value: '$_skippedCount transaksi',
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => context.go('/'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
