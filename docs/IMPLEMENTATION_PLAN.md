# WarungPintar Cimahi — Master Implementation Plan

> **Sources**: `@docs/PRD.md` v10.0.0, `@AGENT.md` §17, `@docs/DESIGN.md`
> **Last Updated**: 2026-05-17
> **Version**: 2.0 — Reorganized by dependency order; Section 16 integrated

---

## Conflict Resolution (LOCKED)

| Konflik | Keputusan | Source |
|---------|-----------|--------|
| Font: Inter vs Plus Jakarta Sans | **Inter** | DESIGN.md wins |
| Primary: #005DAC vs #1976D2 | **#005DAC** | DESIGN.md wins |
| Confirmed green: #059669 vs #1B6D24 | **#059669** | PRD §12.7 (WCAG validated) |
| Gemma package | **flutter_gemma: ^0.2.0** | User approved |
| Test mocking | **mocktail** (bukan mockito) | User confirmed |
| Model delivery | **Download on first launch** (bukan bundle APK) | PRD §16.1 |
| STT engine | **Android SpeechRecognizer API** (on-device, bukan cloud) | PRD §16.4 |
| Inference timeout voice | **30 detik** | PRD §16.5 |
| Inference timeout vision | **45 detik** | PRD §16.5 |
| Max retry | **2x dengan backoff 1s → 3s** | PRD §16.5 |
| Context window budget | **6.000 token prompt, 512 token output** | PRD §16.3 |

**Rule**: Visual tokens → DESIGN.md. Business logic/accessibility → PRD.md. Ambiguous → STOP & ask.

---

## Workflow Rules (Per AGENT.md §17)

Setiap **action** adalah unit kerja atomik dan terverifikasi:

1. Pre-commit: `flutter analyze` HARUS 0 issues
2. Commit: `git add -A && git commit -m "feat: [ACT-XX] - [deskripsi]"`
3. TIDAK BOLEH `git push`
4. Post-commit: `git diff HEAD~1..HEAD --stat` + `git log -1 --name-status`
5. Report: file yang berubah, scope confirmation, zero broken imports
6. Multi-turn: squash/amend, report sebagai "Action X - Turn Y"

---

## Dependency Layer Overview

```
Layer 0 — Foundation (no external deps)
  └── M0: pubspec, analysis, folder structure, DI skeleton, error types,
          theme, router, colors, formatters

Layer 1 — AI Core Infrastructure (requires Layer 0)
  └── M1: ToolCallResult, JSON parser, Gemma isolate, AiService interface + impl,
          system prompts, ModelStorage, ModelDownloadService, AppInitState machine

Layer 2 — Data Infrastructure (requires Layer 0; parallel dengan Layer 1)
  └── M2-DATA: SQLite DDL lengkap, DatabaseService impl,
               VoiceService + STT offline check, ImageQualityGate,
               InferenceRetry wrapper, Fallback Level 1–3 stubs

Layer 3 — Domain + Agent Logic (requires Layer 1 + Layer 2)
  └── M3: Transaction domain/data, Onboarding agent,
          Voice agents (Agent 2 + 3), Vision agents (Agent 4 + 5),
          Catalog domain/data, Price history, Audit log datasource

Layer 4 — Presentation (requires Layer 3)
  └── M4: Dashboard bento, FAB (AI-aware), Banners (loading/degraded/failed),
          Audit log drawer, Toast system, Haptic matrix, Screen verification

Layer 5 — Testing & QA (requires Layer 4)
  └── M5: Unit tests domain/utils, Widget tests, Integration tests
  └── M7: Section 16 QA — model delivery, cold start, STT, fallback, quality gate

Layer 6 — Deliverables (requires Layer 5)
  └── M6: APK obfuscated, Kaggle notebook, Logcat proof, Final checklist
```

---

## Milestone 0: Foundation & DI & Router ✅ COMPLETE

