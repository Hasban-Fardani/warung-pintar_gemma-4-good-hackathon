# WarungPintar Cimahi — Task Checklist

> **Last Updated**: 2026-05-17
> **Progress**: 19/112 actions (17%)
> **PRD Version**: 10.0.0 (AI Runtime Technical Specification Added)
> **Target Platform**: Android (min SDK 26, target SDK 34)

---

## ✅ Milestone 0: Foundation & DI & Router — COMPLETE

- [x] ACT-00 — Fix `pubspec.yaml` — tambah semua pre-approved dependencies
  - Commit: `9155f40` — 66 dependencies resolved, includes `crypto`, `url_launcher`, `image`
  - Verifikasi: `flutter pub get` exit 0, tidak ada dependency conflicts
- [x] ACT-01 — Enforce `analysis_options.yaml` per PRD Appendix C
  - Commit: `d2b7689` — strict lint rules: `avoid_print`, `cancel_subscriptions`, `close_sinks`, `unawaited_futures`
  - Verifikasi: `flutter analyze` — 0 issues, 0 warnings
- [x] ACT-02 — Buat folder structure per PRD §5.1 (Feature-First Clean Architecture)
  - Commit: `78c0839` — 61 `.gitkeep` files across `features/`, `core/`, `lib/`
  - Struktur: `features/{onboarding,transaction,vision,catalog,dashboard,reports}/{data,domain,presentation}/`
- [x] ACT-03 — Extract `AiService` interface → `core/ai/ai_service.dart`
  - Commit: `529f1b6` — pure Dart, zero Flutter imports, method signature: `Future<Result<ToolCallResult, AiFailure>> infer({...})`
- [x] ACT-04 — Extract `DatabaseService` → `core/database/database_service.dart`
  - Commit: `8c62a6e` — `@LazySingleton`, `injection.config.dart` regenerated, SQLite WAL mode setup
- [x] ACT-05 — Buat `AiFailure` sealed class hierarchy per PRD §6.2
  - Commit: `9ff55a1` — 4 variants: `ModelNotLoadedFailure`, `InferenceTimeoutFailure`, `InvalidJsonOutputFailure`, `ImageUnreadableFailure`
  - Pattern: `sealed class AiFailure { final String message; const AiFailure(this.message); }`
- [x] ACT-06 — Buat `app_colors.dart` + `app_strings.dart` per PRD §12.7
  - Commit: `5d4768c` — 50+ color tokens (Primary `#1976D2`, Confirmed `#059669`, Pending `#BA7517`), Indonesian UI strings
- [x] ACT-07 — Buat `money_formatter.dart` + `uuid_helper.dart` per PRD §10.1 & §10.3
  - Commit: `28afae9` — Integer money protocol (sen): `rupiahToSen()`, `senToDisplay()`; UUIDv7/v4 via `uuid: ^4.3.3`
- [x] ACT-08 — Enhance `app_theme.dart` — full DESIGN.md typography per PRD §12.1
  - Commit: `138ecf0` — Typography scale: body 16-18sp, label 16sp, heading 20-24sp; 48dp touch targets; WCAG AAA contrast
- [x] ACT-09 — Restructure `app_router.dart` — PRD §4.1 GoRouter paths
  - Commit: `e932fae` — `StatefulShellRoute` 4 tabs (`/`, `/pending`, `/catalog`, `/settings`), `/onboarding`, push routes (`/item/:id`, `/transaction/:id`, `/reports`)
- [x] ACT-10 — `build_runner` + M0 verification
  - Commit: `246969d` — zero issues, zero network imports in `lib/`, `grep -r "http|dio|cloud" lib/` returns 0 matches

### M0 Verification Gates
- [x] `flutter pub get` — exit 0, no conflicts
- [x] `flutter analyze` — 0 issues, 0 warnings
- [x] `dart run build_runner build --delete-conflicting-outputs` — exit 0
- [x] `grep -r "http|dio|cloud|internet" lib/` — 0 code matches (only allowed in `core/ai/model_download_service.dart`)
- [x] Folder structure matches PRD §5.1 exactly
- [x] `analysis_options.yaml` includes all rules from Appendix C
- [x] No hardcoded network URLs in any Dart file

---

## ✅ Milestone 1: AI Runtime & Isolate Architecture — COMPLETE

- [x] ACT-11 — Buat `tool_call_result.dart` sealed class + `result.dart` Result type
  - Commit: `5a294dc` — `ToolCallSuccess` + `ToolCallFallback` sealed class; `Result<SuccessType, FailureType>` pattern
