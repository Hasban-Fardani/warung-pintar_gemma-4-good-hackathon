# WarungPintar — Offline AI-Powered ERP for Indonesian Micro-SMBs

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.27+-02569B?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.6+-0175C2?style=flat-square&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/AI-Gemma%204%20E2B-FF6B6B?style=flat-square" alt="Gemma 4">
  <img src="https://img.shields.io/badge/License-Apache%202.0-green?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/Offline-First-brightgreen?style=flat-square" alt="Offline First">
</p>

> **Gemma 4 Good Hackathon** — Digital Equity & LiteRT Track

An offline-first, AI-powered ERP application for Indonesian micro-SMB owners (**warung**). Built with Flutter + Gemma 4 E2B (LiteRT-LM), featuring voice transactions, multimodal vision parsing, and a non-blocking pending workflow — all running 100% offline on-device with zero network calls after model initialization.

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

### 🧠 AI Runtime Resilience

- **Model download with resume** — interrupted downloads resume via `Range` header
- **Sideload support** — push model via ADB to `/sdcard/Download/` for fast dev iteration; app detects it automatically before attempting network download
- **File integrity validation** — rejects corrupted/partial models (<2.2 GB) before attempting to load
- **Stale metadata cleanup** — calls `FlutterGemma.uninstallModel()` before re-installing to prevent stale cache issues
- **Android scoped storage** — uses streaming copy (`openRead`/`openWrite`) instead of `File.copy()` to handle cross-mount `Permission denied` errors
- **`MANAGE_EXTERNAL_STORAGE` permission** — requested at runtime for sideload path access on Android 11+

### 🏗️ Enterprise-Grade Architecture

- **Offline-First** — 0 network requests after model download
- **Non-Blocking Pending Workflow** — transactions recorded instantly, confirmed later
- **Immutable Price History** — past transactions never affected by price changes
- **Idempotency Protection** — double-tap proof via UUID + unique constraint
- **Audit Log** — raw AI JSON output stored verbatim for every transaction
- **Per-item Pricing** — each transaction item stores `price_sen` (price per unit × 100) independently

### 🗣️ Voice Transaction Enhancements

- **Persistent STT** — auto-restart on pause/done so users can speak freely without time pressure
- **STT status indicator** — visual chip shows "Jeda..." when speech recognition is paused
- **Credit handling** — `"nanti bayar"` / `"utang"` detected via `needs_clarification` flag
- **AI prompt with examples** — improved prompting with real-world transaction examples in Bahasa Indonesia
- **Pending detail page** — view individual pending transaction details before confirmation

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

### 3. Push AI Model to Device (Development)

The Gemma 4 E2B model (~2.6 GB) is **not bundled** in the APK. For development, push it via ADB:

```bash
# Download the model from HuggingFace:
# https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm

# Place it at ~/Downloads/gemma-4-E2B-it.litertlm, then:
./scripts/push_model.sh

# Build and install the app
flutter run
```

On first launch, the app will:
1. Check `getApplicationDocumentsDirectory()` for an existing valid model (≥2.2 GB)
2. Check `/storage/emulated/0/Download/gemma-4-E2B-it.litertlm` for a sideloaded model
3. Fall back to downloading from HuggingFace

### 4. Build Debug APK

```bash
flutter build apk --debug
```

The APK will be at `build/app/outputs/flutter-apk/app-debug.apk`.

---

## Application Flow

### Startup Flow

