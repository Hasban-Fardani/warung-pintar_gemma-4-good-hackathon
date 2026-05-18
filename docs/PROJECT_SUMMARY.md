# WarungPintar — PRD Condensed (AI Context)

> **Gemma 4 Good Hackathon Submission | Digital Equity & LiteRT Track**  
> Copy-paste ready for AI. Zero fluff. Strict guardrails enforced.

---

## ⚠️ HACKATHON RULES — NON-NEGOTIABLE GUARDRAILS

```
[JUDGING CRITERIA — KAGGLE]
• Impact & Vision (40pts): 64M UMKM, zero digital literacy barrier, 100% offline
• Video Pitch (30pts): ≤3min, Airplane Mode visible ≥3 scenes, emotional before/after
• Technical Depth (30pts): APK runs on ≤4GB RAM, Logcat proof, Kaggle Notebook, 3x Gemma 4 features

[MANDATORY PROOF — REJECT IF MISSING]
✅ Zero outbound network calls during normal operation (Android Network Profiler screenshot)
✅ All 5 agents functional in Airplane Mode (Logcat filter: WarungPintar/AuditLog)
✅ Raw AI JSON output stored verbatim in audit_logs.ai_raw_output
✅ Integer money protocol: ALL monetary values stored as BIGINT sen (×100), NEVER float/decimal
✅ Idempotency: UUIDv4 key enforces UNIQUE constraint — double-submit = silent ignore
✅ Price history immutable: transactions store price_at_transaction_sen snapshot, never reference current price

[STRICT OUTPUT CONSTRAINTS FOR AI]
• NEVER generate network-dependent code (no Retrofit, no http calls except model download)
• NEVER use float/double for money — always int sen
• NEVER overwrite price_history — always INSERT new record
• NEVER assume internet connectivity — all features must work offline
• ALWAYS output valid JSON matching Appendix A schema — no markdown fences, no trailing text
• ALWAYS include idempotency_key in transaction inserts
• ALWAYS log raw_input_source + ai_raw_output to audit_logs
```

---

## 🎯 PROJECT IDENTITY

| Attribute | Value |
|-----------|-------|
| **Name** | WarungPintar Cimahi |
| **Type** | Offline-first Agentic ERP for Indonesian micro-merchants |
| **Platform** | Android (min SDK 26, target 34) |
| **Framework** | Flutter 3.27+ / Dart 3.6+ |
| **State Mgmt** | Riverpod 2.6+ (AutoDispose) |
| **DI** | GetIt 7.6+ |
| **Routing** | GoRouter 14.0+ (StatefulShellRoute) |
| **AI Runtime** | Gemma 4 E2B via LiteRT-LM (on-device) + native function calling + native multimodal vision |
| **DB** | SQLite WAL mode, UUIDv7 PKs |
| **License** | Apache 2.0 |

**Core Value**: Ibu Warsih (45–60, low digital literacy) records multi-item transactions via long-form voice, photos receipts for auto-parse, adds products via packaging photo — zero manual form filling, 100% offline.

---

## 👥 USER PERSONAS (DESIGN FOR PRIMARY)

```
PRIMARY: Ibu Warsih (Warung Owner)
• Age 45–60, Cimahi, SMP education, very low digital literacy
• Pain: Forgets transactions during rush hour (3–5 customers simultaneously), can't calculate daily profit manually
• Accessibility: Touch target ≥48dp, font ≥14sp, WCAG AAA contrast (7:1), noise-tolerant STT

SECONDARY: Pak Budi (Supplier) — bulk stock entry via photo/voice
TERTIARY: Koperasi Mitra — consumes PDF/CSV reports for microloan approval
```

---

## 📊 SUCCESS METRICS (HACKATHON VERIFIABLE)

| Metric | Target | Proof Method |
|--------|--------|-------------|
| Onboarding | 0 manual keystrokes | Screen recording |
| Voice multi-item tx | <8s end-to-end | Timestamp overlay |
| Bulk voice confirm | <3s/item | Screen recording |
| Image→transaction (receipt) | <10s parse+insert | Screen recording |
| Image→masterdata (packaging) | <8s parse+pre-fill | Screen recording |
| Offline compliance | 100% features in Airplane Mode | Logcat screenshot |
| Model cold start | ≤90s | Timer overlay |
| Zero network | 0 outbound connections | Android Network Profiler |

---

## 🗂️ ARCHITECTURE ESSENTIALS

