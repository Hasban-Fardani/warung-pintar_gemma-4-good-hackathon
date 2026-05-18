# WarungPintar — AI Coding Rules (agent.md)

> Flutter 3.27 / Dart 3.6 · Riverpod 2.6 · GetIt · GoRouter · SQLite WAL · Gemma 4 E2B via LiteRT

---

## ⚠️ HACKATHON GUARDRAILS — REJECT IF VIOLATED

```
MONEY    : ALWAYS int sen (Rupiah × 100). NEVER float/double/decimal.
NETWORK  : ZERO outbound calls during normal operation. Model download only.
IDEMPOTENCY : UUIDv4 idempotency_key UNIQUE constraint — duplicate = silent ignore.
PRICE HISTORY : NEVER UPDATE. Always INSERT new record. Transactions store price_at_transaction_sen snapshot.
AUDIT LOG : Raw Gemma JSON (ai_raw_output) + STT transcript MUST be stored verbatim per action.
AI OUTPUT : Valid JSON only — no markdown fences, no trailing text. Clarify via {"name":"clarify","arguments":{"question":"..."}}.
OFFLINE  : 100% features functional in Airplane Mode. Android SpeechRecognizer (id-ID) for STT.
```

---

## 🏗️ ARCHITECTURE — FOLLOW EXACTLY

```
lib/
├── core/
│   ├── ai/          ← GemmaIsolateService, prompts/, json_parser, retry/fallback
│   ├── database/    ← SQLite WAL, UUIDv7 PKs, idempotency, money helpers
│   ├── di/          ← GetIt registration (AiService abstract interface)
│   ├── router/      ← GoRouter + StatefulShellRoute
│   └── error/       ← sealed class AiFailure hierarchy
└── features/
    ├── onboarding/  ← Agent 1
    ├── transaction/ ← Agent 2 (voice tx) + Agent 3 (voice confirm) + pending workflow
    ├── vision/      ← Agent 4 (receipt) + Agent 5 (packaging)
    ├── catalog/     ← stock masterdata + price_history (immutable)
    ├── dashboard/   ← bento layout + pending banner
    └── reports/     ← CSV/PDF export
```

**Non-negotiable patterns:**
- `AiService` — abstract interface, GetIt-injected, always mockable
- `Result<Success<T>, AiFailure>` — ALL async AI operations
- UUIDv7 PKs — no AUTOINCREMENT
- Money display: `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)`

---

## 🤖 5 AGENTS

| # | Trigger | Tool | Key Rules |
|---|---------|------|-----------|
| 1 | First launch (empty DB) | `setup_business` | Zero form, voice-only onboarding |
| 2 | FAB 🎤 long-speech | `record_transactions` | status=`pending`, price=int sen, multi-item array |
| 3 | Pending tab → 🎤 confirm | `confirm_transactions` | Support `confirm_all`, partial edit, skip, delete |
| 4 | FAB 📷 → Foto Struk | `record_transactions` | type=`buy`, status=`pending`, price×100 |
| 5 | FAB 📷 → Foto Kemasan | `parse_product_from_image` | Name+category ONLY — NO price inference |

**Prompt template (semua agent):**
```
[KONTEKS SISTEM] Role + global constraints (ulang setiap sesi)
[KONTEKS DATA]   Stock context max 20 items dari SQLite
[INSTRUKSI KETAT] JSON-only output, no guessing, clarify fallback
[PERINTAH USER]  STT transcript atau image description
```

---

## 🔐 DATA INTEGRITY