```
App Launch
    │
    ├── 📁 App docs dir has valid model (≥2.2 GB)?
    │       ├── YES → Install & Load → Dashboard
    │       │
    │       └── NO  → 🔒 Request MANAGE_EXTERNAL_STORAGE
    │                   │
    │                   ├── 📁 /sdcard/Download/ has valid model?
    │                   │       ├── YES → Streaming copy to app docs
    │                   │       │        → Uninstall stale metadata
    │                   │       │        → Install & Load → Dashboard
    │                   │       │
    │                   │       └── NO  → 🌐 Download model (~2.6 GB)
    │                   │                   │
    │                   │                   └── Resume supported
    │                   │                        → Install & Load → Dashboard
    │                   │
    │                   └── (retry & recovery on failure)
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
    ├── STT streams transcript → AI parses via Gemma 4 E2B
    │
    ├── Multi-item pending transactions created
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
| AI Runtime | Gemma 4 E2B via LiteRT-LM (FFI) |
| Speech-to-Text | speech_to_text (Android SpeechRecognizer) |
| Vision | flutter_gemma multimodal |

### Project Structure

```
lib/
├── core/
│   ├── ai/              # Gemma service, prompts, init notifier, parsers
│   ├── constant/        # Colors, strings, app-wide constants
│   ├── database/        # SQLite service, migrations, WAL mode
│   ├── di/              # GetIt + injectable registration
│   ├── router/          # GoRouter + StatefulShellRoute
│   ├── error/           # Sealed AiFailure hierarchy, Result pattern
│   ├── utils/           # Money formatters, helpers
│   └── voice/           # Voice service abstraction & implementation
├── features/
│   ├── onboarding/      # Agent 1: conversational setup
│   ├── transaction/     # Agents 2, 3: voice tx, pending confirmation
│   ├── vision/          # Agents 4, 5: receipt & product parsing
│   ├── catalog/         # Master data: items, categories, price history
│   ├── dashboard/       # Bento box layout, pending banner, FAB
│   └── reports/         # PDF/CSV export
├── shared/
│   └── widgets/         # Reusable widgets (FAB, banners, etc.)
└── main.dart
```

### State Management Pattern

All state uses Riverpod with a **sealed class hierarchy** for exhaustive pattern matching:

```dart
// Example: App initialization state
sealed class AppInitState {}
final class AppInitLoading extends AppInitState {}
final class AppInitModelDownloading extends AppInitState {
  final double progress;
  final double speedMBps;
  final String eta;
}
final class AppInitModelReady extends AppInitState {}
final class AppInitModelFailed extends AppInitState {
  final String reason;
}
final class AppInitAiDegraded extends AppInitState {
  final String reason;
}
```

### Routes

| Route | Page | Purpose |
|-------|------|---------|
| `/` | DashboardScreen | Main dashboard with bento layout |
| `/model-download` | ModelDownloadScreen | First-launch model download |
| `/onboarding` | OnboardingWelcomePage | Agent 1: voice onboarding |
| `/pending` | PendingTransactionsPage | Pending transaction list |
| `/pending/:id` | PendingDetailPage | Single pending transaction detail |
| `/voice-input` | VoiceInputPage | Agent 2: voice transaction input |
| `/voice-confirm` | VoiceConfirmPage | Agent 3: voice bulk confirmation |
| `/transaction/new` | TransactionFormPage | Manual transaction form |
| `/transaction/edit/:id` | TransactionFormPage | Edit existing transaction |
| `/receipt-capture` | ReceiptCapturePage | Agent 4: receipt photo |
| `/product-capture` | ProductCapturePage | Agent 5: product photo |
| `/catalog` | CatalogListPage | Item master data |
| `/catalog/categories` | CategoryManagementPage | Category management |
| `/settings` | SettingsPage | App settings |
| `/reports` | ReportsPage | CSV/PDF export |

---

## Offline Compliance

After the initial model download:

- ✅ Zero network requests during normal operation
- ✅ All AI inference runs on-device via LiteRT-LM (FFI)
- ✅ All data stored in local SQLite (WAL mode)
- ✅ Android SpeechRecognizer works offline (id-ID language pack)
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

| Area | Status |
|------|--------|
| Gemma 4 E2B model loading | ✅ Complete |
| Model download with resume | ✅ Complete |
| Sideload via ADB (`/sdcard/Download/`) | ✅ Complete |
| File integrity validation (≥2.2GB) | ✅ Complete |
| Scoped storage streaming copy | ✅ Complete |
| Stale metadata cleanup on reinstall | ✅ Complete |
| Agent 1: Onboarding | ✅ Complete |
| Agent 2: Voice transactions | ✅ Complete |
| Agent 3: Pending confirmation | ✅ Complete |
| Agent 4: Vision receipt parsing | ✅ Complete |
| Agent 5: Vision product cataloging | ✅ Complete |
| Non-blocking pending workflow | ✅ Complete |
| Immutable price history | ✅ Complete |
| Per-item pricing (`price_sen`) | ✅ Complete |
| Audit log with raw AI JSON | ✅ Complete |
| STT auto-restart on pause | ✅ Complete |
| Pending detail page | ✅ Complete |
| Edit transaction route | ✅ Complete |
| SQLite with WAL mode | ✅ Complete |
| GoRouter + StatefulShell navigation | ✅ Complete |
| GetIt + injectable DI | ✅ Complete |
| Riverpod state management | ✅ Complete |

---

## License

Apache License 2.0 — see [LICENSE](LICENSE) file.

---

## Acknowledgments

- **Google Gemma Team** — Gemma 4 E2B model and LiteRT-LM SDK
- **Flutter Team** — Flutter framework
- **HuggingFace** — Model hosting and distribution