```
lib/
├── core/
│   ├── ai/          ← GemmaIsolateService, prompts, JSON parser, retry/fallback
│   ├── database/    ← SQLite WAL, UUIDv7, idempotency, integer money
│   ├── di/          ← GetIt registration (AiService interface for testability)
│   ├── router/      ← GoRouter config (StatefulShellRoute + bottom nav)
│   └── error/       ← sealed class AiFailure hierarchy
├── features/
│   ├── onboarding/  ← Agent 1: conversational setup (zero form)
│   ├── transaction/ ← Agent 2 (voice tx) + Agent 3 (voice confirm) + pending workflow
│   ├── vision/      ← Agent 4 (receipt parse) + Agent 5 (packaging parse)
│   ├── catalog/     ← Master barang + kategori + immutable price_history
│   ├── dashboard/   ← Bento layout, pending banner, stock alerts
│   └── reports/     ← PDF/CSV export, transaction list paginated
└── main.dart
```

**Critical Patterns**:
- `AiService` abstract interface → enables mocking for unit tests
- `Result<Success<T>, Error<AiFailure>>` pattern for all async operations
- UUIDv7 for time-sortable offline-first PKs (no AUTOINCREMENT)
- All money: `amount_sen: INTEGER` (Rupiah × 100), display via `NumberFormat.currency(locale: 'id')`

---

## 🤖 5 AGENTS — PROMPT STRUCTURE & TOOLS

```
[PROMPT TEMPLATE — ALL AGENTS]
[KONTEKS SISTEM] ← Role + global constraints (repeat every session)
[KONTEKS DATA]   ← SQLite context: {stock_context} (max 20 latest items)
[INSTRUKSI KETAT]← Output rules: JSON-only, no guessing, clarify fallback
[PERINTAH USER]  ← STT transcript or image description

[MANDATORY OUTPUT RULES]
• Output HANYA valid JSON matching tool schema — no markdown, no explanation
• If info insufficient: {"name": "clarify", "arguments": {"question": "..."}}
• Vision: If image unreadable: {"error": "image_unreadable"}
• NEVER guess price if not in context — use default_price_sen or flag needs_clarification
```

| Agent | Trigger | Tool | Critical Rules |
|-------|---------|------|---------------|
| **1: Onboarding** | First launch (empty DB) | `setup_business` | Zero form, voice-only, creates categories+items |
| **2: Voice Tx** | FAB 🎤 long-speech | `record_transactions` | All tx status=`pending`, price=integer sen, multi-item array |
| **3: Voice Confirm** | Pending tab → voice confirm | `confirm_transactions` | Support "semua benar", partial edit, skip, delete |
| **4: Vision Receipt** | FAB 📷 → Foto Struk | `record_transactions` | All tx type=`buy`, status=`pending`, price×100 |
| **5: Vision Packaging** | FAB 📷 → Foto Kemasan | `parse_product_from_image` | Extract name+category ONLY — NO price, price via voice |

**Tool Schema Reference**: See Appendix A in full PRD. Key constraints:
- `total_price_sen`: integer, minimum 0 (NOT per-unit)
- `transaction_type`: enum ["sell", "buy"]
- `needs_clarification`: boolean default false
- `confirm_transactions`: supports `confirm_all` flag + per-item actions

---

## 🔐 DATA INTEGRITY — NON-NEGOTIABLE

```sql
-- MONEY: ALWAYS INTEGER SEN
amount_sen INTEGER NOT NULL CHECK(amount_sen >= 0)  -- Rp 45.000 → 4500000
price_at_transaction_sen INTEGER NOT NULL           -- Snapshot, never reference current price

-- IDEMPOTENCY: ANTI DOUBLE-SUBMIT
idempotency_key TEXT UNIQUE NOT NULL  -- UUIDv4, silent ignore duplicate inserts

-- AUDIT LOG: APPEND-ONLY
CREATE TABLE audit_logs (
  ai_raw_output TEXT,        -- Raw Gemma JSON BEFORE parsing (verifiable proof)
  raw_input_source TEXT,     -- STT transcript or image path
  state_snapshot TEXT NOT NULL  -- Full row state as JSON at time of action
);

-- PRICE HISTORY: IMMUTABLE
-- UPDATE stock.default_price_sen FOR AI CONTEXT ONLY
-- INSERT NEW record to price_history FOR ALL CHANGES
-- Transactions reference price_at_transaction_sen — NEVER JOIN to current price
```

---

## 🚫 CUT PRIORITY (IF TIME RUNS OUT)

```
SAFE TO CUT (in order):
1. Charts in Reports (keep paginated list)
2. PDF export (use CSV only)
3. Bahasa Sunda support (keep Indonesian only)

NEVER CUT — REJECT SUBMISSION IF MISSING:
❌ Agent 4 Vision Receipt (primary differentiator)
❌ Agent 5 Vision Packaging (secondary differentiator)  
❌ Non-blocking pending workflow (core UX)
❌ Audit log with raw AI JSON output (verifiable proof)
❌ Offline compliance (100% Airplane Mode functionality)
❌ Integer money protocol + idempotency (data integrity)
```

---

## ✅ SUBMISSION CHECKLIST (VERIFIABLE)