> **Layer 0** — Tidak ada dependency eksternal. Semua milestone lain bergantung pada ini.

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-00 | Fix pubspec.yaml — tambah semua pre-approved deps termasuk `dio: ^5.4.0` dan `crypto: ^3.0.3` (Section 16) | pubspec.yaml | ✅ Done |
| ACT-01 | Enforce analysis_options.yaml per PRD Appendix C | analysis_options.yaml | ✅ Done |
| ACT-02 | Buat folder structure per PRD §5.1 — tambah `core/ai/fallback/`, `core/vision/`, `core/voice/` untuk Section 16 | lib/ directory tree | ✅ Done |
| ACT-03 | Extract AiService interface → `core/ai/ai_service.dart` | core/ai/, core/di/ | ✅ Done |
| ACT-04 | Extract DatabaseService → `core/database/database_service.dart` | core/database/, core/di/ | ✅ Done |
| ACT-05 | Buat error/failures.dart — AiFailure sealed class hierarchy termasuk `ImageUnreadableFailure` | core/error/ | ✅ Done |
| ACT-06 | Buat app_colors.dart + app_strings.dart dari DESIGN.md tokens | core/constant/ | ✅ Done |
| ACT-07 | Buat money_formatter.dart + uuid_helper.dart | core/utils/ | ✅ Done |
| ACT-08 | Enhance app_theme.dart — full DESIGN.md typography scale | core/theme/ | ✅ Done |
| ACT-09 | Restructure app_router.dart — PRD §4.1 paths + onboarding redirect + model download redirect | core/router/ | ✅ Done |
| ACT-10 | Run build_runner, verifikasi injection.config.dart | core/di/ | ✅ Done |
| **VERIFY-M0** | `flutter pub get` ✅, `flutter analyze` ✅, folder `core/ai/fallback/` dan `core/vision/` ada ✅ | — | ✅ Pass |

**Catatan ACT-00**: `dio` dan `crypto` wajib hadir sejak M0 karena ACT-11 (ModelDownloadService) bergantung padanya. Jika belum ditambahkan saat ACT-00 selesai, lakukan amend sebelum lanjut ke M1.

---

## Milestone 1: AI Core Infrastructure ✅ COMPLETE

> **Layer 1** — Bergantung pada M0. Mencakup seluruh runtime AI: Gemma isolate, AiService, **plus** model delivery dan app init state machine dari PRD §16.1–16.2.

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-11 | Buat tool_call_result.dart sealed class + result.dart | core/ai/, core/error/ | ✅ Done |
| ACT-12 | Buat json_parser.dart — `_stripJsonFences()` + `parseToolCall()` per PRD §10.5 | core/ai/ | ✅ Done |
| ACT-13 | Buat gemma_isolate_service.dart — isolate infrastructure + `GemmaCapabilityCheck.checkVisionSupport()` per PRD §16.3.3 | core/ai/ | ✅ Done |
| ACT-14 | Update ai_service.dart — return `Result<ToolCallResult, AiFailure>` + `PromptBudget` constants (maxPrompt=6000, maxOutput=512) per PRD §16.3.1 | core/ai/ | ✅ Done |
| ACT-15 | Buat gemma_ai_service.dart — real impl via GemmaIsolateService | core/ai/ | ✅ Done |
| ACT-16 | Buat 5 system prompt files per PRD §6.3–6.7 | core/ai/prompts/ | ✅ Done |
| ACT-17 | Unit tests untuk json_parser + tool_call_result | test/core/ai/ | ✅ Done |
| ACT-18 | Run build_runner, wire DI GemmaAiService | core/di/ | ✅ Done |
| ACT-19 | **[SEC16]** Buat `ModelStorage` — path ke `getApplicationDocumentsDirectory/models/`, SHA-256 verification via `crypto` | core/ai/ | ⬜ Belum |
| ACT-20 | **[SEC16]** Buat `ModelDownloadConfig` — primaryUrl (Kaggle), fallbackUrl (GitHub Releases), `expectedFileSizeBytes` | core/ai/ | ⬜ Belum |
| ACT-21 | **[SEC16]** Buat `ModelDownloadState` sealed class + `ModelDownloadNotifier` — Dio resume download, progress callback, SHA-256 post-download, retry ke fallbackUrl | core/ai/ | ⬜ Belum |
| ACT-22 | **[SEC16]** Buat `AppInitState` sealed class — `ModelDownloading`, `ModelLoading`, `ModelReady`, `ModelFailed`, `AiDegraded` | core/ai/ | ⬜ Belum |
| ACT-23 | **[SEC16]** Buat `AppInitNotifier` — state machine lengkap: cek model → download jika perlu → load → ready/failed | core/ai/ | ⬜ Belum |
| ACT-24 | **[SEC16]** Wire `AppInitNotifier` + `ModelDownloadNotifier` ke GetIt; update `app_router.dart` — redirect ke `ModelDownloadScreen` jika state `ModelDownloading` | core/di/, core/router/ | ⬜ Belum |
| ACT-25 | **[SEC16]** Buat `ModelDownloadScreen` — LinearProgressIndicator + persentase + ETA + retry button per PRD §16.1.4 | core/ai/ atau features/onboarding/presentation/ | ⬜ Belum |
| **VERIFY-M1** | `flutter analyze` ✅, `flutter test test/core/ai/` ✅, `ModelStorage.isModelReady()` return bool ✅, `AppInitState` semua variant compile ✅ | — | ⬜ Belum |

