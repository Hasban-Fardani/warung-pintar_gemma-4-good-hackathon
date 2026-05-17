import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/core/voice/voice_init_result.dart';
import 'package:warung_pintar_cimahi/core/voice/voice_service_impl.dart';
import 'package:warung_pintar_cimahi/features/transaction/presentation/widgets/waveform_widget.dart';
import 'package:intl/intl.dart';

enum VoiceInputState { idle, listening, processing, result, error }

class DraftTransactionItem {
  final String name;
  final int quantity;
  final int priceSen;

  const DraftTransactionItem({
    required this.name,
    required this.quantity,
    required this.priceSen,
  });

  String get priceDisplay => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(priceSen ~/ 100);
}

class VoiceInputPage extends ConsumerStatefulWidget {
  const VoiceInputPage({super.key});

  @override
  ConsumerState<VoiceInputPage> createState() => _VoiceInputPageState();
}

class _VoiceInputPageState extends ConsumerState<VoiceInputPage>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _transcriptController = TextEditingController();

  VoiceInputState _state = VoiceInputState.idle;
  bool _isUserStillRecording = false;
  bool _isInitialized = false;
  String _fullTranscript = '';
  Timer? _timer;
  int _elapsedSeconds = 0;
  String? _errorMessage;
  List<DraftTransactionItem> _draftItems = [];
  int _totalSen = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String get _formattedDuration {
    final minutes = _elapsedSeconds ~/ 60;
    final secs = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

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
    final voiceService = getIt<VoiceService>();
    final initResult = await voiceService.initialize();

    if (initResult is! VoiceInitSuccess) {
      setState(() {
        _state = VoiceInputState.error;
        _errorMessage = 'Speech recognition not available';
      });
      return;
    }

    setState(() => _isInitialized = true);
    await _startListening();
  }

  Future<void> _startListening() async {
    if (!_isInitialized) return;

    setState(() {
      _state = VoiceInputState.listening;
      _isUserStillRecording = true;
      _fullTranscript = '';
      _transcriptController.clear();
      _elapsedSeconds = 0;
      _errorMessage = null;
      _draftItems = [];
      _totalSen = 0;
    });

    _startTimer();

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 4),
      localeId: 'id_ID',
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      _appendTranscript(result.recognizedWords);
    } else {
      _transcriptController.text = _fullTranscript + result.recognizedWords;
    }
  }

  Future<void> _restartListening() async {
    if (!_isUserStillRecording || !mounted || !_isInitialized) return;

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 4),
      localeId: 'id_ID',
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
    );
  }

  void _appendTranscript(String words) {
    if (_fullTranscript.isNotEmpty) {
      _fullTranscript += ' ';
    }
    _fullTranscript += words;
    _transcriptController.text = _fullTranscript;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
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

  Future<void> _stopAndProcess() async {
    _isUserStillRecording = false;
    _stopTimer();
    await _speech.stop();

    if (_fullTranscript.isEmpty) {
      setState(() {
        _state = VoiceInputState.error;
        _errorMessage = 'Tidak ada input suara';
      });
      return;
    }

    setState(() => _state = VoiceInputState.processing);
    await _processTranscript(_fullTranscript);
  }

  Future<void> _processTranscript(String transcript) async {
    try {
      final draftItems = await _mockParseTranscript(transcript);

      if (draftItems != null && draftItems.isNotEmpty) {
        setState(() {
          _draftItems = draftItems;
          _totalSen = _draftItems.fold(0, (sum, item) => sum + item.priceSen * item.quantity);
          _state = VoiceInputState.result;
        });
      } else {
        setState(() {
          _state = VoiceInputState.error;
          _errorMessage = 'Tidak dapat memahami transaksi';
        });
      }
    } catch (e) {
      setState(() {
        _state = VoiceInputState.error;
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  Future<List<DraftTransactionItem>?> _mockParseTranscript(String transcript) async {
    await Future.delayed(const Duration(seconds: 1));

    if (transcript.toLowerCase().contains('indomie') ||
        transcript.toLowerCase().contains('aqua') ||
        transcript.toLowerCase().contains('rokok')) {
      return [
        const DraftTransactionItem(name: 'Inomie Goreng', quantity: 3, priceSen: 350000),
        const DraftTransactionItem(name: 'Aqua Botol 600ml', quantity: 2, priceSen: 400000),
        const DraftTransactionItem(name: 'Rokok Surya 1 Pak', quantity: 1, priceSen: 250000),
      ];
    }
    return null;
  }

  void _onCancel() {
    _isUserStillRecording = false;
    _stopTimer();
    _speech.stop();
    if (mounted) {
      context.pop();
    }
  }

  void _onRetry() {
    setState(() {
      _state = VoiceInputState.idle;
      _fullTranscript = '';
      _transcriptController.clear();
      _draftItems = [];
      _totalSen = 0;
      _errorMessage = null;
    });
    _startListening();
  }

  void _onConfirm() {
    context.go('/pending');
  }

  void _onEditManual() {
    context.go('/transaction/form');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    _scrollController.dispose();
    _transcriptController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          Text(
            _getHeaderTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: _state == VoiceInputState.listening
                ? IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: _onCancel,
                    tooltip: 'Tutup',
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    return switch (_state) {
      VoiceInputState.idle => 'Catat Suara',
      VoiceInputState.listening => 'Sedang Mendengarkan',
      VoiceInputState.processing => 'Memproses...',
      VoiceInputState.result => 'AI Memahami',
      VoiceInputState.error => 'Tidak Berhasil',
    };
  }

  Widget _buildBody() {
    return switch (_state) {
      VoiceInputState.idle => _buildIdleState(),
      VoiceInputState.listening => _buildListeningState(),
      VoiceInputState.processing => _buildProcessingState(),
      VoiceInputState.result => _buildResultState(),
      VoiceInputState.error => _buildErrorState(),
    };
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: const Icon(Icons.mic, size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          const Text(
            'Tekan mic untuk mulai',
            style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _startListening,
            icon: const Icon(Icons.mic),
            label: const Text('Mulai'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(200, 56),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningState() {
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hearing, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Sedang Mendengarkan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FakeWaveformWidget(isListening: true),
          const SizedBox(height: 24),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              reverse: true,
              child: Text(
                _fullTranscript.isEmpty ? 'Mulai berbicara...' : _fullTranscript,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '⏱ $_formattedDuration',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.onSurface,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _stopAndProcess,
              icon: const Icon(Icons.stop, size: 24),
              label: const Text(
                'STOP & PROSES',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onError,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _onCancel,
              child: const Text(
                'Batal',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Memproses...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _fullTranscript,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _draftItems.length,
              itemBuilder: (context, index) {
                final item = _draftItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${item.quantity} × ${item.priceDisplay}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
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
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(_totalSen ~/ 100),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _onConfirm,
              icon: const Icon(Icons.check, size: 24),
              label: const Text(
                'KONFIRMASI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'Ulangi',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: _onEditManual,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, size: 20, color: AppColors.onSurfaceVariant),
                  SizedBox(width: 8),
                  Text(
                    'Edit Manual',
                    style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorContainer,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tidak dapat memahami',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(180, 56),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _onEditManual,
              icon: const Icon(Icons.edit),
              label: const Text('Input Manual'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(180, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