```
[TECHNICAL]
[ ] APK runs on physical Android ≤4GB RAM, Airplane Mode ON
[ ] Folder structure matches Section 5.1 (Feature-First Clean Architecture)
[ ] GetIt DI with AiService interface (mockable for tests)
[ ] GoRouter handles navigation + state preservation
[ ] All 5 agents functional with correct tool calling
[ ] Pending workflow: status=pending → confirmed via voice, not auto-confirmed
[ ] Price history: INSERT new record on price change, transactions immutable
[ ] JSON parser robust: _stripJsonFences() handles markdown/trailing text
[ ] Idempotency: double voice/image submit = 1 DB row
[ ] Audit log: raw AI JSON + STT transcript stored per transaction
[ ] Zero hardcoded network URLs (except model download with fallback)

[PROOF]
[ ] Audit log drawer shows: STT transcript + raw Gemma JSON + idempotency key
[ ] Logcat screenshot: zero HttpClient calls during normal operation
[ ] Android Network Profiler: 0 outbound connections post-model-download
[ ] Kaggle Notebook public: all 5 agents proven with sample inputs/outputs
[ ] GitHub repo public (Apache 2.0), README with offline test instructions

[DELIVERABLES]
[ ] YouTube video ≤3min: Airplane Mode visible ≥3 scenes, timer overlays for metrics
[ ] Kaggle writeup <1,500 words: Impact → Agents → Integrity → Proof → Roadmap
[ ] README: install steps, offline test guide, architecture diagram (Riverpod+GetIt)
```

---

## ⚡ AI RUNTIME SPECS (SECTION 16 — CRITICAL)

```
MODEL DELIVERY
• NOT bundled in APK — model chunks approach was removed (caused OOM, slow build, no live reload)
• Model file: gemma-4-E2B-it.litertlm (2.59 GB, .litertlm format for LiteRT-LM)
• Source: litert-community/gemma-4-E2B-it-litert-lm on HuggingFace

INIT ORDER (app_init_notifier.dart):
  1. Check app documents dir — if file exists and size > 100MB → install via fromFile()
  2. Check sideload path /sdcard/Download/gemma-4-E2B-it.litertlm — if valid → copy → install
  3. Fallback: download via Dio with Range header resume support

DEV WORKFLOW:
  • Download model once to ~/Downloads/gemma-4-E2B-it.litertlm
  • Run scripts/push_model.sh to ADB push to device before flutter run
  • Script skips push if file already on device with matching size
  • Alias: wp → push_model.sh && flutter run

DOWNLOAD (fallback only):
  • Dio with Range header for resume support
  • Connection timeout: 30s | Receive timeout: 30 minutes
  • Progress UI: circular indicator + % + speed (MB/s) + ETA
  • Partial file deleted automatically on failure
  • No SHA-256 verify (removed — unnecessary for hackathon scope)
  • No GitHub Releases fallback (file is 2.59GB, exceeds GitHub 2GB limit)

COLD START STATE MACHINE
AppInitState: ModelDownloading → ModelLoading → ModelReady | ModelFailed | AiDegraded
• ModelLoading: manual input works, voice/foto FABs disabled with tooltip
• ModelFailed/AiDegraded: permanent/session manual mode, all data still saves to SQLite

GEMMA 4 CONSTRAINTS
• Context window: 8192 tokens → limit prompt to 6000, output to 512 tokens
• 512 tokens ≈ 17 transaction items (realistic max: 10–12) — sufficient
• NO token streaming → show CircularProgressIndicator during inference
• Vision support: runtime check with 1x1 pixel test, disable FAB if failed

STT OFFLINE
• speech_to_text uses Android SpeechRecognizer API (on-device)
• Check id-ID locale availability at startup → dialog + deep link to settings if missing
• VAD: pauseFor=2000ms (natural pause tolerance), minConfidence=0.5

TIMEOUT & RETRY
• Voice inference: 30s timeout | Vision: 45s timeout
• Max 2 retries with exponential backoff (1s, 3s)
• Retry only for: InferenceTimeoutFailure, ModelNotLoadedFailure
• InvalidJsonOutputFailure → handled by Fallback Level 1

FALLBACK HIERARCHY
Level 1: _stripJsonFences() + 1x retry with reinforcement prompt
Level 2: Disable voice/foto FABs, show red banner, auto-open manual form
Level 3: Permanent manual mode (ModelFailed), gray banner, all features work sans AI

VISION QUALITY GATE (BEFORE INFERENCE)
• File size ≥10KB | Resolution ≥400×400px | Brightness avg ≥40/255
• Fail → dialog with specific message + "Foto Ulang" option
• Gate runs BEFORE compression/base64 encoding to save time
```

---

## 🛠️ DEV TOOLING & SCRIPTS