**Dependency Note**: ACT-19–25 harus selesai sebelum M3 dimulai karena semua agent use case akan memanggil `InferenceRetry` yang bergantung pada `AppInitNotifier` state.

---

## Milestone 2: Data Infrastructure — Database, Voice, Vision Gate

> **Layer 2** — Bergantung pada M0. Dapat dikerjakan **paralel** dengan M1 jika ada dua working context. Harus selesai sebelum M3 dimulai.

### 2A — SQLite & Database

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-26 | Implement full SQLite DDL di `database_service.dart` per PRD §11 — WAL mode, semua tabel, semua index, foreign keys ON | core/database/ | ⬜ Belum |
| ACT-27 | Buat `AuditLogDatasource` — append-only insert, tidak ada UPDATE/DELETE, per PRD §9 | features/transaction/data/ | ⬜ Belum |
| ACT-28 | Integration test: idempotency — duplicate `idempotency_key` = 1 row di DB | test/integration/ | ⬜ Belum |
| ACT-29 | Integration test: price history isolation — update harga tidak mengubah `price_at_transaction_sen` lama | test/integration/ | ⬜ Belum |

### 2B — Voice Service & STT Offline

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-30 | **[SEC16]** Buat `VoiceInitResult` sealed class — `VoiceInitSuccess`, `VoiceInitFailed`, `VoiceInitMissingPack` | core/voice/ | ⬜ Belum |
| ACT-31 | **[SEC16]** Buat `VoiceConfig` — `vadSilenceThresholdMs=2000`, `localeId='id-ID'`, `maxListenDurationMs=30000`, `minConfidenceScore=0.5` | core/voice/ | ⬜ Belum |
| ACT-32 | **[SEC16]** Buat `VoiceServiceImpl` — init `SpeechToText`, cek ketersediaan locale `id-ID`, start listening dengan VAD config dari `VoiceConfig` | core/voice/ | ⬜ Belum |
| ACT-33 | **[SEC16]** Buat `LanguagePackDialog` — dialog + deep link ke Android Language Settings jika `id-ID` tidak tersedia, per PRD §16.4.2 | core/voice/ | ⬜ Belum |
| ACT-34 | Wire `VoiceServiceImpl` ke GetIt; panggil `voiceService.initialize()` di `AppInitNotifier` setelah model ready | core/di/, core/ai/ | ⬜ Belum |

### 2C — Vision Quality Gate

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-35 | **[SEC16]** Buat `ImageQualityFailReason` enum — `fileTooSmall`, `resolutionTooLow`, `tooDark` | core/vision/ | ⬜ Belum |
| ACT-36 | **[SEC16]** Buat `ImageQualityResult` sealed class + `ImageQualityGate` — validasi ukuran ≥10KB, resolusi ≥400×400, brightness sampling 100px rata-rata ≥40/255, per PRD §16.7.2 | core/vision/ | ⬜ Belum |
| ACT-37 | **[SEC16]** Buat `ImageQualityFailDialog` — pesan spesifik per `ImageQualityFailReason`, tombol "Foto Ulang" + "Batal", per PRD §16.7.3 | core/vision/ | ⬜ Belum |
| ACT-38 | Wire `ImageQualityGate` ke GetIt | core/di/ | ⬜ Belum |

### 2D — Inference Retry & Fallback Infrastructure

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-39 | **[SEC16]** Buat `InferenceRetry.runWithRetry()` — voice timeout 30s, vision timeout 45s, max 2 retry, backoff 1s→3s, per PRD §16.5.3 | core/ai/ | ⬜ Belum |
| ACT-40 | **[SEC16]** Buat `Level1JsonRepair.attempt()` — strip fence + retry inference 1x dengan reinforcement prompt suffix, per PRD §16.6.1 | core/ai/fallback/ | ⬜ Belum |
| ACT-41 | **[SEC16]** Buat helper `AppInitNotifier.markAsDegraded(reason)` — transisi ke `AiDegraded` state; buat `AppInitNotifier.markAsFailed(reason)` — transisi ke `ModelFailed` (permanent) | core/ai/ | ⬜ Belum |
| ACT-42 | Unit test: `InferenceRetry` — mock timeout → verify 2x retry → verify backoff → verify final Error return | test/core/ai/ | ⬜ Belum |
| ACT-43 | Unit test: `Level1JsonRepair` — input malformed JSON → verify strip → verify retry call → verify fallback | test/core/ai/ | ⬜ Belum |
| **VERIFY-M2** | `flutter analyze` ✅, `flutter test test/integration/` ✅, `flutter test test/core/ai/` (retry + repair) ✅, `VoiceConfig` semua konstanta defined ✅, `ImageQualityGate.validate()` return sealed class ✅ | — | ⬜ Belum |