- [x] ACT-12 — Buat `json_parser.dart` — `_stripJsonFences()` + `parseToolCall()` per PRD §10.5
  - Commit: `5a294dc` — handles markdown fences (```json), trailing text, missing fields, edge cases; throws `FormatException` on invalid JSON
- [x] ACT-13 — Buat `gemma_isolate_service.dart` — isolate infrastructure per PRD §10.4
  - Commit: `5a294dc` — `init()`, `infer()`, `dispose()` lifecycle; worker stub with `ReceivePort`/`SendPort`; singleton pattern
- [x] ACT-14 — Update `ai_service.dart` — return `Result<ToolCallResult, AiFailure>` per PRD §6.1
  - Commit: `5a294dc` — changed from `Future<String>` to `Result` pattern; maps exceptions to `AiFailure` variants
- [x] ACT-15 — Buat `gemma_ai_service.dart` — real implementation via `GemmaIsolateService`
  - Commit: `5a294dc` — isolate communication + json parser integration + error mapping to `AiFailure`
- [x] ACT-16 — Buat 5 system prompt files per PRD §6.3–6.7
  - Commit: `5a294dc` — `onboarding_prompt.txt`, `voice_transaction_prompt.txt`, `pending_confirm_prompt.txt`, `vision_receipt_prompt.txt`, `vision_product_prompt.txt`
  - Semua prompt: enforce JSON-only output, reference tool schemas from Appendix A
- [x] ACT-17 — Unit tests untuk `json_parser.dart` + `tool_call_result.dart`
  - Commit: `5a294dc` — 22 tests: fence stripping, malformed JSON, missing fields, valid tool calls; all pass
- [x] ACT-18 — Run `build_runner`, wire DI `GemmaAiService` per PRD §5.2
  - Commit: `5a294dc` — manual registration in `injection.dart`: `getIt.registerLazySingleton<AiService>(() => GemmaAiService())`; `build_runner` exit 0

### M1 Verification Gates
- [x] `flutter analyze` — 0 issues, 0 warnings
- [x] `flutter test test/core/ai/` — 22 tests pass, 100% coverage on parser logic
- [x] `dart run build_runner build --delete-conflicting-outputs` — exit 0
- [x] `AiService` interface has zero Flutter imports (pure Dart)
- [x] All system prompts end with explicit JSON-only instruction
- [x] `GemmaIsolateService` does not load model on import (lazy initialization)

---

## ⬜ Milestone 2: Agents 1, 2, 3 — Onboarding & Voice

### Database & Domain Layer
- [ ] ACT-19 — Full SQLite DDL di `database_service.dart` per PRD §11
  - Tasks: Implement `PRAGMA journal_mode = WAL`, `PRAGMA synchronous = NORMAL`, `PRAGMA foreign_keys = ON`
  - Tables: `transactions`, `audit_logs`, `stock`, `price_history`, `categories`, `app_settings`
  - Indexes: `idx_tx_date`, `idx_tx_type`, `idx_tx_status`, `idx_tx_method`
  - Constraints: `CHECK` for enums, `UNIQUE` for `idempotency_key`, `FOREIGN KEY` references
- [ ] ACT-20 — Transaction domain layer — entity, abstract repository, use cases
  - Entities: `TransactionEntity` (id UUIDv7, idempotency_key, item_name, quantity, amount_sen, price_at_transaction_sen, type, status, needs_clarification, input_method, confirmed_at, created_at, is_deleted)
  - Abstract Repo: `TransactionRepository` with methods: `insert()`, `findAllPending()`, `confirm()`, `edit()`, `softDelete()`
  - Use Cases: `RecordTransactionUseCase`, `ConfirmTransactionUseCase`, `GetPendingTransactionsUseCase`
- [ ] ACT-21 — Transaction data layer — model, datasource, repository implementation
  - Model: `TransactionModel` (to/from `TransactionEntity`)
  - Datasource: `TransactionLocalDataSource` (CRUD via `DatabaseService`)
  - Repo Impl: `TransactionRepositoryImpl` (implements abstract repo, handles idempotency constraint silently)
- [ ] ACT-22 — Audit log datasource — append-only per PRD §9
  - Method: `insertAuditLog()` — no UPDATE/DELETE allowed
  - Fields: `transaction_id`, `action` (enum from §9.2), `raw_input_source`, `ai_raw_output` (verbatim), `state_snapshot` (JSON dump), `created_at`
  - Verification: Unit test that `updateAuditLog()` and `deleteAuditLog()` methods do not exist

### Agent 1: Conversational Onboarding
- [ ] ACT-23 — Onboarding domain — `setup_business` use case
  - Input: parsed JSON from Agent 1 tool call
  - Logic: Insert categories → insert stock items with `default_price_sen` → insert initial `price_history` entries
  - Output: `Result<SetupResult, AiFailure>` with counts of created items
- [ ] ACT-24 — Onboarding presentation — page + Riverpod provider
  - Page: `OnboardingPage` (full screen, no bottom nav, conversational UI)
  - Provider: `onboardingProvider` (StateNotifier) — manages state: `listening`, `processing`, `complete`, `error`
  - Integration: Calls `VoiceService.startListening()` → `AiService.infer()` → `SetupBusinessUseCase`

### Voice Infrastructure & Agents 2-3
- [ ] ACT-25 — `VoiceService` interface + implementation per PRD §16.4
  - Interface: `Future<VoiceInitResult> initialize()`, `Future<void> startListening({Function(String) onResult})`, `void stopListening()`
  - Impl: `VoiceServiceImpl` using `speech_to_text: ^7.0.0`
  - Config: `localeId: 'id-ID'`, `pauseFor: Duration(milliseconds: 2000)`, `listenFor: Duration(milliseconds: 30000)`, `minConfidence: 0.5`
  - Verification: Check `id-ID` locale availability on init; return `VoiceInitMissingPack()` if not found
- [ ] ACT-26 — Voice transaction provider (Agent 2) per PRD §6.4
  - Provider: `voiceTransactionProvider` (AsyncNotifier)
  - Flow: STT transcript → `InferenceRetry.runWithRetry()` with `voice_transaction_prompt` → parse `record_transactions` → insert as `pending`
  - Edge cases: Handle `needs_clarification=true`, missing price (use `default_price_sen`), verbal numbers ("empat puluh lima ribu" → 4500000 sen)
  - Output: List of pending transactions with `input_method: 'voice'`
- [ ] ACT-27 — Pending confirmation provider (Agent 3) per PRD §6.5
  - Provider: `pendingConfirmProvider` (AsyncNotifier)
  - Flow: Fetch pending list → AI reads summary → user voice response → parse `confirm_transactions` → bulk update status
  - Actions supported: `confirm`, `edit_price`, `skip`, `delete`, `confirm_all`
  - Haptic feedback per PRD §12.6: 1 short vibration on success, 3 light on clarification needed
- [ ] ACT-28 — Shared widgets: `pending_banner.dart`, `status_badge.dart` per PRD §12.4 & §12.5
  - `PendingBanner`: Yellow banner showing count, tap to open confirmation, reactive via Riverpod
  - `StatusBadge`: Two badges per transaction — input method (🎤/📷/✏️) + status (⏳/✅/❗)
  - Styling: 48dp touch targets, 16sp minimum text, WCAG AAA contrast

### Testing & Verification
- [ ] ACT-29 — Unit tests: `record_transaction_usecase.dart`, `confirm_transaction_usecase.dart`
  - Mock `AiService` returning `Success`/`Error` variants
  - Test idempotency: duplicate `idempotency_key` silently ignored
  - Test money conversion: string "45000" → 4500000 sen → display "Rp 45.000"
  - Test clarification flag: item with multiple matches sets `needs_clarification: true`

### M2 Verification Gates
- [ ] `flutter analyze` — 0 issues, 0 warnings
- [ ] `flutter test test/features/transaction/` — all tests pass, >80% coverage on domain layer
- [ ] Voice flow dengan `FakeAiService` — functional end-to-end test: STT transcript → pending insert → confirm → dashboard update
- [ ] Pending count reactive: Adding a pending transaction via test immediately updates `PendingBanner` without rebuild
- [ ] Idempotency test: Insert same transaction twice with same `idempotency_key` → only 1 row in database
- [ ] Integer money test: No float/double usage in any transaction amount field
- [ ] Audit log test: Every transaction insert creates exactly 1 audit log entry with `ai_raw_output` verbatim

---

## ⬜ Milestone 3: Agents 4, 5 + Master Data

### Vision Infrastructure & Agent 4 (Receipt Parser)
- [ ] ACT-30 — Vision domain — `parse_receipt_usecase.dart` (Agent 4) per PRD §6.6
  - Input: `File imageFile`
  - Pre-processing: Compress to JPEG ≤512KB via `flutter_image_compress`, encode base64
  - Inference: Call `InferenceRetry.runWithRetry()` with `vision_receipt_prompt`, `imageBase64`
  - Output: Parse `record_transactions` with all items as `type: 'buy'`, `status: 'pending'`
  - Fallback: Level 1 JSON repair if `InvalidJsonOutputFailure`
- [ ] ACT-31 — Vision presentation — `receipt_capture_page.dart` + provider per PRD §6.6
  - Page: `ReceiptCapturePage` — camera preview, capture button, compression progress indicator
  - Provider: `receiptParseProvider` (AsyncNotifier) — manages state: `capturing`, `compressing`, `inferring`, `preview`, `error`
  - Preview Card: Show parsed items with edit capability before confirm
  - Integration: Tap "Konfirmasi" → call `ConfirmTransactionUseCase` for bulk confirm

### Agent 5: Vision Product Parser (Kemasan)
- [ ] ACT-32 — Vision domain — `parse_product_usecase.dart` (Agent 5) per PRD §6.7
  - Input: `File imageFile`
  - Inference: Call with `vision_product_prompt`, extract `product_name`, `estimated_category`, `size_or_weight`
  - Critical: Output must NOT include price — price obtained via separate voice input
  - Output: `ParseProductResult` with name, category, size; trigger voice prompt for price
- [ ] ACT-33 — Vision presentation — `product_capture_page.dart` + provider per PRD §6.7
  - Page: `ProductCapturePage` — camera intent, capture, inference progress
  - Post-inference: Show pre-filled form with name/category/size; disable price field
  - Voice price input: Auto-trigger `VoiceService.startListening()` after vision success
  - Final insert: Combine vision result + voice price → insert to `stock` + `price_history`

### Master Data: Catalog & Price History
- [ ] ACT-34 — Catalog domain — entities, abstract repo, CRUD use cases per PRD §8.1
  - Entity: `StockEntity` (id UUIDv7, item_name UNIQUE, current_qty, default_price_sen, low_stock_threshold, category_id, is_deleted, last_updated)
  - Abstract Repo: `StockRepository` with `create()`, `findAll()`, `findById()`, `update()`, `softDelete()`, `getByCategory()`
  - Use Cases: `AddStockUseCase`, `UpdateStockUseCase`, `DeleteStockUseCase`, `GetStockListUseCase`
- [ ] ACT-35 — Catalog data — models, datasources, repository implementation
  - Model: `StockModel` (to/from `StockEntity`)
  - Datasource: `StockLocalDataSource` (CRUD via `DatabaseService`)
  - Repo Impl: `StockRepositoryImpl` with search/filter logic
- [ ] ACT-36 — Catalog presentation — list, detail, category drawer per PRD §8.1–8.2
  - Pages: `CatalogPage` (list with search/filter), `StockDetailPage` (info + price history timeline), `CategoryDrawer` (modal)
  - Widgets: `StockListItem` (with price history badge), `PriceHistoryTimeline` (append-only visual)
  - FAB Integration: "Foto Kemasan" and "Tambah Manual" actions
- [ ] ACT-37 — Price history — append-only `update_price_usecase.dart` per PRD §10.6
  - Logic: On price update → INSERT new row to `price_history` (never UPDATE existing) → UPDATE `stock.default_price_sen` cache only
  - Verification: Unit test that old transactions retain `price_at_transaction_sen` unchanged after price update
  - UI: `PriceHistoryTimeline` shows all historical prices with reason and timestamp

### Testing & Verification
- [ ] ACT-38 — Tests: vision use cases + price history isolation
  - Vision tests: Mock `AiService` returning parsed product/receipt JSON; verify compression + base64 encoding
  - Price isolation test: Insert transaction at price X → update stock price to Y → verify transaction still shows X
  - Append-only test: Attempt to UPDATE or DELETE `price_history` row → should fail or be impossible via repository interface

### M3 Verification Gates
- [ ] `flutter analyze` — 0 issues, 0 warnings
- [ ] `flutter test test/features/vision/ test/features/catalog/` — all tests pass
- [ ] Camera permissions verified: `permission_handler` requests `camera` and `microphone` at runtime with rationale dialog
- [ ] Price isolation proven: Integration test with real SQLite database shows old transactions unaffected by price changes
- [ ] Vision pre-processing: Image compression reduces file to ≤512KB without crashing on low-RAM devices
- [ ] No price in vision product output: Unit test asserts `parse_product_from_image` JSON never contains `price` field

---

## ⬜ Milestone 4: UI/UX Polish & Audit

### Dashboard & Navigation
- [ ] ACT-39 — Bento Box dashboard per PRD §12.2
  - Layout: Full-width omzet card, 2-column profit/modal cards, pending banner (conditional), horizontal scroll stock alerts, 5 recent transactions list
  - Styling: Border 0.5px `#E0E0E0`, radius 12px, elevation 0px, background `#FFFFFF` on scaffold `#F8F9FA`
  - Reactivity: All cards update via Riverpod without full rebuild
- [ ] ACT-40 — Expandable FAB — 3 sub-FABs per PRD §12.3
  - Main FAB: Center, appears on tabs 1/2/3
  - Sub-FABs: 🎤 Suara (voice long-input), 📷 Foto (camera with bottom sheet choice), ✏️ Manual (form fallback)
  - Behavior: Tap FAB to expand, tap × to close; dim overlay when expanded; sub-FAB foto shows bottom sheet: "Foto Struk Supplier" / "Foto Kemasan Produk"
  - AI-aware: Disable voice/foto sub-FABs when `AppInitState != ModelReady` with tooltip "AI sedang memuat..."

### Audit & Feedback Systems
- [ ] ACT-41 — Audit log drawer per PRD §9.4
  - Trigger: Swipe or tap on any transaction → bottom drawer slides up
  - Content: STT transcript (if voice), raw AI JSON output (verbatim), idempotency key, input method badge, timestamp chain
  - Styling: Monospace font for JSON, copy-to-clipboard button for raw output
  - Verification: Raw JSON matches exactly what `AiService.infer()` received before `_stripJsonFences()`
- [ ] ACT-42 — Toast system per PRD §12.8
  - Types: Success (auto-dismiss 3s), Info (4s), Warning (manual dismiss), Error (manual dismiss — never auto)
  - Implementation: Global `ScaffoldMessenger` wrapper with type-based duration logic
  - Content: Indonesian messages, actionable where possible (e.g., "Coba lagi" button on error)
- [ ] ACT-43 — Haptic matrix per PRD §12.6
  - Implementation: `Vibration.vibrate()` calls with pattern:
    - Success confirmed: 1 × 50ms
    - Success pending: 2 × (30ms on, 50ms off)
    - Clarification needed: 3 × 30ms rapid
    - Bulk confirm done: 1 × 120ms
    - Error/validation fail: 3 × 100ms heavy
    - Destructive action: 1 × 100ms heavy
  - Fallback: Check `Vibration.hasVibrator()` before calling; silent if not available

### Screen Verification
- [ ] ACT-44 — Screen-by-screen UI verification (16 screens) per PRD §4.2 & §12
  - Screens to verify:
    1.  Beranda (Dashboard) — bento layout, pending banner, stock alerts
    2.  Pending Review — list with badges, voice confirm button, clarification flow
    3.  Laporan & Histori — period selector, list (chart optional per cut priority)
    4.  Katalog Barang — list, search, filter, FAB actions
    5.  Master Kategori (drawer) — CRUD with confirmation on delete
    6.  Detail Barang + History Harga — timeline, edit price (adds new history entry)
    7.  Detail Transaksi + Audit Log — drawer with raw JSON, transcript
    8.  Setelan — profile, AI settings, backup, delete data
    9.  Onboarding — conversational, zero keystroke, voice-only
    10. Receipt Capture — camera, compression progress, preview card
    11. Product Capture — camera, pre-fill form, voice price prompt
    12. Manual Transaction Form — fallback with validation
    13. Manual Stock Form — add/edit item with category picker
    14. Export Preview — PDF/CSV options, period selection
    15. Model Download Screen — progress bar, ETA, cancel/resume (Section 16)
    16. AI Degraded Banner — yellow/red/gray banners per init state
  - Verification criteria:
    - Touch targets ≥48dp (use Flutter DevTools inspector)
    - Text sizes: body 16-18sp, labels ≥16sp, headings 20-24sp
    - Contrast: WCAG AAA (7:1) for all text/background pairs
    - No overflow on 360x800 (small) and 414x896 (large) viewports
    - All interactive elements have haptic feedback per matrix

### M4 Verification Gates
- [ ] `flutter analyze` — 0 issues, 0 warnings
- [ ] 16 screens match docs/design/ PNGs — visual regression test via `golden_tests/`
- [ ] No overflow pada 360x800 dan 414x896 — tested via `flutter run` with `--device-id` emulator profiles
- [ ] All badges and banners update reactively via Riverpod without manual `setState`
- [ ] Audit log drawer shows verbatim `ai_raw_output` — copy-paste matches inference input exactly
- [ ] Haptic patterns match PRD §12.6 — verified via device vibration sensor or log output

---

## ⬜ Milestone 5: Testing & QA

### Unit & Widget Tests
- [ ] ACT-45 — Unit tests: `money_formatter.dart`, `uuid_helper.dart`
  - Money tests: "45000" → 4500000 sen, 4500000 → "Rp 45.000", float input rejected
  - UUID tests: v7 is time-sortable, v4 is random, no collisions in 10k iterations
- [ ] ACT-46 — Widget tests: `dashboard.dart`, `pending_banner.dart`, `audit_drawer.dart`
  - Dashboard: Bento cards render with correct data, pending banner appears/disappears reactively
  - PendingBanner: Tap opens confirmation flow, count updates on transaction change
  - AuditDrawer: Shows raw JSON, copy button works, timestamps formatted correctly

### Integration Tests
- [ ] ACT-47 — Integration test: idempotency per PRD §10.2
  - Setup: Real SQLite in-memory database via `$FloorAppDatabase.inMemoryDatabaseBuilder()`
  - Action: Insert same transaction twice with identical `idempotency_key`
  - Assertion: Only 1 row exists in `transactions` table; no exception thrown
- [ ] ACT-48 — Integration test: price history isolation per PRD §10.6
  - Setup: Insert stock item with price 10000 sen → insert transaction at that price → update stock price to 15000 sen
  - Assertion: Transaction still shows `price_at_transaction_sen: 1000000`; new `price_history` entry exists; `stock.default_price_sen` updated to 15000

### AI Runtime Tests (Section 16)
- [ ] ACT-49 — Unit tests: `InferenceRetry.runWithRetry()` per PRD §16.5
  - Test timeout: Mock `AiService` that delays >30s → verify `InferenceTimeoutFailure` returned after 30s
  - Test retry: Mock service that fails first call, succeeds second → verify 1 retry with 1s backoff
  - Test no retry on `InvalidJsonOutputFailure` → verify fallback to Level 1 repair instead
- [ ] ACT-50 — Unit tests: `Level1JsonRepair.attempt()` per PRD §16.6.1
  - Test fence stripping: Input with ```json ... ``` → output clean JSON
  - Test retry with reinforcement prompt: Malformed JSON → retry with stricter prompt → success
- [ ] ACT-51 — Unit tests: `ImageQualityGate.validate()` per PRD §16.7
  - Test file size: <10KB → `ImageQualityFailReason.fileTooSmall`
  - Test resolution: <400x400 → `resolutionTooLow`
  - Test brightness: Sampled luminance <40 → `tooDark`
  - Test pass: Valid image → `ImageQualityPass`

### Coverage & Security
- [ ] ACT-52 — Code coverage report per PRD §13.2
  - Command: `flutter test --coverage`
  - Target: >80% coverage on `features/*/domain/` and `features/*/data/`
  - Exclusion: UI/presentation layer may be lower; focus on business logic
- [ ] ACT-53 — Zero network imports verification per PRD Appendix D
  - Command: `grep -r "import.*http|import.*dio|import.*cloud" lib/ --exclude="*model_download*"`
  - Expected: 0 matches (only `model_download_service.dart` may import `dio`)
- [ ] ACT-54 — Offline compliance test per PRD §3.2
  - Setup: Physical Android device ≤4GB RAM, Airplane Mode ON
  - Actions: Record voice transaction, capture receipt photo, confirm pending, export report
  - Verification: All actions succeed; `Android Network Profiler` shows 0 outbound connections after model download

### M5 Verification Gates
- [ ] `flutter test --coverage` >80% domain/data layer coverage
- [ ] Zero network imports di test files — `grep` returns 0 matches
- [ ] All integration tests pass on physical device with Airplane Mode ON
- [ ] `flutter drive` end-to-end test: Full user journey (onboarding → transaction → report) completes offline
- [ ] Memory pressure test: App does not crash when backgrounded during inference; model not reloaded unnecessarily

---

## ⬜ Milestone 6: AI Runtime Technical Specification (Section 16)

### Model Delivery Strategy
- [ ] ACT-55 — Implement `ModelStorage` class per PRD §16.1.1
  - Path: `getApplicationDocumentsDirectory()/models/gemma-4-E2B-it-litertlm-Q4_K_M.litertlm`
  - Method: `isModelReady()` checks file existence + SHA-256 verification via `crypto: ^3.0.3`
  - SHA-256: Hardcoded hash in `ModelStorage` (placeholder to be replaced with official hash)
- [ ] ACT-56 — Implement `ModelDownloadConfig` per PRD §16.1.2
  - Primary URL: Kaggle Models endpoint
  - Fallback URL: GitHub Releases mirror
  - Expected file size: ~2.5GB constant for progress calculation
- [ ] ACT-57 — Implement `ModelDownloadNotifier` with Dio resume support per PRD §16.1.3
  - State management: `DownloadIdle`, `DownloadProgress` (with percent, bytes, ETA), `DownloadVerifying`, `DownloadComplete`, `DownloadFailed`
  - Resume logic: Check existing file size, send `Range: bytes=XXX-` header
  - SHA-256 verification post-download: Delete file and return `DownloadFailed` if mismatch
  - Fallback retry: If primary URL fails, automatically try fallback URL with same resume logic
- [ ] ACT-58 — Implement `ModelDownloadScreen` UI per PRD §16.1.4
  - Fullscreen overlay during download (blocking UX)
  - Linear progress bar with percentage, downloaded/total bytes, ETA
  - Verification step: Circular progress + "Memverifikasi integritas file..."
  - Error state: Icon, reason text, "Coba Lagi" button that restarts download
  - Accessibility: 16sp+ text, high contrast, touch targets ≥48dp

### Cold Start UX & Degraded Mode
- [ ] ACT-59 — Implement `AppInitState` sealed class per PRD §16.2.1
  - Variants: `AppInitModelDownloading`, `AppInitModelLoading`, `AppInitModelReady`, `AppInitModelFailed(reason)`, `AppInitAiDegraded(reason)`
  - Location: `lib/core/ai/app_init_state.dart`
- [ ] ACT-60 — Implement `AppInitNotifier` state machine per PRD §16.2.1
  - Flow: Check `ModelStorage.isModelReady()` → if false, start download and listen to `modelDownloadProvider`; if true, load model via `GemmaIsolateService.initialize()`
  - Error handling: Catch model load exceptions → set state to `AppInitModelFailed`
  - Integration: Listens to `modelDownloadProvider` for download completion/failure
- [ ] ACT-61 — Implement `AiLoadingBanner` for degraded mode per PRD §16.2.2
  - Condition: Show only when `AppInitState == AppInitModelLoading`
  - UI: Yellow banner with circular progress indicator, text "AI sedang memuat — fitur suara & foto akan aktif sebentar lagi"
  - Placement: Top of dashboard, above bento grid
- [ ] ACT-62 — Implement `AiAwareFab` per PRD §16.2.2
  - Logic: Disable voice/foto sub-FABs when `initState is! AppInitModelReady`
  - UX: Grayed out icons, tooltip "AI sedang memuat...", manual sub-FAB always enabled
  - Integration: Watch `appInitProvider` via Riverpod `ConsumerWidget`
- [ ] ACT-63 — Implement `AiDegradedBanner` for Level 2 fallback per PRD §16.6.2
  - Condition: Show when `AppInitState == AppInitAiDegraded`
  - UI: Red banner with warning icon, text "AI sedang bermasalah — gunakan input manual", "Coba Lagi" button
  - Action: Button triggers `appInitProvider.notifier.initialize()` to retry model load
- [ ] ACT-64 — Implement `PermanentManualModeBanner` for Level 3 fallback per PRD §16.6.3
  - Condition: Show when `AppInitState == AppInitModelFailed`
  - UI: Dark gray banner, text "Mode Manual Aktif — fitur AI tidak tersedia"
  - Behavior: FAB voice/foto buttons completely removed from UI (not just disabled)

### Gemma 4 E2B Capability & Constraints
- [ ] ACT-65 — Implement `PromptBudget` constants per PRD §16.3.1
  - Values: `contextWindowTokens = 8192`, `maxPromptTokens = 6000`, `maxOutputTokens = 512`, `safetyMarginTokens = 1680`
  - Usage: Enforce in all `AiService.infer()` calls via `maxTokens` parameter
- [ ] ACT-66 — Document token estimation logic per PRD §16.3.2
  - Location: Comment block in `voice_transaction_prompt.txt` or separate `token_budget.md`
  - Content: ~30 tokens per transaction item → 512 tokens supports ~17 items → sufficient for real-world usage (max 10-12 items per utterance)
- [ ] ACT-67 — Implement `GemmaCapabilityCheck.checkVisionSupport()` per PRD §16.3.3
  - Method: Send 1x1 pixel dummy base64 image with simple prompt
  - Success: Return `true` if non-empty response
  - Failure: Catch exception, return `false`, log warning, disable vision FABs
  - Integration: Call during `AppInitNotifier._loadModel()` after model load success
- [ ] ACT-68 — Document streaming limitation per PRD §16.3.4
  - Location: Comment in `gemma_ai_service.dart` or `README.md`
  - Content: `flutter_gemma ^0.2.0` does not support token streaming; UI shows `CircularProgressIndicator` during inference; acceptable for 5-8s voice inference latency

### STT Offline Verification
- [ ] ACT-69 — Implement `VoiceInitResult` sealed class per PRD §16.4.1
  - Variants: `VoiceInitSuccess`, `VoiceInitFailed(reason)`, `VoiceInitMissingPack`
  - Usage: Return from `VoiceService.initialize()` to inform UI of language pack status
- [ ] ACT-70 — Implement `id-ID` locale check in `VoiceServiceImpl` per PRD §16.4.1
  - Logic: After `_stt.initialize()`, call `_stt.locales()` and check `any((locale) => locale.localeId.startsWith('id'))`
  - Return: `VoiceInitMissingPack()` if not found
- [ ] ACT-71 — Implement `LanguagePackDialog` with deep link per PRD §16.4.2
  - UI: AlertDialog with title "Bahasa Belum Terpasang", explanation text, "Nanti" and "Buka Pengaturan" buttons
  - Deep link: `android-app://com.android.settings/.LanguageSettings` via `url_launcher`
  - Fallback: If deep link fails, open general settings `package:com.android.settings`
  - Behavior: `barrierDismissible: false` — user must explicitly choose
- [ ] ACT-72 — Configure VAD and confidence thresholds per PRD §16.4.3
  - Constants in `VoiceConfig`: `vadSilenceThresholdMs = 2000`, `localeId = 'id-ID'`, `maxListenDurationMs = 30000`, `minConfidenceScore = 0.5`
  - Usage: Pass to `_stt.listen()` parameters: `pauseFor`, `localeId`, `listenFor`, and filter `onResult` by `confidence`
- [ ] ACT-73 — Document noise limitation per PRD §16.4.4
  - Location: `README.md` or `KNOWN_LIMITATIONS.md`
  - Content: No audio pre-processing; relies on Android engine; accuracy may decrease in high-noise warung environments; not in hackathon scope

### Inference Timeout & Retry Logic
- [ ] ACT-74 — Implement `InferenceRetry` wrapper per PRD §16.5.3
  - Constants: `_maxRetries = 2`, `_firstBackoffMs = 1000`, `_secondBackoffMs = 3000`, `_voiceTimeoutSec = 30`, `_visionTimeoutSec = 45`
  - Method: `runWithRetry()` — wraps `AiService.infer()` with timeout and retry logic
  - Timeout: Use `.timeout()` with `onTimeout` returning `InferenceTimeoutFailure`
  - Retry condition: Only retry on `InferenceTimeoutFailure` or `ModelNotLoadedFailure`; not on `InvalidJsonOutputFailure`
  - Backoff: `Future.delayed()` between retries
- [ ] ACT-75 — Integrate `InferenceRetry` into all agent use cases per PRD §16.5.3
  - Files to update: `record_voice_transaction_usecase.dart`, `parse_receipt_usecase.dart`, `parse_product_usecase.dart`, `confirm_pending_usecase.dart`, `setup_business_usecase.dart`
  - Pattern: Replace direct `aiService.infer()` call with `InferenceRetry.runWithRetry(...)`

### Fallback Hierarchy
- [ ] ACT-76 — Implement Level 1: `Level1JsonRepair.attempt()` per PRD §16.6.1
  - Logic: Try `_stripJsonFences()` on raw output → parse → if fails, retry inference with reinforcement prompt suffix
  - Reinforcement prompt: Append explicit JSON-only instruction to system prompt
  - Integration: Called in use cases when `InvalidJsonOutputFailure` received from `InferenceRetry`
- [ ] ACT-77 — Implement Level 2: `AppInitAiDegraded` state + banner per PRD §16.6.2
  - Trigger: After Level 1 fails or retry exhausted
  - Action: Set `appInitProvider` state to `AppInitAiDegraded`, show red banner, disable AI FABs, auto-open manual form
  - Session scope: State resets on app restart; if model loads successfully later, return to normal
- [ ] ACT-78 — Implement Level 3: `AppInitModelFailed` permanent manual mode per PRD §16.6.3
  - Trigger: Model load fails permanently (RAM, corruption, LiteRT crash)
  - Action: Set state to `AppInitModelFailed`, show gray banner, remove voice/foto FABs entirely
  - Data safety: All manual transactions still save to SQLite with `input_method: 'manual'`; audit log, reports, export all functional

### Vision Input Quality Gate
- [ ] ACT-79 — Implement `ImageQualityResult` sealed class + `ImageQualityFailReason` enum per PRD §16.7.1
  - Result variants: `ImageQualityPass`, `ImageQualityFail(reason)`
  - Fail reasons: `fileTooSmall`, `resolutionTooLow`, `tooDark`
- [ ] ACT-80 — Implement `ImageQualityGate.validate()` per PRD §16.7.2
  - Checks: File size ≥10KB, resolution ≥400x400px, brightness ≥40/255 via 100-pixel sampling
  - Brightness calculation: ITU-R BT.709 luminance formula on sampled pixels
  - Efficiency: Sample 10x10 grid of pixels rather than full image decode for speed
- [ ] ACT-81 — Implement `ImageQualityFailDialog` per PRD §16.7.3
  - UI: AlertDialog with icon, title, specific message per failure reason, "Foto Ulang" and "Batal" buttons
  - Return: `Future<bool>` — true if user chooses retry, false if cancel
  - Behavior: `barrierDismissible: false` — explicit user choice required
- [ ] ACT-82 — Integrate quality gate into vision use cases per PRD §16.7.4
  - Flow in `parse_receipt_usecase.dart` and `parse_product_usecase.dart`:
    1.  Call `ImageQualityGate.validate(imageFile)` before any compression/inference
    2.  If fail: Show dialog; if user chooses retry, return `Error(ImageUnreadableFailure())` to trigger camera reopen
    3.  If pass: Proceed to compress → base64 encode → inference
  - Error handling: If compression fails or returns null, return `ImageUnreadableFailure`

### DI Integration for Section 16
- [ ] ACT-83 — Register new Section 16 services in `injection.dart` per PRD §16.8
  - Add: `ModelDownloadNotifier` (lazy singleton), `ImageQualityGate` (factory), `ParseReceiptUseCase`, `RecordVoiceTransactionUseCase` (factories with `AiService` dependency)
  - Verify: `build_runner` generates updated `injection.config.dart` with no errors

### M6 Verification Gates (Section 16)
- [ ] Model delivery: File not bundled in APK; download on first launch with progress UI; SHA-256 verification passes; fallback URL works if primary fails
- [ ] Cold start UX: `AppInitState` transitions correctly; degraded mode banners appear/disappear based on state; manual input always available
- [ ] Gemma capability: Context window limit enforced (6000 token prompt max); vision support check runs on cold start; no streaming assumed
- [ ] STT offline: `id-ID` locale check works; language pack dialog deep link opens Android settings; VAD threshold = 2000ms; min confidence = 0.5
- [ ] Timeout & retry: Voice inference times out at 30s, vision at 45s; max 2 retries with 1s/3s backoff; `InferenceRetry` used in all agents
- [ ] Fallback hierarchy: Level 1 repairs malformed JSON; Level 2 disables AI FABs with red banner; Level 3 permanent manual mode with gray banner; all data safe in SQLite
- [ ] Vision quality gate: File size, resolution, brightness checks run before inference; specific dialog shown per failure; quality gate integrated in use cases
- [ ] DI integration: All Section 16 classes registered in `injection.dart`; `build_runner` succeeds

---

## ⬜ Milestone 7: Deliverables & Submission

### Build & Distribution
- [ ] ACT-84 — APK build config per PRD Appendix D
  - Command: `flutter build apk --obfuscate --split-debug-info=build/symbols --split-per-abi`
  - Verification: APK size <150MB (model not bundled); install on physical device ≤4GB RAM; runs in Airplane Mode
  - Obfuscation: `--obfuscate` flag applied; symbols map saved for debugging
- [ ] ACT-85 — GitHub release preparation
  - Assets: APK file, `SHA256SUMS.txt`, `README.md` with install instructions
  - Tag: `v1.0.0-hackathon` with release notes mapping to PRD sections
  - License: Apache 2.0 header in all Dart files; `LICENSE` file in repo root

### Documentation & Proof
- [ ] ACT-86 — Kaggle Notebook outline implementation per PRD §14.1
  - Sections to implement:
    1.  Setup & Model Loading: Load Gemma 4 E2B, verify LiteRT runtime
    2.  Function Calling Proof — Agent 2: Voice multi-item input → JSON array → schema validation
    3.  Function Calling Proof — Agent 3: "semua benar" and "ganti lima puluh ribu" → confirm/edit actions
    4.  Multimodal Vision Proof — Agent 4: Receipt image → parsed transactions → accuracy vs ground truth
    5.  Multimodal Vision Proof — Agent 5: Product packaging → name+category (no price) → verify no price field
    6.  JSON Robustness Test: Malformed output with fences/trailing text → `_stripJsonFences()` success
    7.  Integer Money Validation: "45.000" → 4500000 → "Rp 45.000"; float vs integer precision comparison
    8.  Price History Isolation: Insert old-price transaction → update price → verify transaction unchanged
    9.  Performance Benchmark: Inference time per query (voice/vision), memory usage estimate
  - Output: Public Kaggle Notebook URL in submission
- [ ] ACT-87 — Logcat proof strategy per PRD §9.4 & Appendix D
  - Implementation: Add `logger` package with `WarungPintar/AuditLog` tag for all audit log inserts
  - Verification step: Record Logcat output during demo showing raw AI JSON in real-time
  - Filter command: `adb logcat -s WarungPintar/AuditLog`
- [ ] ACT-88 — Network profiler proof per PRD Appendix D
  - Tool: Android Studio Network Profiler or `adb shell dumpsys netstats`
  - Test scenario: After model download complete, perform voice transaction, receipt scan, report export
  - Expected: 0 outbound HTTP connections during normal operation (only model download phase uses network)
- [ ] ACT-89 — YouTube video storyboard implementation per PRD §15.2
  - Timestamps to hit:
    - [0:00-0:20] Hook: Busy warung, Ibu Warsih overwhelmed
    - [0:20-0:40] Problem: Software too complex, no internet, no time to type
    - [0:40-1:05] Onboarding: Airplane Mode visible, voice setup, dashboard populates
    - [1:05-1:35] Long-speech multi-item: One mic tap, 4 items, pending banner appears, timer <8s
    - [1:35-1:55] Voice bulk confirm: "Semua benar", pending badge disappears, dashboard updates
    - [1:55-2:20] Vision receipt: Photo nota, parsing, preview, confirm
    - [2:20-2:40] Vision product + audit log: Photo packaging, pre-fill, voice price, split-screen raw JSON
    - [2:40-2:55] Impact: End-of-day PDF export, profit shown, notebook closed
    - [2:55-3:00] Outro: Logo, Gemma 4 Good badge, GitHub/APK links
  - Technical: Airplane Mode visible in status bar in ≥3 scenes; timer overlay for performance metrics; split-screen for audit log proof

### Final Checklist & Submission
- [ ] ACT-90 — Appendix D technical checklist completion
  - Run all verification commands: `flutter analyze`, `flutter test`, `grep` for network imports, APK install test
  - Document results: Screenshot of `flutter analyze` output, test coverage report, Logcat filter output
- [ ] ACT-91 — Section 16 technical checklist completion
  - Verify all items in PRD §16.9: model delivery, cold start UX, Gemma capability, STT offline, timeout/retry, fallback hierarchy, vision quality gate
  - Document: Screenshots of download progress, degraded mode banners, language pack dialog, quality gate rejection dialog
- [ ] ACT-92 — Kaggle writeup draft (<1500 words) per PRD §15.1
  - Sections:
    1.  Digital Equity Gap (200 words): Why cloud SaaS fails for UMKM; Ibu Warsih pain points
    2.  Five Gemma 4 Agents (500 words): Onboarding, voice kasir, voice confirm, vision receipt, vision product
    3.  Enterprise Integrity at Edge (400 words): Immutable price history, non-blocking pending, UUIDv7, idempotency, raw AI audit log
    4.  Technical Proof (200 words): Kaggle Notebook, Logcat, APK demo
    5.  Roadmap (100 words): P2P Bluetooth sync, local RAG, offline
    6.  Links (100 words): GitHub repo, APK release, YouTube video
- [ ] ACT-93 — Final submission bundle
  - Contents:
    - GitHub repo URL (public, Apache 2.0)
    - Kaggle Notebook URL (public)
    - YouTube video URL (unlisted or public)
    - APK file (via GitHub Releases)
    - PDF writeup (<1500 words)
    - Screenshot pack: Logcat proof, Network Profiler proof, Airplane Mode visible, audit log drawer with raw JSON
  - Verification: All links accessible; APK installs and runs offline; video meets 3-minute limit

### M7 Verification Gates
- [ ] `flutter build apk --obfuscate --split-debug-info=build/symbols` — success, APK <150MB
- [ ] Appendix D checklist — 100% pass (all technical items verified)
- [ ] Section 16 checklist — 100% pass (all AI runtime items verified)
- [ ] Kaggle Notebook — public, executable, all 9 sections implemented with outputs
- [ ] YouTube video — ≤3:00 duration, Airplane Mode visible in ≥3 scenes, timer overlays for performance metrics
- [ ] Writeup — <1500 words, covers all 6 sections, links included
- [ ] GitHub repo — public, Apache 2.0 license, README with install/test instructions, architecture diagram
- [ ] Zero network requests during demo — Logcat and Network Profiler proofs included in submission

---

## 🔄 Cross-Milestone Dependencies & Blockers

### Critical Path Dependencies
1.  **M0 → M1**: `AiService` interface must be stable before implementing `GemmaAiService` and system prompts
2.  **M1 → M2**: `Result<ToolCallResult, AiFailure>` pattern must be finalized before agent use cases can be written
3.  **M2 → M3**: Transaction `pending` workflow must be working before vision agents can insert into same queue
4.  **M3 → M4**: Price history append-only logic must be proven before UI timeline can be built
5.  **Section 16 → All**: Model download and cold start state machine must be implemented before any AI-dependent feature can be tested on real device

### Known Blockers & Mitigations
- **Blocker**: Gemma 4 E2B model file not publicly available for download
  - Mitigation: Use placeholder model for development; document SHA-256 verification step for when official file is released; use Kaggle Notebook for inference proof instead of on-device for submission
- **Blocker**: `flutter_gemma ^0.2.0` vision support unconfirmed on low-RAM devices
  - Mitigation: Implement `GemmaCapabilityCheck.checkVisionSupport()`; if false, disable vision FABs and show informative message; fallback to manual input
- **Blocker**: Android `SpeechRecognizer` id-ID pack not pre-installed on all devices
  - Mitigation: Implement `LanguagePackDialog` with deep link; document in README that user must install language pack via Android settings before first use
- **Blocker**: 2.5GB model download may exceed user data limits or storage
  - Mitigation: Show clear progress + ETA; allow cancel/resume; store in app documents directory (not internal cache); document storage requirement in onboarding

### Rollback Strategy
- If Section 16 implementation blocks submission timeline:
  1.  Cut model download complexity: Bundle small test model in APK for demo only (document this is demo-only, not production)
  2.  Cut vision quality gate: Skip brightness/resolution checks, rely on user to take clear photos (document as known limitation)
  3.  Cut fallback hierarchy Levels 2-3: Only implement Level 1 JSON repair; if AI fails completely, show generic error and open manual form
- Never cut:
  - Integer money protocol (PRD §10.1)
  - Idempotency constraint (PRD §10.2)
  - Audit log append-only with raw AI output (PRD §9)
  - Pending non-blocking workflow (PRD §7)
  - Price history immutable (PRD §10.6)

---

> **Note**: This checklist is a living document. Update progress markers (`[ ]` → `[x]`) and commit hashes as work completes. All verification gates must pass before considering a milestone complete. When in doubt, refer to the source PRD v10.0.0 sections cited in each task.