scripts/push_model.sh
  • Checks if model exists at ~/Downloads/gemma-4-E2B-it.litertlm
  • Connects via ADB, checks if device already has model with matching file size
  • Skips push if size matches (avoids re-pushing 2.59GB unnecessarily)
  • Pushes to /sdcard/Download/gemma-4-E2B-it.litertlm on device

DAILY DEV WORKFLOW:
  1. Connect Android device via USB
  2. Run: ./scripts/push_model.sh && flutter run
  3. App detects sideloaded model on first launch, copies to app documents dir
  4. Subsequent launches use copy in app documents dir directly

MODEL LOAD FLOW (app_init_notifier.dart):
  AppInitLoading
    → check app documents dir
    → check /sdcard/Download/ sideload
    → [if needed] _downloadWithResume() via Dio
    → FlutterGemma.installModel().fromFile().install()
    → FlutterGemma.getActiveModel(preferredBackend: gpu)
    → GemmaService.initialize(model)
  AppInitModelReady

---

## 🎨 UI/UX NON-NEGOTIABLES (DESIGN.md + ERP PRINCIPLES)

```
ACCESSIBILITY (AGE 40+)
• Font: body 16–18sp, labels ≥16sp, headings 20–24sp
• Touch target: ≥48dp for ALL interactive elements
• Contrast: WCAG AAA (7:1) for all text
• Color + icon + label: NEVER color-only indicators

TABLES (table-design.md)
• Column alignment matches data type: text=left, money=right, dates=left
• Tabular numerals for all monetary columns: font-variant-numeric: tabular-nums
• Row height ≥48px, hover highlight (no zebra striping)
• Default sort reflects user mental model: documents=created_at DESC, approvals=submitted_at ASC

FORMS (erp-principles.md)
• Persistent labels (NO placeholder-as-label)
• Error messages explain action: "Contract Date cannot be in past" NOT SQL error
• Filter state persists on back navigation (session/URL params)
• Every server action: immediate button disable + spinner feedback

NAVIGATION (erp-principles.md)
• Max 3 clicks for frequent tasks (Ibu Warsih daily workflow)
• FAB (ExpandableFab) expands to 3 mini FABs ABOVE main FAB, arranged horizontally
  - 🎤 Suara → /voice-input (disabled if AI not ready)
  - 📷 Foto → PhotoSourceBottomSheet (disabled if AI not ready)
  - ✏️ Manual → /transaction/new (always enabled)
• No backdrop/overlay when FAB is expanded
• Mini FABs animate with SlideTransition + FadeTransition + ScaleTransition
• Pending banner always on top if pending exists: "⏳ N transaksi pending [🎤 Konfirmasi]"
```

---

## 🧪 TESTING REQUIREMENTS

```
UNIT TESTS (MOCKED)
• AiService.infer() returns valid ToolCall for voice input
• Money conversion: rupiahToSen("45000") == 4500000, senToDisplay(4500000) == "Rp 45.000"
• JSON fence stripper handles malformed output with markdown/trailing text

INTEGRATION TESTS (REAL DB)
• Idempotency: duplicate insert with same idempotency_key = 1 row
• Price history: update price → new history record, old transactions unchanged

DEVICE TESTS (PHYSICAL ANDROID ≤4GB RAM)
• Airplane Mode ON: all features functional
• Double-tap submit: only 1 transaction row created
• Long voice input (10+ items): all items enter pending queue, no crash
• Bulk voice confirm: all pending items transition to confirmed
• Memory pressure: app doesn't crash, model stays loaded
```

---

## 📦 DEPENDENCIES (pubspec.yaml ESSENTIALS)

```yaml
dependencies:
  flutter_riverpod: ^2.6.0    # State management (AutoDispose)
  get_it: ^7.6.0              # DI (service locator)
  go_router: ^14.0.0          # Declarative navigation
  flutter_gemma: ^0.14.x      # LiteRT-LM on-device inference (NOT ^0.2.0)
  speech_to_text: ^7.0.0      # Android on-device STT
  sqflite: ^2.3.0             # SQLite with WAL
  uuid: ^4.3.3                # UUIDv7 for offline-first PKs
  intl: ^0.19.0               # Currency formatting (id-ID)
  dio: ^5.4.0                 # Model download with resume (Range header)
  crypto: ^3.0.3              # SHA-256 verification
  logger: latest              # Structured logging (PrettyPrinter)
  path_provider: latest       # App documents directory for model storage
  injectable: ^2.6.0          # GetIt code generation
  freezed: ^2.5.0             # Immutable state classes
  fpdart: ^1.1.0              # Either/Result pattern
```

---

> **END OF CONDENSED PRD**  
> AI INSTRUCTIONS: Use this document as single source of truth. If any implementation detail conflicts with this summary, defer to the full PRD.md. Never generate code that violates the guardrails in Section ⚠️. Always prioritize offline functionality, data integrity, and accessibility for Ibu Warsih.