---

## Milestone 3: Domain + Agent Logic

> **Layer 3** — Bergantung pada M1 (AI core + init state) dan M2 (database + voice + vision gate + retry). Semua agent use case **wajib** menggunakan `InferenceRetry.runWithRetry()` dan `Level1JsonRepair` — tidak boleh memanggil `AiService.infer()` langsung.

### 3A — Transaction Domain & Data

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-44 | Transaction domain layer — `TransactionEntity`, abstract `TransactionRepository`, usecases: `RecordVoiceTransactionUseCase`, `ConfirmTransactionUseCase`, `GetPendingTransactionsUseCase` | features/transaction/domain/ | ⬜ Belum |
| ACT-45 | Transaction data layer — `TransactionModel`, `TransactionDatasource`, `TransactionRepositoryImpl` | features/transaction/data/ | ⬜ Belum |
| ACT-46 | Unit test: `RecordVoiceTransactionUseCase` — mock `AiService` via mocktail, verify `InferenceRetry` dipakai, verify output masuk pending | test/features/transaction/ | ⬜ Belum |

### 3B — Agent 1: Onboarding

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-47 | Onboarding domain — `SetupBusinessUseCase` — parse `setup_business` tool call → insert categories + stock ke SQLite | features/onboarding/domain/ | ⬜ Belum |
| ACT-48 | Onboarding presentation — `OnboardingPage` + Riverpod `AutoDispose` provider + state machine 4 state (Listening → Inference → Execution → Feedback) | features/onboarding/presentation/ | ⬜ Belum |

### 3C — Agent 2 & 3: Voice Transaction + Confirmation

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-49 | Voice transaction provider (Agent 2) — `VoiceTransactionNotifier`: start STT → collect transcript → call `RecordVoiceTransactionUseCase` → insert pending → update Riverpod state | features/transaction/presentation/ | ⬜ Belum |
| ACT-50 | Pending confirmation provider (Agent 3) — `PendingConfirmNotifier`: load pending list → STT → `ConfirmTransactionUseCase` → handle `confirm_all` flag → update state | features/transaction/presentation/ | ⬜ Belum |
| ACT-51 | Unit test: `ConfirmTransactionUseCase` — verify "semua benar" → semua pending jadi confirmed; verify "skip" → item tetap pending | test/features/transaction/ | ⬜ Belum |

### 3D — Agent 4 & 5: Vision

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-52 | Vision domain — `ParseReceiptUseCase` (Agent 4) — **wajib**: run `ImageQualityGate.validate()` dulu → compress → `InferenceRetry.runWithRetry()` → `Level1JsonRepair` jika perlu → insert pending per PRD §16.7.4 | features/vision/domain/ | ⬜ Belum |
| ACT-53 | Vision presentation — `ReceiptCapturePage` + provider — camera intent → kirim ke `ParseReceiptUseCase` → tampilkan preview card | features/vision/presentation/ | ⬜ Belum |
| ACT-54 | Vision domain — `ParseProductUseCase` (Agent 5) — quality gate → inference → pre-fill form → STT untuk harga → insert ke `stock` | features/vision/domain/ | ⬜ Belum |
| ACT-55 | Vision presentation — `ProductCapturePage` + provider | features/vision/presentation/ | ⬜ Belum |
| ACT-56 | Unit test: `ParseReceiptUseCase` — mock `ImageQualityGate` return fail → verify dialog triggered, inference NOT called; mock pass → verify inference called | test/features/vision/ | ⬜ Belum |

### 3E — Catalog + Price History

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-57 | Catalog domain — `StockEntity`, `PriceHistoryEntity`, abstract `CatalogRepository`, usecases: `GetCatalogUseCase`, `AddItemUseCase`, `UpdateItemPriceUseCase` (append-only per PRD §10.6), `SoftDeleteItemUseCase` | features/catalog/domain/ | ⬜ Belum |
| ACT-58 | Catalog data — `StockModel`, `PriceHistoryModel`, `CatalogDatasource`, `CatalogRepositoryImpl` | features/catalog/data/ | ⬜ Belum |
| ACT-59 | Catalog presentation — list page, detail page, category drawer, add item via foto+suara | features/catalog/presentation/ | ⬜ Belum |
| ACT-60 | Unit test: `UpdateItemPriceUseCase` — verify insert ke `price_history`, BUKAN update kolom di `stock.default_price_sen` langsung; verify transaksi lama tidak berubah | test/features/catalog/ | ⬜ Belum |
| **VERIFY-M3** | `flutter analyze` ✅, semua agent unit tests ✅, `ParseReceiptUseCase` terbukti panggil quality gate sebelum inference ✅, `UpdateItemPriceUseCase` append-only verified ✅, camera permissions declared ✅ | — | ⬜ Belum |

