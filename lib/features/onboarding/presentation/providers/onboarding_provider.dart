import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OnboardingStatus { idle, listening, processing, completed }

class OnboardingState {
  final OnboardingStatus status;
  final int currentStep;
  final String shopName;
  final String ownerName;
  final String transcript;

  const OnboardingState({
    this.status = OnboardingStatus.idle,
    this.currentStep = 0,
    this.shopName = '',
    this.ownerName = '',
    this.transcript = '',
  });

  OnboardingState copyWith({
    OnboardingStatus? status,
    int? currentStep,
    String? shopName,
    String? ownerName,
    String? transcript,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      transcript: transcript ?? this.transcript,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void startOnboarding() {
    state = state.copyWith(status: OnboardingStatus.idle, currentStep: 1);
  }

  void processTranscript(String transcript) {
    state = state.copyWith(
      status: OnboardingStatus.processing,
      transcript: transcript,
    );
  }

  void confirmSetup() {
    state = state.copyWith(status: OnboardingStatus.completed, currentStep: 4);
  }

  void reset() {
    state = const OnboardingState();
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setShopName(String name) {
    state = state.copyWith(shopName: name);
  }

  void setOwnerName(String name) {
    state = state.copyWith(ownerName: name);
  }

  void setListening(bool listening) {
    state = state.copyWith(
      status: listening ? OnboardingStatus.listening : OnboardingStatus.idle,
    );
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (_) => OnboardingNotifier(),
);
