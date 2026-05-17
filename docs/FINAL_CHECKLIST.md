# WarungPintar Cimahi — Final Checklist

This checklist combines all technical constraints, Kaggle competition deliverables (Appendix D), and Section 16 Quality Assurance rules from the PRD.

## A. Technical Constraints (PRD Core Rules)

- [ ] **Zero-Network Inference:** STT, Vision, and LLM run 100% on-device via LiteRT (`flutter_gemma`). No external API calls are made for inference.
- [ ] **Gemma 4 E2B:** The app explicitly uses the Gemma 4 E2B `.bin` model.
- [ ] **Integer Pricing:** All internal prices and database entries are integers (`int`). No float operations for money.
- [ ] **Append-Only History:** `price_history` and `audit_logs` are strictly append-only. No `UPDATE` or `DELETE` allowed.
- [ ] **Feature-First Architecture:** Codebase follows strict clean architecture (presentation, domain, data layers per feature).
- [ ] **Design Tokens:** UI adheres strictly to `docs/DESIGN.md` tokens. No raw hex colors used in the UI layer.

## B. Section 16 Quality Assurance (M7 Gates)

- [ ] **ACT-81 (Model Delivery):** Dio configured with `Range` header for resumable downloads.
- [ ] **ACT-82 (State Machine):** `Uninitialized` -> `Downloading` -> `Ready` -> `Inferencing` flows correctly.
- [ ] **ACT-85 (STT Offline):** `speech_to_text` is configured explicitly with `onDevice: true`.
- [ ] **ACT-87 (Timeout):** 15-second strict timeout on Gemma inference.
- [ ] **ACT-89 (Retry):** 3 maximum retries on failure before falling back.
- [ ] **ACT-91 (Fallback):** App falls back to `Permanent Manual Mode` if the model fails or cannot be downloaded.
- [ ] **ACT-110 (Vision Quality Gate):** Accuracy on receipt parsing (Agent 4) is > 95%.

## C. Hackathon Deliverables (Appendix D)

### C.1. Technical Submission
- [ ] **APK Build:** `app-release.apk` built with `--obfuscate` and `--split-debug-info`.
- [ ] **Debug Info:** `build/debug-info/` directory included in submission zip.
- [ ] **GitHub Repository:** Clean, well-documented source code available.

### C.2. Kaggle Notebook
- [ ] **Notebook Created:** Hosted on Kaggle platform.
- [ ] **Section 1-9 Addressed:** All sections from the `kaggle_notebook_outline.md` are implemented with code cells and expected outputs.
- [ ] **LiteRT Proof:** Explicitly proves LiteRT is the engine.

### C.3. Video & Logcat Proof
- [ ] **Zero-Network Video:** Video demonstrating STT/Inference working in Airplane mode.
- [ ] **Logcat Logs:** Clean logcat export showing no `HttpClient` activity during inference.
- [ ] **UI Demo:** Video showcasing the beautiful, accessible UI (Inter font, WCAG AAA contrast).

## Verification Sign-off

- **Developer:** [Sign here]
- **Date:** [Date here]
- **Commit Hash:** [Latest Commit]