---

## Milestone 4: Presentation Layer — UI/UX Polish

> **Layer 4** — Bergantung pada M3. Semua widget yang berinteraksi dengan AI **wajib** membaca `AppInitState` dari Riverpod — tidak boleh assume model selalu ready.

### 4A — Dashboard & Core Layout

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-61 | Dashboard domain — `DashboardSummaryUseCase` — hanya hitung transaksi `status = confirmed` untuk omzet/profit; hitung pending count terpisah | features/dashboard/domain/ | ⬜ Belum |
| ACT-62 | Bento Box dashboard — full impl per PRD §12.2: full-width omzet, 2-kolom profit/modal, scroll horizontal stock alert, 5 transaksi terakhir dengan badge ganda | features/dashboard/presentation/ | ⬜ Belum |
| ACT-63 | Pending banner — reactive via Riverpod, tap → buka Agent 3, badge count real-time | shared/widgets/ | ⬜ Belum |
| ACT-64 | Status badge widget — badge input method (biru/hijau/abu) + badge status (hijau/kuning/merah) per PRD §12.5 | shared/widgets/ | ⬜ Belum |

### 4B — AI-Aware FAB & Banners (Section 16)

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-65 | **[SEC16]** Buat `AiLoadingBanner` — tampil saat `AppInitModelLoading`, warna kuning `#FFF3CD`, teks + spinner kecil per PRD §16.2.2 | shared/widgets/ | ⬜ Belum |
| ACT-66 | **[SEC16]** Buat `AiDegradedBanner` — tampil saat `AppInitAiDegraded`, warna `#FFEDED`, icon warning + teks + tombol "Coba Lagi" yang trigger `AppInitNotifier.initialize()` per PRD §16.6.2 | shared/widgets/ | ⬜ Belum |
| ACT-67 | **[SEC16]** Buat `PermanentManualModeBanner` — tampil saat `AppInitModelFailed`, warna `#424242`, teks putih permanen per PRD §16.6.3 | shared/widgets/ | ⬜ Belum |
| ACT-68 | **[SEC16]** Buat `AiAwareFab` — FAB ekspansi 3 sub-tombol; Suara dan Foto `onTap = null` + tooltip "AI sedang memuat..." jika `AppInitState` bukan `ModelReady`; Manual selalu aktif; dim overlay saat expand per PRD §12.3 + §16.2.2 | shared/widgets/ | ⬜ Belum |
| ACT-69 | **[SEC16]** Integrasikan semua banner ke `DashboardPage` dalam urutan: `PermanentManualModeBanner` → `AiDegradedBanner` → `AiLoadingBanner` → pending banner → konten | features/dashboard/presentation/ | ⬜ Belum |

### 4C — Shared Widgets & UX

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-70 | Audit log drawer per PRD §9.4 — STT transcript, raw AI JSON, idempotency key, input method, timestamp chain | shared/widgets/ | ⬜ Belum |
| ACT-71 | Toast system per PRD §12.8 — sukses auto-dismiss 3s, info 4s, warning manual, error manual (TIDAK pernah auto) | shared/widgets/ | ⬜ Belum |
| ACT-72 | Haptic matrix per PRD §12.6 — 6 pola haptic berbeda via `vibration` package | core/utils/ | ⬜ Belum |
| ACT-73 | Screen-by-screen UI verification terhadap design PNGs — 16 screens, no overflow di 360×800 dan 414×896 | all presentation/ | ⬜ Belum |
| **VERIFY-M4** | `flutter analyze` ✅, 16 screens match design ✅, no overflow di kedua ukuran ✅, `AiAwareFab` disabled saat model tidak ready ✅, semua banner muncul di state yang benar ✅ | — | ⬜ Belum |

---

## Milestone 5: Testing & QA — Domain/Data Coverage

