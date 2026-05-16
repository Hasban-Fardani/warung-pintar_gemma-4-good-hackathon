# WarungPintar Cimahi — Task Checklist

> **Last Updated**: 2026-05-17
> **Progress**: 11/53 actions (21%)

---

## ✅ Milestone 0: Foundation & DI & Router — COMPLETE

- [x] ACT-00 — Fix pubspec.yaml — tambah semua pre-approved deps
  - Commit: `9155f40` — 66 dependencies resolved
- [x] ACT-01 — Enforce analysis_options.yaml per PRD Appendix C
  - Commit: `d2b7689` — strict lint rules + const fix
- [x] ACT-02 — Buat folder structure per PRD §5.1
  - Commit: `78c0839` — 61 .gitkeep files across feature/core/shared
- [x] ACT-03 — Extract AiService interface → core/ai/ai_service.dart
  - Commit: `529f1b6` — pure Dart, zero Flutter imports
- [x] ACT-04 — Extract DatabaseService → core/database/database_service.dart
  - Commit: `8c62a6e` — @LazySingleton, injection.config.dart regenerated
- [x] ACT-05 — Buat AiFailure sealed class hierarchy
  - Commit: `9ff55a1` — 4 variants: ModelNotLoaded, InferenceTimeout, InvalidJsonOutput, ImageUnreadable
- [x] ACT-06 — Buat app_colors.dart + app_strings.dart
  - Commit: `5d4768c` — 50+ color tokens + Indonesian UI strings
- [x] ACT-07 — Buat money_formatter.dart + uuid_helper.dart
  - Commit: `28afae9` — integer money protocol (sen), UUIDv7/v4
- [x] ACT-08 — Enhance app_theme.dart — full DESIGN.md typography
  - Commit: `138ecf0` — complete typography scale, 48dp touch targets, card/button themes
- [x] ACT-09 — Restructure app_router.dart — PRD §4.1 paths
  - Commit: `e932fae` — StatefulShellRoute 4 tabs, /onboarding, push routes
- [x] ACT-10 — build_runner + M0 verification
  - Commit: `246969d` — zero issues, zero network imports

### M0 Verification Gates
- [x] `flutter pub get` — exit 0
- [x] `flutter analyze` — 0 issues
- [x] `dart run build_runner build` — exit 0
- [x] `grep -r "http|dio|cloud" lib/` — 0 code matches
- [x] Folder structure matches PRD §5.1

---

## ⬜ Milestone 1: AI Runtime & Isolate Architecture — NEXT

- [ ] ACT-11 — Buat tool_call_result.dart sealed class + result.dart Result type
- [ ] ACT-12 — Buat json_parser.dart — stripJsonFences + parseToolCall
- [ ] ACT-13 — Buat gemma_isolate_service.dart — isolate infrastructure
- [ ] ACT-14 — Update ai_service.dart — return Result<ToolCallResult, AiFailure>
- [ ] ACT-15 — Buat gemma_ai_service.dart — real impl via GemmaIsolateService
- [ ] ACT-16 — Buat 5 system prompt files per PRD §6.3–6.7
- [ ] ACT-17 — Unit tests untuk json_parser + tool_call_result
- [ ] ACT-18 — Run build_runner, wire DI GemmaAiService

### M1 Verification Gates
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test test/core/ai/` — all pass
- [ ] `dart run build_runner build` — exit 0

---

## ⬜ Milestone 2: Agents 1, 2, 3 — Onboarding & Voice

- [ ] ACT-19 — Full SQLite DDL di database_service.dart per PRD §11
- [ ] ACT-20 — Transaction domain layer — entity, abstract repo, usecases
- [ ] ACT-21 — Transaction data layer — model, datasource, repo impl
- [ ] ACT-22 — Audit log datasource — append-only per PRD §9
- [ ] ACT-23 — Onboarding domain — setup_business usecase
- [ ] ACT-24 — Onboarding presentation — page + Riverpod provider
- [ ] ACT-25 — VoiceService interface + impl
- [ ] ACT-26 — Voice transaction provider (Agent 2)
- [ ] ACT-27 — Pending confirmation provider (Agent 3)
- [ ] ACT-28 — Shared widgets: pending_banner, status_badge
- [ ] ACT-29 — Unit tests: record/confirm usecases

### M2 Verification Gates
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test` — all pass
- [ ] Voice flow dengan FakeAI — functional
- [ ] Pending count reactive

---

## ⬜ Milestone 3: Agents 4, 5 + Master Data

- [ ] ACT-30 — Vision domain — parse_receipt_usecase (Agent 4)
- [ ] ACT-31 — Vision presentation — receipt_capture_page + provider
- [ ] ACT-32 — Vision domain — parse_product_usecase (Agent 5)
- [ ] ACT-33 — Vision presentation — product_capture_page + provider
- [ ] ACT-34 — Catalog domain — entities, abstract repo, CRUD usecases
- [ ] ACT-35 — Catalog data — models, datasources, repo impl
- [ ] ACT-36 — Catalog presentation — list, detail, category drawer
- [ ] ACT-37 — Price history — append-only update_price_usecase
- [ ] ACT-38 — Tests: vision usecases + price history isolation

### M3 Verification Gates
- [ ] `flutter analyze` — 0 issues
- [ ] Tests pass
- [ ] Camera permissions verified
- [ ] Price isolation proven

---

## ⬜ Milestone 4: UI/UX Polish & Audit

- [ ] ACT-39 — Bento Box dashboard per PRD §12.2
- [ ] ACT-40 — Expandable FAB — 3 sub-FABs per PRD §12.3
- [ ] ACT-41 — Audit log drawer per PRD §9.4
- [ ] ACT-42 — Toast system per PRD §12.8
- [ ] ACT-43 — Haptic matrix per PRD §12.6
- [ ] ACT-44 — Screen-by-screen UI verification (16 screens)

### M4 Verification Gates
- [ ] `flutter analyze` — 0 issues
- [ ] 16 screens match docs/design/ PNGs
- [ ] No overflow pada 360x800 dan 414x896

---

## ⬜ Milestone 5: Testing & QA

- [ ] ACT-45 — Unit tests: money_formatter, uuid_helper
- [ ] ACT-46 — Widget tests: dashboard, pending_banner, audit_drawer
- [ ] ACT-47 — Integration test: idempotency
- [ ] ACT-48 — Integration test: price history isolation

### M5 Verification Gates
- [ ] `flutter test --coverage` >80% domain/data
- [ ] Zero network imports di test

---

## ⬜ Milestone 6: Deliverables

- [ ] ACT-49 — APK build config — obfuscation + split-debug-info
- [ ] ACT-50 — Kaggle Notebook outline (9 sections)
- [ ] ACT-51 — Logcat proof strategy doc
- [ ] ACT-52 — Final checklist validation per Appendix D

### M6 Verification Gates
- [ ] `flutter build apk --obfuscate` — success
- [ ] Appendix D — 100% pass
