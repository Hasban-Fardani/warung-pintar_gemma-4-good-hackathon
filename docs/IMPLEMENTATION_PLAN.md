# WarungPintar Cimahi — Master Implementation Plan

> **Sources**: `@docs/PRD.md` v9.0.0, `@AGENT.md` §17, `@docs/DESIGN.md`
> **Last Updated**: 2026-05-17

---

## Conflict Resolution (LOCKED)

| Konflik | Keputusan | Source |
|---------|-----------|--------|
| Font: Inter vs Plus Jakarta Sans | **Inter** | DESIGN.md wins |
| Primary: #005DAC vs #1976D2 | **#005DAC** | DESIGN.md wins |
| Confirmed green: #059669 vs #1B6D24 | **#059669** | PRD §12.7 (WCAG validated) |
| Gemma package | **flutter_gemma: ^0.2.0** added | User approved |
| Test mocking | **mocktail** (bukan mockito) | User confirmed |

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

## Milestone 0: Foundation & DI & Router (Day 1) ✅ COMPLETE

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-00 | Fix pubspec.yaml — tambah semua pre-approved deps | pubspec.yaml | ✅ Done |
| ACT-01 | Enforce analysis_options.yaml per PRD Appendix C | analysis_options.yaml | ✅ Done |
| ACT-02 | Buat folder structure per PRD §5.1 (directories + .gitkeep) | lib/ directory tree | ✅ Done |
| ACT-03 | Extract AiService interface → `core/ai/ai_service.dart` | core/ai/, core/di/ | ✅ Done |
| ACT-04 | Extract DatabaseService → `core/database/database_service.dart` | core/database/, core/di/ | ✅ Done |
| ACT-05 | Buat error/failures.dart — AiFailure sealed class hierarchy | core/error/ | ✅ Done |
| ACT-06 | Buat app_colors.dart + app_strings.dart dari DESIGN.md tokens | core/constant/ | ✅ Done |
| ACT-07 | Buat money_formatter.dart + uuid_helper.dart | core/utils/ | ✅ Done |
| ACT-08 | Enhance app_theme.dart — full DESIGN.md typography scale | core/theme/ | ✅ Done |
| ACT-09 | Restructure app_router.dart — PRD §4.1 paths + onboarding redirect | core/router/ | ✅ Done |
| ACT-10 | Run build_runner, verifikasi injection.config.dart | core/di/ | ✅ Done |
| **VERIFY-M0** | `flutter pub get` ✅, `flutter analyze` ✅, zero network imports ✅ | — | ✅ Pass |

---

## Milestone 1: AI Runtime & Isolate Architecture (Day 2)

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-11 | Buat tool_call_result.dart sealed class + result.dart | core/ai/, core/error/ | ⬜ Belum |
| ACT-12 | Buat json_parser.dart — stripJsonFences + parseToolCall | core/ai/ | ⬜ Belum |
| ACT-13 | Buat gemma_isolate_service.dart — isolate infrastructure | core/ai/ | ⬜ Belum |
| ACT-14 | Update ai_service.dart — return Result<ToolCallResult, AiFailure> | core/ai/ | ⬜ Belum |
| ACT-15 | Buat gemma_ai_service.dart — real impl via GemmaIsolateService | core/ai/ | ⬜ Belum |
| ACT-16 | Buat 5 system prompt files per PRD §6.3–6.7 | core/ai/prompts/ | ⬜ Belum |
| ACT-17 | Unit tests untuk json_parser + tool_call_result | test/core/ai/ | ⬜ Belum |
| ACT-18 | Run build_runner, wire DI GemmaAiService | core/di/ | ⬜ Belum |
| **VERIFY-M1** | `flutter analyze` ✅, `flutter test test/core/ai/` ✅, build_runner ✅ | — | ⬜ Belum |

---

## Milestone 2: Agents 1, 2, 3 — Onboarding & Voice (Day 3)

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-19 | Implement full SQLite DDL di database_service.dart per PRD §11 | core/database/ | ⬜ Belum |
| ACT-20 | Transaction domain layer — entity, abstract repo, usecases | features/transaction/domain/ | ⬜ Belum |
| ACT-21 | Transaction data layer — model, datasource, repo impl | features/transaction/data/ | ⬜ Belum |
| ACT-22 | Audit log datasource — append-only per PRD §9 | features/transaction/data/ | ⬜ Belum |
| ACT-23 | Onboarding domain — setup_business usecase | features/onboarding/domain/ | ⬜ Belum |
| ACT-24 | Onboarding presentation — page + Riverpod provider | features/onboarding/presentation/ | ⬜ Belum |
| ACT-25 | VoiceService interface + impl | shared/services/ | ⬜ Belum |
| ACT-26 | Voice transaction provider (Agent 2) | features/transaction/presentation/ | ⬜ Belum |
| ACT-27 | Pending confirmation provider (Agent 3) | features/transaction/presentation/ | ⬜ Belum |
| ACT-28 | Shared widgets: pending_banner, status_badge | shared/widgets/ | ⬜ Belum |
| ACT-29 | Unit tests: record/confirm usecases dengan mock AI | test/features/transaction/ | ⬜ Belum |
| **VERIFY-M2** | `flutter analyze` ✅, tests ✅, voice flow FakeAI ✅, pending reactive ✅ | — | ⬜ Belum |

