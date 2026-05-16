import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/core/di/injection.dart';
import 'package:warung_pintar_cimahi/features/vision/domain/usecases/parse_product_usecase.dart';
import 'package:warung_pintar_cimahi/features/vision/domain/usecases/parse_receipt_usecase.dart';

enum VisionState { idle, capturing, qualityChecking, processing, success, error }

class VisionStateData {
  final VisionState state;
  final dynamic result;
  final String? errorMessage;
  final bool isProcessing;

  const VisionStateData({
    this.state = VisionState.idle,
    this.result,
    this.errorMessage,
    this.isProcessing = false,
  });

  VisionStateData copyWith({
    VisionState? state,
    dynamic result,
    String? errorMessage,
    bool? isProcessing,
  }) {
    return VisionStateData(
      state: state ?? this.state,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class VisionNotifier extends StateNotifier<VisionStateData> {
  final ParseReceiptUseCase _parseReceiptUseCase;
  final ParseProductUseCase _parseProductUseCase;

  VisionNotifier({
    ParseReceiptUseCase? parseReceiptUseCase,
    ParseProductUseCase? parseProductUseCase,
  })  : _parseReceiptUseCase =
            parseReceiptUseCase ?? getIt<ParseReceiptUseCase>(),
        _parseProductUseCase =
            parseProductUseCase ?? getIt<ParseProductUseCase>(),
        super(const VisionStateData());

  Future<void> captureReceipt(File image) async {
    state = state.copyWith(
      state: VisionState.capturing,
      isProcessing: true,
      errorMessage: null,
    );

    state = state.copyWith(
      state: VisionState.qualityChecking,
    );

    state = state.copyWith(
      state: VisionState.processing,
    );

    final result = await _parseReceiptUseCase.call(image);

    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          state: VisionState.success,
          result: data,
          isProcessing: false,
        );
      case Failure(:final error):
        state = state.copyWith(
          state: VisionState.error,
          errorMessage: error,
          isProcessing: false,
        );
    }
  }

  Future<void> captureProduct(File image) async {
    state = state.copyWith(
      state: VisionState.capturing,
      isProcessing: true,
      errorMessage: null,
    );

    state = state.copyWith(
      state: VisionState.qualityChecking,
    );

    state = state.copyWith(
      state: VisionState.processing,
    );

    final result = await _parseProductUseCase.call(image);

    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          state: VisionState.success,
          result: data,
          isProcessing: false,
        );
      case Failure(:final error):
        state = state.copyWith(
          state: VisionState.error,
          errorMessage: error,
          isProcessing: false,
        );
    }
  }

  void reset() {
    state = const VisionStateData();
  }
}

final visionProvider =
    StateNotifierProvider.autoDispose<VisionNotifier, VisionStateData>(
  (ref) => VisionNotifier(),
);