> **Layer 5A** — Unit dan integration tests untuk domain/data layer. Dapat dimulai incremental sejak M3 selesai.

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-74 | Unit test: `money_formatter` — `rupiahToSen('45000') == 4500000`, `senToDisplay(4500000) == 'Rp 45.000'`, tidak pernah float | test/core/utils/ | ⬜ Belum |
| ACT-75 | Unit test: `uuid_helper` — UUIDv7 time-sortable, no collision dalam 1000 generate | test/core/utils/ | ⬜ Belum |
| ACT-76 | Unit test: `json_parser` — fence stripping, missing `name` key, missing `arguments` key, empty string, nested malformed | test/core/ai/ | ⬜ Belum |
| ACT-77 | Widget test: `DashboardPage` — pending banner muncul jika ada pending, hilang jika tidak ada; omzet hanya tampil dari `confirmed` | test/features/dashboard/ | ⬜ Belum |
| ACT-78 | Widget test: `AuditLogDrawer` — STT transcript + raw JSON tampil | test/features/transaction/ | ⬜ Belum |
| ACT-79 | Integration test: idempotency — duplicate `idempotency_key` = 1 row (in-memory SQLite) | test/integration/ | ⬜ Belum |
| ACT-80 | Integration test: price history isolation — update harga → `price_history` bertambah 1 row, `price_at_transaction_sen` transaksi lama tidak berubah | test/integration/ | ⬜ Belum |
| **VERIFY-M5** | `flutter test --coverage` >80% domain/ dan data/ ✅, zero network call di semua tests ✅ | — | ⬜ Belum |

---

## Milestone 7: Section 16 QA — AI Runtime Verification

> **Layer 5B** — Verifikasi khusus semua implementasi PRD §16. Dapat berjalan paralel dengan M5 setelah M4 selesai. Ini adalah **gate** sebelum M6 (deliverables) — submission tidak boleh dimulai jika ada item merah di sini.

### 7A — Model Delivery Verification

| Action ID | Deskripsi | Verifikasi | Status |
|-----------|-----------|------------|--------|
| ACT-81 | Test `ModelStorage.isModelReady()` — file tidak ada → return false; file ada tapi SHA-256 salah → return false; file ada SHA-256 benar → return true | Unit test dengan file dummy | ⬜ Belum |
| ACT-82 | Test `ModelDownloadNotifier` — simulasi download sukses → state sequence: `DownloadIdle` → `DownloadProgress` → `DownloadVerifying` → `DownloadComplete` | Unit test mock Dio | ⬜ Belum |
| ACT-83 | Test resume download — simulasi file setengah ter-download → verify `Range: bytes=N-` header dikirim | Unit test mock Dio | ⬜ Belum |
| ACT-84 | Test fallback URL — simulasi primary URL gagal → verify retry ke `fallbackUrl` | Unit test mock Dio | ⬜ Belum |
| ACT-85 | Test SHA-256 mismatch → file korup dihapus → state `DownloadFailed` | Unit test | ⬜ Belum |
| ACT-86 | Manual verify: `ModelDownloadScreen` tampil saat cold install; progress bar bergerak; ETA muncul; tombol "Coba Lagi" aktif saat gagal | Device test atau integration test | ⬜ Belum |

### 7B — Cold Start UX & State Machine Verification

| Action ID | Deskripsi | Verifikasi | Status |
|-----------|-----------|------------|--------|
| ACT-87 | Test `AppInitNotifier` state transitions — `ModelDownloading` → `ModelLoading` → `ModelReady` (happy path) | Unit test mock download + load | ⬜ Belum |
| ACT-88 | Test `AppInitNotifier` — download gagal → state `ModelFailed` (bukan `AiDegraded`) | Unit test | ⬜ Belum |
| ACT-89 | Test `AppInitNotifier` — model load gagal → state `ModelFailed` | Unit test | ⬜ Belum |
| ACT-90 | Widget test: `AiAwareFab` — saat `AppInitModelLoading` → Suara + Foto `onTap == null` && tooltip "AI sedang memuat..." tampil; Manual tetap aktif | Widget test dengan provider mock | ⬜ Belum |
| ACT-91 | Widget test: `AiLoadingBanner` — muncul saat `ModelLoading`, hilang saat `ModelReady` | Widget test | ⬜ Belum |
| ACT-92 | Widget test: `PermanentManualModeBanner` — muncul saat `ModelFailed`, tidak punya tombol dismiss | Widget test | ⬜ Belum |

### 7C — STT Offline Verification