```sql
-- MONEY
amount_sen INTEGER NOT NULL CHECK(amount_sen >= 0)
price_at_transaction_sen INTEGER NOT NULL  -- snapshot, never JOIN to current price

-- IDEMPOTENCY
idempotency_key TEXT UNIQUE NOT NULL  -- UUIDv4

-- AUDIT (append-only)
CREATE TABLE audit_logs (
  id TEXT PRIMARY KEY,  -- UUIDv7
  ai_raw_output TEXT NOT NULL,
  raw_input_source TEXT NOT NULL,
  state_snapshot TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

-- PRICE HISTORY (immutable)
-- ✅ UPDATE stock.default_price_sen untuk AI context
-- ✅ INSERT ke price_history untuk setiap perubahan
-- ❌ NEVER update existing price_history record
```

---

## ⚡ AI RUNTIME

```
MODEL DELIVERY  : Download via Dio (resume support), SHA-256 verify, NOT bundled in APK
COLD START      : ModelDownloading → ModelLoading → ModelReady | ModelFailed | AiDegraded
DEGRADED MODE   : Voice/foto FABs disabled, manual form still works, data still saves
CONTEXT LIMIT   : 8192 token window → prompt max 6000, output max 512
STREAMING       : Disabled — show CircularProgressIndicator during inference
TIMEOUT         : Voice 30s | Vision 45s | Max 2 retries (1s, 3s backoff)

FALLBACK HIERARCHY:
  L1: _stripJsonFences() + 1 retry with reinforcement prompt
  L2: Disable AI FABs → red banner → auto-open manual form
  L3: Permanent manual mode (ModelFailed) → gray banner

VISION QUALITY GATE (before inference):
  File ≥10KB | Resolution ≥400×400px | Brightness avg ≥40/255
  Fail → dialog + "Foto Ulang" — gate runs BEFORE compression
```

---

## 🎨 UI NON-NEGOTIABLES

```
ACCESSIBILITY : Touch target ≥48dp | Font body ≥16sp | WCAG AAA 7:1 contrast
INDICATORS    : NEVER color-only — always color + icon + label
PENDING BANNER: Always visible if pending exists → "⏳ N transaksi pending [🎤 Konfirmasi]"
FAB           : Expands to 3 modes — 🎤 Voice | 📷 Foto | ✏️ Manual
TABLES        : text=left | money=right (tabular-nums) | row height ≥48px
FORMS         : Persistent labels (no placeholder-as-label) | error messages explain action
NAV           : Max 3 clicks for Ibu Warsih daily workflow
```

---

## 🚫 CODE ANTI-PATTERNS — REJECT IMMEDIATELY

```dart
// ❌ MONEY AS FLOAT
double price = 45000.0;                     // → int priceSen = 4500000

// ❌ NETWORK IN FEATURES (except model download)
final response = await dio.get('...');      // → use SQLite + AiService only

// ❌ AI SERVICE CONCRETE IN WIDGET
final gemma = GemmaService();               // → inject via GetIt<AiService>()

// ❌ HARDCODED STRING
Text('Transaksi berhasil');                 // → AppStrings.transactionSuccess

// ❌ BUSINESS LOGIC IN WIDGET
onTap: () { final total = qty * price; }   // → move to Notifier/UseCase

// ❌ DIRECT DB CALL IN PRESENTATION
final db = await openDatabase(...);        // → inject via repository

// ❌ print() IN PRODUCTION CODE
print('debug');                            // → use logger package or // DEV:

// ❌ DYNAMIC TYPE
Map<String, dynamic> result;               // → typed model class

// ❌ PRICE JOIN TO CURRENT
SELECT t.qty * s.default_price_sen ...     // → use t.price_at_transaction_sen

// ❌ DUPLICATE INSERT WITHOUT IDEMPOTENCY
await db.insert('transactions', data);     // → must include idempotency_key + UNIQUE constraint
```

---

## ✅ CODE STANDARDS — ALWAYS FOLLOW