---

## Milestone 3: Agents 4, 5 + Master Data (Day 4)

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-30 | Vision domain — parse_receipt_usecase (Agent 4) | features/vision/domain/ | ⬜ Belum |
| ACT-31 | Vision presentation — receipt_capture_page + provider | features/vision/presentation/ | ⬜ Belum |
| ACT-32 | Vision domain — parse_product_usecase (Agent 5) | features/vision/domain/ | ⬜ Belum |
| ACT-33 | Vision presentation — product_capture_page + provider | features/vision/presentation/ | ⬜ Belum |
| ACT-34 | Catalog domain — entities, abstract repo, CRUD usecases | features/catalog/domain/ | ⬜ Belum |
| ACT-35 | Catalog data — models, datasources, repo impl | features/catalog/data/ | ⬜ Belum |
| ACT-36 | Catalog presentation — list, detail, category drawer, add item | features/catalog/presentation/ | ⬜ Belum |
| ACT-37 | Price history — append-only update_price_usecase per PRD §10.6 | features/catalog/domain/ | ⬜ Belum |
| ACT-38 | Tests: vision usecases + price history isolation | test/features/ | ⬜ Belum |
| **VERIFY-M3** | `flutter analyze` ✅, tests ✅, camera permissions ✅, price isolation ✅ | — | ⬜ Belum |

---

## Milestone 4: UI/UX Polish & Audit (Day 5)

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-39 | Bento Box dashboard — full impl per PRD §12.2 + provider | features/dashboard/ | ⬜ Belum |
| ACT-40 | Expandable FAB — 3 sub-FABs + dim overlay per PRD §12.3 | shared/widgets/ | ⬜ Belum |
| ACT-41 | Audit log drawer per PRD §9.4 | shared/widgets/ | ⬜ Belum |
| ACT-42 | Toast system per PRD §12.8 | shared/widgets/ | ⬜ Belum |
| ACT-43 | Haptic matrix per PRD §12.6 | core/utils/ | ⬜ Belum |
| ACT-44 | Screen-by-screen UI verification terhadap 16 docs/design/ PNGs | all presentation/ | ⬜ Belum |
| **VERIFY-M4** | `flutter analyze` ✅, 16 screens match ✅, no overflow 360x800/414x896 ✅ | — | ⬜ Belum |

---

## Milestone 5: Testing & QA (Day 5–6)

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-45 | Unit tests: money_formatter, uuid_helper | test/core/utils/ | ⬜ Belum |
| ACT-46 | Widget tests: dashboard, pending_banner, audit_drawer | test/ | ⬜ Belum |
| ACT-47 | Integration test: idempotency (duplicate key = 1 row) | test/integration/ | ⬜ Belum |
| ACT-48 | Integration test: price history isolation | test/integration/ | ⬜ Belum |
| **VERIFY-M5** | `flutter test --coverage` >80% domain/data ✅, zero network di test ✅ | — | ⬜ Belum |

---

## Milestone 6: Deliverables (Day 6)

| Action ID | Deskripsi | Scope | Status |
|-----------|-----------|-------|--------|
| ACT-49 | APK build config — obfuscation + split-debug-info | build scripts | ⬜ Belum |
| ACT-50 | Kaggle Notebook outline (9 sections per PRD §14.1) | docs/ | ⬜ Belum |
| ACT-51 | Logcat proof strategy doc | docs/ | ⬜ Belum |
| ACT-52 | Final checklist validation per PRD Appendix D | docs/ | ⬜ Belum |
| **VERIFY-M6** | `flutter build apk --obfuscate` ✅, Appendix D 100% ✅ | — | ⬜ Belum |

---

## Risk Register

| Risiko | Mitigasi |
|--------|----------|
| `flutter_gemma` unavailable | Stub GemmaIsolateService worker; real inference wiring saat model tersedia |
| Pub version conflicts | Resolve satu per satu dengan `flutter pub add` |
| `speech_to_text` perlu internet | Verifikasi offline STT engine; Airplane Mode test |
| WCAG AAA contrast tidak terpenuhi | Verifikasi setiap pair dengan contrast checker |

---

## Progress Summary

| Milestone | Total Actions | Selesai | Sisa | Status |
|-----------|--------------|---------|------|--------|
| M0: Foundation | 11 | 11 | 0 | ✅ COMPLETE |
| M1: AI Runtime | 8 | 0 | 8 | ⬜ NEXT |
| M2: Agents 1-3 | 11 | 0 | 11 | ⬜ Pending |
| M3: Agents 4-5 | 9 | 0 | 9 | ⬜ Pending |
| M4: UI/UX Polish | 6 | 0 | 6 | ⬜ Pending |
| M5: Testing | 4 | 0 | 4 | ⬜ Pending |
| M6: Deliverables | 4 | 0 | 4 | ⬜ Pending |
| **TOTAL** | **53** | **11** | **42** | **21% Complete** |

> **NOTE**: ACT-14 diubah dari FakeAiService menjadi update AiService return type. Tidak ada FakeAiService — hanya GemmaAiService (real AI) per PRD §6.1.
