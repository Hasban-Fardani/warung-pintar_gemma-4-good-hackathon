# WarungPintar — Offline AI-Powered ERP for Indonesian Micro-SMBs

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.27+-02569B?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.6+-0175C2?style=flat-square&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/AI-Gemma%204%20E2B-FF6B6B?style=flat-square" alt="Gemma 4">
  <img src="https://img.shields.io/badge/License-Apache%202.0-green?style=flat-square" alt="License">
</p>

> **Gemma 4 Good Hackathon** — Digital Equity & LiteRT Track

An offline-first, AI-powered ERP application for Indonesian micro-SMB owners (warung). Built with Flutter + Gemma 4 E2B, featuring voice transactions, multimodal vision parsing, and a non-blocking pending workflow — all running 100% offline on-device.

---

## Key Features

### 🤖 Five Gemma 4 AI Agents

| Agent | Capability |
|-------|------------|
| **Agent 1** | Conversational onboarding — zero forms, zero keystrokes |
| **Agent 2** | Long-speech voice transactions — multi-item in one breath |
| **Agent 3** | Voice bulk confirmation — "confirm all" in one sentence |
| **Agent 4** | Vision receipt parsing — foto struk → pending queue |
| **Agent 5** | Vision product cataloging — foto kemasan → pre-filled master data |

### 🏗️ Enterprise-Grade Architecture

- **Offline-First** — 0 network requests after model download
- **Non-Blocking Pending Workflow** — transactions recorded instantly, confirmed later
- **Immutable Price History** — past transactions never affected by price changes
- **Idempotency Protection** — double-tap proof via UUID + unique constraint
- **Audit Log** — raw AI JSON output stored verbatim for every transaction

### 📱 Accessibility-First UI

- Touch targets ≥ 48dp
- Font size ≥ 14sp
- WCAG AAA contrast ratios
- Designed for users 40–70 years old

---

## Prerequisites

| Requirement | Version |
|------------|---------|
| Flutter SDK | ≥ 3.27 |
| Dart SDK | ≥ 3.6 |
| Android SDK | API 26+ (Android 8.0) |
| Android device | ≥ 4GB RAM |

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Hasban-Fardani/warung-pintar_gemma-4-good-hackathon.git
cd warung-pintar_gemma-4-good-hackathon
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Build Debug APK

```bash
flutter build apk --debug
```

The APK will be at `build/app/outputs/flutter-apk/app-debug.apk`.

### 4. Install on Device

```bash
flutter install
```

---

## First Launch — Model Download

On first launch, the app downloads the **Gemma 4 E2B model (~2.6 GB)** from HuggingFace. This happens only once.

The download screen shows:
- Real-time progress percentage
- Download speed (MB/s)
- Estimated time remaining
- Downloaded / Total MB

**⚠️ Important:** Do not close the app during download. After download completes, the app runs 100% offline.

---

## Application Flow

### Startup Flow

```
App Launch
    │
    ├── Model already installed?
    │       ├── YES → Load model → Dashboard
    │       │
    │       └── NO  → Download model (~2.6 GB)
    │                   │
    │                   └── Complete → Load model → Dashboard
    │
    └── Dashboard Ready
            ├── AI features active (voice, camera)
            └── All features work offline
```

### Transaction Flow

```
User taps Voice FAB 🎤
    │
    ├── Speak: "Jual beras 3 kilo 45 ribu, kopi 2 saset 6 ribu"
    │
    ├── AI parses → multiple pending transactions
    │
    └── Dashboard shows pending banner
            │
            └── User confirms later via voice: "Semua benar"
                    │
                    └── Transactions confirmed → Omzet updated
```

### Vision Receipt Flow

```
User taps Camera FAB 📷 → "Foto Struk Supplier"
    │
    ├── Take photo of receipt
    │
    ├── AI parses all items → pending queue
    │
    └── User reviews, confirms, or edits
```

---

## Architecture

### Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.27+ |
| Language | Dart 3.6+ |
| State Management | Riverpod 2.6+ |
| Dependency Injection | GetIt 7.6+ |
| Routing | GoRouter 14.0+ |
| Database | SQLite (WAL mode) |
| AI Runtime | Gemma 4 E2B via LiteRT-LM |
| Speech-to-Text | speech_to_text |
| Vision | flutter_gemma multimodal |

### Clean Architecture Folder Structure

```
lib/
├── core/
│   ├── constant/       # Colors, strings
│   ├── database/       # SQLite service, migrations
│   ├── ai/            # Gemma service, prompts, parsers
│   ├── di/            # GetIt injection
│   ├── router/        # GoRouter configuration
│   ├── error/         # Failures, Result pattern
│   └── utils/         # Formatters, helpers
├── features/
│   ├── onboarding/    # Agent 1: conversational setup
│   ├── transaction/    # Agents 2, 3: voice transactions
│   ├── vision/        # Agents 4, 5: receipt & product parsing
│   ├── catalog/        # Master data: items, categories
│   ├── dashboard/      # Bento box, banners
│   └── reports/        # PDF/CSV export
└── main.dart
```

### State Management Pattern

All state uses Riverpod with a **sealed class hierarchy** for exhaustive pattern matching:

```dart
// Example: Transaction state
sealed class TransactionState {}
final class TransactionIdle extends TransactionState {}
final class TransactionLoading extends TransactionState {}
final class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
}
final class TransactionError extends TransactionState {
  final String message;
}
```

---

## Offline Compliance

After the initial model download:

- ✅ Zero network requests
- ✅ All AI inference runs on-device via LiteRT-LM
- ✅ All data stored in local SQLite
- ✅ Works in Airplane Mode

---

## Building for Release

```bash
# Generate obfuscated release APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Or release bundle for Play Store
flutter build appbundle --release
```

---

## Project Status

| Feature | Status |
|---------|--------|
| Gemma 4 E2B model loading | ✅ Complete |
| Agent 1: Onboarding | ✅ Complete |
| Agent 2: Voice transactions | ✅ Complete |
| Agent 3: Pending confirmation | ✅ Complete |
| Agent 4: Vision receipt parsing | ✅ Complete |
| Agent 5: Vision product cataloging | ✅ Complete |
| Non-blocking pending workflow | ✅ Complete |
| Immutable price history | ✅ Complete |
| Audit log with raw AI JSON | ✅ Complete |
| SQLite with WAL mode | ✅ Complete |
| GoRouter navigation | ✅ Complete |
| GetIt dependency injection | ✅ Complete |
| Riverpod state management | ✅ Complete |

---

## License

Apache License 2.0 — see [LICENSE](LICENSE) file.

---

## Acknowledgments

- **Google Gemma Team** — Gemma 4 E2B model and LiteRT-LM SDK
- **Flutter Team** — Flutter framework
- **HuggingFace** — Model hosting and distribution