```dart
// ✅ MONEY HELPERS
int rupiahToSen(String rupiah) => (double.parse(rupiah.replaceAll('.', '')) * 100).round();
String senToDisplay(int sen) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(sen / 100);

// ✅ RESULT PATTERN
Future<Result<List<TransactionEntity>, AiFailure>> parseVoice(String transcript);

// ✅ SEALED FAILURE CLASS
sealed class AiFailure {}
final class InferenceTimeoutFailure extends AiFailure {}
final class InvalidJsonOutputFailure extends AiFailure { final String raw; ... }
final class ModelNotLoadedFailure extends AiFailure {}
final class ImageQualityFailure extends AiFailure { final String reason; ... }

// ✅ RIVERPOD AUTODISPOSE
@riverpod
class TransactionNotifier extends _$TransactionNotifier { ... }

// ✅ CONST EVERYWHERE
const EdgeInsets.all(16);
const SizedBox(height: 8);

// ✅ SWITCH EXHAUSTIVE
String label(AiFailure f) => switch (f) {
  InferenceTimeoutFailure() => 'Inferensi timeout',
  InvalidJsonOutputFailure() => 'Output AI tidak valid',
  ModelNotLoadedFailure() => 'Model belum siap',
  ImageQualityFailure(:final reason) => 'Foto tidak jelas: $reason',
};
```

---

## 🧪 TESTING REQUIREMENTS

```dart
// UNIT — mocked
test('rupiahToSen("45000") == 4500000', ...);
test('duplicate insert with same idempotency_key = 1 row', ...);
test('AiService.infer() returns valid ToolCall for voice input', ...);
test('_stripJsonFences handles markdown + trailing text', ...);

// DEVICE (physical Android ≤4GB RAM, Airplane Mode ON)
[ ] All 5 agents functional offline
[ ] Double-tap submit → 1 row only
[ ] 10+ item voice → no crash, all enter pending
[ ] Price change → new price_history row, old transactions unchanged
[ ] Memory pressure → model stays loaded
```

---

## 📦 KEY DEPENDENCIES

```yaml
flutter_riverpod: ^2.6.0
get_it: ^7.6.0
go_router: ^14.0.0
flutter_gemma: ^0.2.0   # LiteRT-LM on-device
speech_to_text: ^7.0.0  # Android SpeechRecognizer (id-ID)
sqflite: ^2.3.0
uuid: ^4.3.3             # UUIDv7 PKs
intl: ^0.19.0
dio: ^5.4.0              # Model download only
crypto: ^3.0.3           # SHA-256 verify
fpdart: ^1.1.0           # Either/Result
freezed: ^2.5.0
```

---

MODEL DELIVERY  : 
  1. DEV: Auto-push via scripts/push_model.sh sebelum flutter run
           Model source : ~/Downloads/gemma-4-E2B-it.litertlm
           Android dest : /sdcard/Download/gemma-4-E2B-it.litertlm
           App checks sideload path dulu sebelum network download
  2. PROD: Download via Dio (resume support, Range header), NOT bundled in APK
  
  INIT ORDER (app_init_notifier.dart):
    1. Cek app documents dir — jika valid (>2GB, size match) → install langsung
    2. Cek /sdcard/Download/gemma-4-E2B-it.litertlm — jika valid → copy ke app docs → uninstall stale metadata → install
    3. Fallback: download dari _modelUrl via Dio (resume support, Range header)
    4. Recovery: jika model load gagal → retry dari sideload jika tersedia
## ✅ SUBMISSION PROOF CHECKLIST

```
[ ] APK runs on physical ≤4GB RAM, Airplane Mode ON
[ ] Network Profiler: 0 outbound connections post-model-download
[ ] Logcat: zero HttpClient during normal operation
[ ] Audit log drawer: STT transcript + raw Gemma JSON + idempotency_key visible
[ ] Kaggle Notebook public: all 5 agents with sample inputs/outputs
[ ] GitHub public (Apache 2.0) + README offline test guide
[ ] YouTube ≤3min: Airplane Mode visible ≥3 scenes, timer overlays
```

> **Single source of truth.** Conflict with any other doc → defer to this file. Never violate Section ⚠️.