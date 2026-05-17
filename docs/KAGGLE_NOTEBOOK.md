# WarungPintar Cimahi - Kaggle Notebook Outline

This notebook serves as the verifiable technical proof for the Gemma 4 Good Hackathon submission. It demonstrates the capabilities of the Gemma 4 E2B LiteRT model running entirely on-device, implementing all 5 agents.

## Section 1: Setup & Model Loading
- Load Gemma 4 E2B from Kaggle Models (`gemma-4-E2B-it-litertlm-Q4_K_M.litertlm`).
- Verify the LiteRT runtime environment on the device.
- Log model initialization time and RAM footprint.

## Section 2: Function Calling Proof — Agent 2 (Voice)
- **Input:** Ucapan multi-item bahasa Indonesia ("Beras tiga kilo empat lima ribu, kopi dua saset tiga ribu").
- **Output:** JSON array `transactions` valid.
- **Validasi:** Schema compliance check, pastikan status `pending`, konversi teks numerik verbal ke integer sen (misal "empat lima ribu" -> 4500000).

## Section 3: Function Calling Proof — Agent 3 (Confirm)
- **Input:** Konfirmasi bulk ("semua benar") dan parsial ("ganti lima puluh ribu").
- **Output:** JSON `confirm_transactions` actions.
- **Validasi:** Pastikan AI memetakan respons user ke array ID transaksi yang tepat.

## Section 4: Multimodal Vision Proof — Agent 4 (Struk)
- **Input:** Gambar struk belanja/nota supplier (sample file).
- **Output:** JSON `record_transactions` (semua item bertipe `buy`, status `pending`).
- **Validasi:** Accuracy rate vs ground truth manual.

## Section 5: Multimodal Vision Proof — Agent 5 (Kemasan)
- **Input:** Gambar kemasan produk (misal bungkus Tepung Segitiga Biru).
- **Output:** JSON `parse_product_from_image` (nama produk, kategori).
- **Verifikasi:** Tidak boleh ada atribut harga di dalam output karena AI tidak boleh menebak harga produk tanpa input explicit.

## Section 6: JSON Robustness Test
- **Simulasi:** Inject output dengan markdown fence (```json ... ```) dan trailing text.
- **Pembuktian:** Tunjukkan fungsi `_stripJsonFences()` dapat memulihkan JSON menjadi payload bersih yang dapat diparse.
- **Edge cases:** Output kosong, JSON malformed, key yang hilang ditangani dengan graceful fallback.

## Section 7: Integer Money Validation
- **Simulasi:** "45.000" → 4500000 (sen) → "Rp 45.000" display.
- **Pembuktian:** Demonstrasikan kehilangan presisi (precision loss) jika menggunakan tipe data float, dan buktikan mengapa protokol *Integer Money* mencegah bug finansial.

## Section 8: Price History Isolation Test
- **Input:** Insert transaksi masa lalu dengan harga lama.
- **Action:** Update harga item di master katalog.
- **Verifikasi:** Transaksi lama tidak berubah harganya (karena menyimpan snapshot `price_at_transaction_sen`), namun entri baru bertambah di `price_history`.

## Section 9: Performance Benchmark
- **Voice Inference:** Rata-rata inference time per query (dalam milidetik).
- **Vision Inference:** Rata-rata inference time per image.
- **Memory Footprint:** Estimasi penggunaan memori selama dan sesudah inferensi di device ber-RAM ≤4GB.