| Action ID | Deskripsi | Verifikasi | Status |
|-----------|-----------|------------|--------|
| ACT-93 | Test `VoiceServiceImpl.initialize()` — mock `SpeechToText.locales()` tidak ada `id-ID` → return `VoiceInitMissingPack` | Unit test mocktail | ⬜ Belum |
| ACT-94 | Test `VoiceServiceImpl.initialize()` — mock `SpeechToText.initialize()` return false → return `VoiceInitFailed` | Unit test | ⬜ Belum |
| ACT-95 | Widget test: `LanguagePackDialog` tampil saat `VoiceInitMissingPack` | Widget test | ⬜ Belum |
| ACT-96 | Verify `VoiceConfig` constants — `vadSilenceThresholdMs=2000`, `maxListenDurationMs=30000`, `minConfidenceScore=0.5`, `localeId='id-ID'` ada di code, bukan magic number | Code review / grep | ⬜ Belum |
| ACT-97 | Device test Airplane Mode: aktifkan Airplane Mode → buka app → voice input tetap berfungsi (tidak ada network call) | Physical device | ⬜ Belum |

### 7D — Timeout & Retry Verification

| Action ID | Deskripsi | Verifikasi | Status |
|-----------|-----------|------------|--------|
| ACT-98 | Test `InferenceRetry` — mock inference selalu timeout → verify tepat 3 call (1 original + 2 retry) → verify state akhir `Error(InferenceTimeoutFailure)` | Unit test fake timer | ⬜ Belum |
| ACT-99 | Test `InferenceRetry` — mock inference timeout lalu sukses di attempt ke-2 → verify return `Success` | Unit test | ⬜ Belum |
| ACT-100 | Test `InferenceRetry` — `InvalidJsonOutputFailure` TIDAK di-retry di level ini (diserahkan ke Level1JsonRepair) | Unit test — verify hanya 1 call | ⬜ Belum |
| ACT-101 | Verify timeout values — grep codebase: voice timeout tepat 30000ms, vision timeout tepat 45000ms, bukan nilai lain | Code review / grep | ⬜ Belum |

### 7E — Fallback Hierarchy Verification

| Action ID | Deskripsi | Verifikasi | Status |
|-----------|-----------|------------|--------|
| ACT-102 | Test Level 1 — input JSON dengan markdown fence → `Level1JsonRepair.attempt()` strip berhasil → return `Success` tanpa inference ulang | Unit test | ⬜ Belum |
| ACT-103 | Test Level 1 — input JSON malformed total → strip gagal → retry inference 1x dengan reinforcement suffix → verify suffix ada di prompt | Unit test mock AiService | ⬜ Belum |
| ACT-104 | Test Level 2 — `InferenceRetry` + `Level1JsonRepair` keduanya gagal → `AppInitNotifier.markAsDegraded()` dipanggil → state `AiDegraded` | Integration test | ⬜ Belum |
| ACT-105 | Widget test: setelah `AiDegraded` → `AiDegradedBanner` tampil → tombol "Coba Lagi" tap → `AppInitNotifier.initialize()` dipanggil | Widget test | ⬜ Belum |
| ACT-106 | Test Level 3 — model load gagal → `ModelFailed` → verifikasi SQLite masih bisa write manual transaction → verifikasi `PermanentManualModeBanner` ada | Integration test | ⬜ Belum |

### 7F — Vision Quality Gate Verification

| Action ID | Deskripsi | Verifikasi | Status |
|-----------|-----------|------------|--------|
| ACT-107 | Test `ImageQualityGate` — file < 10KB → return `ImageQualityFail(fileTooSmall)` | Unit test file dummy | ⬜ Belum |
| ACT-108 | Test `ImageQualityGate` — gambar 300×300px → return `ImageQualityFail(resolutionTooLow)` | Unit test | ⬜ Belum |
| ACT-109 | Test `ImageQualityGate` — gambar hitam solid → brightness sampling < 40 → return `ImageQualityFail(tooDark)` | Unit test | ⬜ Belum |
| ACT-110 | Test `ImageQualityGate` — gambar 800×600 >10KB brightness normal → return `ImageQualityPass` | Unit test | ⬜ Belum |
| ACT-111 | Widget test: `ImageQualityFailDialog` — `tooDark` → pesan menyebut cahaya; `resolutionTooLow` → pesan menyebut struk/kemasan mengisi layar; `fileTooSmall` → pesan menyebut buram | Widget test | ⬜ Belum |
| ACT-112 | Test `ParseReceiptUseCase` — quality gate dijalankan SEBELUM `FlutterImageCompress` dan `AiService.infer()` — verify call order via mocktail | Unit test verify call order | ⬜ Belum |
| **VERIFY-M7** | Semua ACT-81–112 pass ✅, tidak ada magic number timeout/retry di codebase ✅, `AppInitState` transitions fully tested ✅, quality gate proven pre-inference ✅ | — | ⬜ Belum |

---

## Milestone 6: Deliverables

