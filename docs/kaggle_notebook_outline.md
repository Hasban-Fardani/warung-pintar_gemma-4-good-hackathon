# WarungPintar Cimahi — Kaggle Notebook Outline

This document outlines the structure of the Kaggle Notebook to be submitted as proof of the `GemmaIsolateService` and `WarungGemmaManager` performance and capabilities, specifically fulfilling the requirements outlined in PRD §14.1.

## Section 1: Setup & LiteRT Environment Verification

**Objective:** Demonstrate that the Gemma 4 E2B `.bin` model loads successfully into the LiteRT runtime via `flutter_gemma`.

**Input/Code Sample (Dart context):**
```dart
final service = ref.read(gemmaIsolateServiceProvider);
final isReady = await service.isReady();
final status = await service.getInitializationStatus();
```

**Expected Output/Validation:**
- Boolean assertion `isReady == true`.
- Status check confirms memory allocation for the model.
- Time taken to load model into memory.

**Judge's Note:** This proves that the app uses the authorized LiteRT inference engine, not a remote API.

---

## Section 2: Function Calling Proof — Agent 2 (Voice)

**Objective:** Prove that the voice-to-JSON agent (Agent 2) correctly parses a multi-item Indonesian voice transcript into the expected JSON structure.

**Input Sample:**
`"Beli indomie goreng tiga biji, telur setengah kilo, sama minyak bimoli dua liter"`

**Expected Output Schema (JSON):**
```json
{
  "items": [
    {"name": "indomie goreng", "quantity": 3},
    {"name": "telur", "quantity": 0.5, "unit": "kg"},
    {"name": "minyak bimoli", "quantity": 2, "unit": "liter"}
  ],
  "is_complete": true
}
```

**Validation Cell:**
- Assert `items.length == 3`.
- Assert `items[0].quantity == 3`.
- Assert parse time < 3000ms.

---

## Section 3: Function Calling Proof — Agent 3 (Confirmation)

**Objective:** Demonstrate Agent 3 interpreting user confirmation intentions.

**Test Case A: Full Confirmation**
**Input:** `"Ya bener semua"`
**Expected Output:** `{"status": "confirm"}`

**Test Case B: Partial Correction**
**Input:** `"Bukan, yang indomie dua aja"`
**Expected Output:** `{"status": "correct", "correction": "indomie dua"}`

**Validation Cell:**
- Assert JSON exact match for Test Case A.
- Assert JSON structure for Test Case B.

---

## Section 4: Multimodal Vision Proof — Agent 4 (Struk)

**Objective:** Prove image-to-text accuracy using an image of a physical receipt.

**Input Sample:**
*Image payload (simulated base64 of a dummy receipt)*

**Expected Output Schema (JSON):**
```json
{
  "items": [
    {"name": "Beras Sania 5kg", "price_per_unit": 75000, "quantity": 1},
    {"name": "Gula Pasir", "price_per_unit": 16500, "quantity": 2}
  ],
  "total_price": 108000
}
```

**Validation Cell:**
- Compare output arrays against Ground Truth (GT) JSON.
- Calculate Accuracy % (must be > 95% per Quality Gate).

---

## Section 5: Multimodal Vision Proof — Agent 5 (Kemasan)

**Objective:** Verify that Agent 5 extracts product names from packaging but *excludes* price data.

**Input Sample:**
*Image payload (simulated base64 of a coffee sachet)*

**Expected Output Schema (JSON):**
```json
{
  "item_name": "Kopi Kapal Api Mix 25gr",
  "category": "Minuman"
}
```

**Validation Cell:**
- Assert `price` field does not exist in the output JSON.
- Assert string non-empty.

---

## Section 6: JSON Robustness Test

**Objective:** Prove the robustness of `_stripJsonFences()` against markdown-wrapped or malformed Gemma outputs.

**Input Samples:**
1. `` ```json { "status": "ok" } ``` ``
2. `Here is the result: { "status": "ok" }`

**Validation Cell:**
- Assert both inputs parse perfectly to `{ "status": "ok" }`.

---

## Section 7: Integer Money Validation

**Objective:** Demonstrate that the app uses integer cents (`int`) for all price calculations, preventing float precision loss.

**Input Sample (Dart calculation):**
`1000000.1 * 3` vs `(100000010 * 3) / 100`

**Validation Cell:**
- Show that float logic produces `3000000.2999999995`.
- Show that integer logic maintains absolute accuracy.

---

## Section 8: Price History Isolation

**Objective:** Prove the strict separation and append-only nature of the `price_history` table.

**Input Sample:**
- Update price of "Beras" from 15000 to 16000.

**Validation Cell:**
- Assert `products` table reflects current price `16000`.
- Assert `price_history` contains 2 immutable records (15000, 16000).

---

## Section 9: Performance Benchmark

**Objective:** Measure on-device inference latency.

**Metrics Gathered:**
- Load time.
- Average Tokens Per Second (TPS).
- Peak memory usage during inference.

**Validation Cell:**
- Output formatting suitable for Kaggle leaderboard comparison.