> **Layer 6** — Bergantung pada M5 + M7 keduanya hijau. TIDAK boleh dimulai jika ada item merah di VERIFY-M7.

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-113 | APK build config — `flutter build apk --obfuscate --split-debug-info=build/debug-info` | build scripts | ⬜ Belum |
| ACT-114 | Kaggle Notebook outline — 9 sections per PRD §14.1, semua agent dibuktikan | docs/ | ⬜ Belum |
| ACT-115 | Logcat proof strategy — filter `WarungPintar/AuditLog`, zero `HttpClient` call saat operasi normal (model sudah ter-download), raw JSON Gemma visible di split screen | docs/ | ⬜ Belum |
| ACT-116 | Final checklist validation per PRD Appendix D + Section 16 checklist (PRD §16.9) | docs/ | ⬜ Belum |
| **VERIFY-M6** | `flutter build apk --obfuscate` sukses ✅, APK jalan di physical device ≤4GB RAM Airplane Mode ✅, Appendix D 100% ✅, §16.9 checklist 100% ✅ | — | ⬜ Belum |

---

## Risk Register

| Risiko | Mitigasi |
|--------|----------|
| `flutter_gemma ^0.2.0` tidak support streaming | Sudah dikonfirmasi di PRD §16.3.4 — pakai `CircularProgressIndicator`, tidak ada workaround needed |
| Model file SHA-256 placeholder — hash resmi belum diketahui | Update `ModelStorage._modelSha256` segera setelah file model resmi tersedia dari Kaggle; jangan skip verification |
| Kaggle URL download berubah sebelum submission | Verifikasi URL `ModelDownloadConfig.primaryUrl` H-1 submission; fallback GitHub Releases sudah siap |
| `speech_to_text` memerlukan internet di beberapa Android OEM | Device test Airplane Mode wajib (ACT-97); jika gagal, tambahkan note known limitation |
| `id-ID` language pack tidak ter-install di test device | `LanguagePackDialog` sudah ready; pastikan test device punya pack sebelum demo video |
| WCAG AAA contrast tidak terpenuhi di banner baru | Verifikasi setiap warna banner (#FFF3CD, #FFEDED, #424242) dengan contrast checker sebelum ACT-73 |
| Vision brightness sampling terlalu lambat di device low-end | Benchmark `ImageQualityGate.validate()` di device ≤4GB RAM — target < 500ms; jika lambat, kurangi sample dari 100 ke 25 pixel |
| RAM tidak cukup untuk load model 2.5GB di device ≤4GB | State `ModelFailed` sudah handle skenario ini dengan permanent manual mode; tambahkan log warning di `AppInitNotifier._loadModel()` |

---

## Progress Summary

| Milestone | Total Actions | Selesai | Sisa | Status |
|-----------|--------------|---------|------|--------|
| M0: Foundation | 11 | 11 | 0 | ✅ COMPLETE |
| M1: AI Core + Model Delivery | 16 | 8 | 8 | 🔄 IN PROGRESS |
| M2: Data Infrastructure | 16 | 0 | 16 | ⬜ NEXT |
| M3: Domain + Agents | 17 | 0 | 17 | ⬜ Pending |
| M4: Presentation / UI | 13 | 0 | 13 | ⬜ Pending |
| M5: Testing & QA | 7 | 0 | 7 | ⬜ Pending |
| M7: Section 16 QA | 32 | 0 | 32 | ⬜ Pending |
| M6: Deliverables | 4 | 0 | 4 | ⬜ Pending |
| **TOTAL** | **116** | **19** | **97** | **16% Complete** |

> **NOTE**: Penomoran action ID direset mulai ACT-19 untuk actions baru (lanjut dari ACT-18 yang terakhir ✅). M7 diberi nomor terpisah dari M5 sesuai instruksi — keduanya layer 5 (paralel) tapi M7 khusus Section 16. M6 adalah gate akhir yang hanya bisa dibuka setelah M5 + M7 keduanya selesai.

---

## Quick Reference: Section 16 Action Map

| PRD §16 Sub-section | Actions |
|--------------------|---------|
| §16.1 Model Delivery | ACT-19, ACT-20, ACT-21, ACT-25 |
| §16.2 Cold Start UX & AppInitState | ACT-22, ACT-23, ACT-24, ACT-65–69, ACT-87–92 |
| §16.3 Gemma Capabilities | ACT-13 (vision check), ACT-14 (PromptBudget) |
| §16.4 STT Offline | ACT-30–34, ACT-93–97 |
| §16.5 Timeout & Retry | ACT-39, ACT-42, ACT-98–101 |
| §16.6 Fallback Hierarchy | ACT-40, ACT-41, ACT-102–106 |
| §16.7 Vision Quality Gate | ACT-35–38, ACT-107–112 |