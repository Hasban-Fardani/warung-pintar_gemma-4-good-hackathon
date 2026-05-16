# Product Requirements Document: WarungPintar Cimahi
## Gemma 4 Good Hackathon Submission — Digital Equity & LiteRT Track

**Version:** 9.0.0 (Final Architectural Review)
**Last Updated:** Mei 2026
**Platform:** Android (min SDK 26, target SDK 34)
**Framework:** Flutter 3.27+ / Dart 3.6+
**State Management:** Riverpod 2.6+ (AutoDispose & Testable)
**Dependency Injection:** GetIt 7.6+ (Service Locator)
**Routing:** GoRouter 14.0+ (Declarative Navigation)
**AI Runtime:** Gemma 4 E2B via LiteRT-LM (On-Device) + Native Tool Calling + Native Multimodal Vision
**Architecture:** Offline-First, Clean Architecture, Edge-Agentic
**License:** Apache 2.0

---

## 1. Executive Summary & Competition Strategy

WarungPintar adalah aplikasi ERP agentic offline-first untuk pelaku UMKM mikro Indonesia. Proyek ini mengeksploitasi **tiga kapabilitas frontier Gemma 4 sekaligus**: native function calling, native multimodal vision, dan on-device reasoning — semuanya berjalan 100% tanpa koneksi internet.

Ibu Warsih bisa mencatat transaksi lewat suara panjang (multi-item sekaligus), memfoto struk belanja agar AI membaca dan mencatatnya otomatis, menambah barang baru lewat foto kemasan, serta mengkonfirmasi transaksi pending via suara — semua tanpa satu form yang diisi manual.

### 1.1 Mapping ke Kriteria Penilaian Kaggle

| Kriteria | Poin | Strategi WarungPintar |
|---|---|---|
| Impact & Vision | 40 | 64 juta UMKM, zero digital literacy barrier, offline-first |
| Video Pitch & Storytelling | 30 | Storyboard 3 menit dengan before/after visual yang emosional |
| Technical Depth & Execution | 30 | APK jalan, Logcat proof, Kaggle Notebook, 3 fitur Gemma 4, Robust Architecture (Riverpod + GetIt + Folder Structure) |

### 1.2 Keunggulan Kompetitif

1.  **Multimodal Vision aktif** — foto struk → AI parse → ledger entry; foto kemasan → AI baca nama produk → pre-fill master barang.
2.  **Triple Gemma 4 Feature** — function calling + vision + on-device inference dalam satu app.
3.  **Non-blocking pending workflow** — ratusan transaksi bisa dicatat dulu, dikonfirmasi belakangan via suara bulk.
4.  **Price history immutable** — perubahan harga tidak mempengaruhi data transaksi lama.
5.  **Enterprise data integrity di edge** — UUIDv7, idempotency, WAL, integer money, audit log append-only.
6.  **Bukti teknis verifiable** — Kaggle Notebook + Logcat + raw AI output tersimpan di audit log.
7.  **Scalable Codebase** — Implementasi Clean Architecture dengan Folder Structure yang ketat, Riverpod untuk state reaktif, dan GetIt untuk Dependency Injection, memastikan app mudah di-test dan di-maintain.

---

## 2. Target User Personas

### 2.1 Primary — Ibu Warsih (Pemilik Warung)
-   **Demografis:** 45–60 tahun, Cimahi, Jawa Barat
-   **Pendidikan:** SMP, literasi digital sangat rendah
-   **Rutinitas:** Buka warung 06.00–20.00, jam ramai 07.00–09.00 dan 16.00–18.00
-   **Pain Points:**
    -   Lupa catat transaksi saat jam sibuk, melayani 3–5 pembeli bersamaan
    -   Tidak bisa hitung laba harian tanpa kalkulator
    -   Harus catat struk supplier satu per satu
    -   Takut salah tekan di aplikasi digital
-   **Accessibility Needs:**
    -   Touch target minimum 48dp
    -   Font minimum 14sp (presbyopia)
    -   Kontras WCAG AAA (7:1)
    -   Toleran noise suara ambien warung

### 2.2 Secondary — Pak Budi (Supplier)
Mengantar barang dua kali seminggu dengan nota pengiriman. Ibu Warsih perlu catat stok masuk massal — via foto nota atau suara sambil berbicara dengan Pak Budi.

### 2.3 Tertiary — Koperasi Mitra (Petugas Pinjaman)
Membutuhkan laporan keuangan terstruktur untuk persetujuan kredit mikro. Mengonsumsi output PDF/CSV dari WarungPintar.

---

## 3. Product Vision & Success Metrics

### 3.1 Vision Statement
Setiap pelaku UMKM mikro Indonesia dapat membuat keputusan bisnis berbasis data menggunakan agen AI otonom yang bekerja 100% offline, memahami bahasa lokal, dan menerima input dalam bentuk apapun — suara panjang, teks, maupun foto.

### 3.2 Hackathon Success Metrics

| Metrik | Target | Cara Buktikan |
|---|---|---|
| Onboarding conversational | Selesai tanpa 1 keystroke manual | Screen recording live |
| Voice transaction multi-item | < 8 detik end-to-end | Timestamp di video |
| Voice bulk confirm pending | < 3 detik per item | Screen recording |
| Image-to-transaction (foto struk) | < 10 detik parse + insert | Screen recording |
| Image-to-masterdata (foto kemasan) | < 8 detik parse + pre-fill | Screen recording |
| Offline compliance | 100% fitur aktif di Airplane Mode | Logcat screenshot |
| Model cold start | ≤ 90 detik | Timer overlay di video |
| Zero network request | 0 outbound connection | Android Network Profiler |

### 3.3 Post-Hackathon Impact Metrics
-   70% pengurangan waktu pencatatan manual harian
-   100% pengguna aktif dapat menyebut laba harian tanpa kalkulator
-   90% acceptance rate laporan PDF oleh koperasi lokal

---

## 4. Screen Hierarchy & Navigation

### 4.1 Struktur Navigasi (GoRouter)

Menggunakan `StatefulShellRoute` untuk Bottom Navigation dengan state preservation.

```
Root Router
├── /onboarding (First Launch Only)
└── / (StatefulShellRoute - Bottom Nav)
    ├── Tab 1: Beranda (Dashboard) → Path: /
    ├── Tab 2: Pending           → Path: /pending
    ├── Tab 3: Katalog           → Path: /catalog
    └── Tab 4: Setelan           → Path: /settings

FAB (center, muncul di Tab 1, 2, 3):
├── Sub-FAB: Suara (voice input panjang)
├── Sub-FAB: Foto (kamera — struk atau kemasan)
└── Sub-FAB: Manual (form fallback)

Halaman non-tab (navigasi push via GoRouter):
├── /item/:id              → Detail Barang + History Harga
├── /transaction/:id       → Detail Transaksi + Audit Log Drawer
└── /reports               → Laporan & Histori
```

### 4.2 Tabel Halaman Lengkap

| # | Halaman | Akses | Pattern | Konten Utama |
|---|---|---|---|---|
| 1 | **Beranda (Dashboard)** | Bottom Nav Tab 1 | Full Page | Bento omzet/profit/modal, pending banner, stock alert scroll, 5 transaksi terakhir |
| 2 | **Pending Review** | Bottom Nav Tab 2 + badge | Full Page | List pending non-blocking, voice bulk confirm, klarifikasi ambigu |
| 3 | **Laporan & Histori** | Shortcut dari Beranda | Full Page | Period selector, chart, transaction list paginated, export PDF/CSV |
| 4 | **Katalog Barang** | Bottom Nav Tab 3 | Full Page + Drawer edit | List barang, filter kategori, tambah via foto+suara, badge price history |
| 5 | **Master Kategori** | Drawer dari Katalog | Drawer | List kategori, tambah/edit/hapus |
| 6 | **Detail Barang + History Harga** | Push dari Katalog | Full Page | Info barang, timeline harga immutable, edit harga (tambah entry baru) |
| 7 | **Detail Transaksi + Audit Log** | Drawer dari transaksi manapun | Drawer | Append-only log: STT transcript, raw AI JSON, before/after edit |
| 8 | **Setelan** | Bottom Nav Tab 4 | Full Page | Profil usaha, AI settings, haptic, backup DB, hapus data |
| 9 | **Onboarding** | First launch only | Full Page (no nav) | Conversational setup via suara |

---

## 5. Project Architecture & Folder Structure

Untuk memastikan kualitas kode dan kemudahan maintenance (terutama saat kolaborasi dengan AI coding tools), struktur folder diatur secara ketat menggunakan pola **Feature-First**.

### 5.1 Folder Structure

```
lib/
├── core/
│   ├── constant/          ← Konstanta aplikasi (Colors, Strings)
│   ├── database/          ← SQLite helper, Migration, WAL setup
│   ├── ai/                ← GemmaIsolateService, Prompts, JSON parser
│   ├── di/                ← GetIt registration (injection.dart)
│   ├── router/            ← GoRouter configuration
│   ├── error/             ← Failures, Result pattern
│   └── utils/             ← Money formatter, UUID helper, Logger
├── features/
│   ├── onboarding/        ← Agent 1 logic & UI
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── transaction/       ← Agent 2, 3 + Pending workflow
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── vision/            ← Agent 4, 5 logic
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── catalog/           ← Master Barang + Kategori
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── dashboard/         ← Bento Box, Banner
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── reports/           ← Laporan, Export
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

### 5.2 Dependency Injection Setup

Pendaftaran service dilakukan di `lib/core/di/injection.dart`.

```dart
final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Services
  getIt.registerLazySingleton<DatabaseService>(() => DatabaseServiceImpl());
  getIt.registerLazySingleton<AiService>(() => GemmaAiService());
  getIt.registerLazySingleton<VoiceService>(() => VoiceServiceImpl());
  
  // Repositories
  getIt.registerFactory<TransactionRepository>(() => TransactionRepositoryImpl(getIt()));
}
```

---

## 6. Agentic Workflows & AI Integration

WarungPintar mengoperasikan **lima agent Gemma 4**. Semua agent mengakses AI melalui `AiService` interface untuk memastikan **testability** (dapat di-mock).

### 6.1 AI Service Interface (Abstract)

Didefinisikan untuk memungkinkan mocking pada Unit Test.

```dart
// lib/core/ai/ai_service.dart
abstract class AiService {
  Future<Result<ToolCallResult, AiFailure>> infer({
    required String systemPrompt,
    required String userInput,
    String? imageBase64,
  });
}

// Implementasi Nyata
class GemmaAiService implements AiService {
  @override
  Future<Result<ToolCallResult, AiFailure>> infer({
    required String systemPrompt,
    required String userInput,
    String? imageBase64,
  }) async {
    try {
      final raw = await GemmaIsolateService.infer(systemPrompt, userInput, imageBase64);
      final parsed = parseToolCall(raw);
      return Success(parsed);
    } on FormatException catch (e) {
      return Error(InvalidJsonOutputFailure(e.message));
    } catch (e) {
      return Error(ModelNotLoadedFailure());
    }
  }
}
```

### 6.2 Error & Failure Hierarchy

Standarisasi error handling menggunakan `sealed class` untuk coverage penuh.

```dart
// lib/core/error/failures.dart
sealed class AiFailure {
  final String message;
  const AiFailure(this.message);
}

final class ModelNotLoadedFailure extends AiFailure {
  const ModelNotLoadedFailure() : super("Model AI gagal dimuat");
}

final class InferenceTimeoutFailure extends AiFailure {
  const InferenceTimeoutFailure() : super("Proses AI timeout");
}

final class InvalidJsonOutputFailure extends AiFailure {
  final String rawOutput;
  const InvalidJsonOutputFailure(this.rawOutput) : super("Output AI bukan JSON valid");
}

final class ImageUnreadableFailure extends AiFailure {
  const ImageUnreadableFailure() : super("Gambar tidak terbaca");
}
```

### 6.3 Agent 1: Conversational Onboarding

**Objektif:** Setup ERP awal lewat percakapan — zero form, zero keystroke.

**State Machine:**
```
State 0 (First Launch) → database kosong → trigger voice prompt
State 1 (Listening)    → STT capture user response
State 2 (Inference)    → Gemma 4 via AiService → JSON tool call
State 3 (Execution)    → UseCase eksekusi setup_business() ke SQLite
State 4 (Feedback)     → Dashboard populate, AI konfirmasi
```

**System Prompt:**
```text
Kamu adalah asisten setup WarungPintar. Analisa ucapan pengguna dan panggil fungsi setup.
Gunakan HANYA JSON valid sesuai skema. Jangan tambahkan teks lain selain JSON.
Jika tidak cukup informasi, output: {"name": "clarify", "arguments": {"question": "<pertanyaan>"}}

TOOLS: [lihat Appendix A — setup_business]
```

### 6.4 Agent 2: Long-Speech Voice Transaction (Core Kasir)

**Objektif:** Konversi ucapan panjang multi-item menjadi array transaksi pending. Tidak blocking — semua langsung masuk pending queue, dikonfirmasi belakangan.

**Fitur Kunci:**
-   STT dengan VAD (Voice Activity Detection) threshold panjang — tidak auto-stop terlalu cepat
-   Satu ucapan bisa menghasilkan array `transactions` multi-item sekaligus
-   Semua hasil masuk status `pending`, **bukan langsung confirmed**
-   Omzet di dashboard hanya menghitung transaksi `status = confirmed`

**Edge Case Handling:**

| Kasus | Behavior |
|---|---|
| Harga tidak disebutkan | Ambil `default_price_sen` dari `stock`; insert sebagai pending |
| Item ambigu (misal "kerupuk" ada 3 jenis) | Insert pending dengan flag `needs_clarification = true` |
| Nominal verbal ("empat puluh lima ribu") | Konversi ke integer sen: 4500000 |
| Item tidak dikenal sama sekali | Tetap insert pending, item_name as-is, harga 0 + flag clarify |
| Bulk multi-item satu ucapan | Output array transactions dalam satu tool call |

**System Prompt:**
```text
Kamu kasir WarungPintar. Ubah ucapan pengguna menjadi transaksi JSON.
Aturan wajib:
- "jual"/"laku"/"terjual" = sell (pemasukan)
- "beli"/"kulakan"/"stok"/"masuk" = buy (pengeluaran)
- total_price_sen = total rupiah × 100 (bukan per satuan)
- Harga harus integer bulat, TIDAK boleh float
- Jika harga tidak disebutkan, gunakan default dari konteks: {stock_context}
- Jika item ambigu (ada beberapa jenis), set needs_clarification: true
- Jangan pernah menebak harga jika tidak ada default
- SEMUA transaksi statusnya pending — juri agent lain yang konfirmasi

TOOLS: [lihat Appendix A — record_transactions]
```

### 6.5 Agent 3: Pending Confirmation via Voice

**Objektif:** Konfirmasi batch transaksi pending lewat suara — bisa "semua benar", "parsial benar", atau ubah satu item.

**Flow:**
1.  User tap tab Pending → pilih "Konfirmasi via suara"
2.  AI bacakan summary: *"Ada 7 transaksi pending. Item pertama: Beras 3 kilo harga empat puluh lima ribu — konfirmasi?"*
3.  User bisa jawab:
    -   "Ya" / "Benar" / "Oke" → item dikonfirmasi, lanjut item berikutnya
    -   "Semua benar" → seluruh pending dikonfirmasi sekaligus
    -   "Ganti lima puluh ribu" → update harga item ini, konfirmasi
    -   "Lewati" / "Skip" → item tetap pending, lanjut berikutnya
    -   "Hapus" → soft delete item ini

**System Prompt:**
```text
Kamu membantu konfirmasi transaksi pending WarungPintar.
Item saat ini: {current_item_json}
Semua item pending: {pending_list_json}

Analisa jawaban pengguna dan output JSON action.
Jangan menebak — jika tidak jelas, output clarify.

TOOLS: [lihat Appendix A — confirm_transactions]
```

### 6.6 Agent 4: Vision Receipt Parser (Foto Struk)

**Objektif:** Foto struk/nota supplier → AI parse semua item → masuk pending queue.

**User Flow:**
1.  Tap FAB → pilih ikon kamera
2.  Pilih "Foto Struk Supplier"
3.  Camera intent → foto struk
4.  Image compress ke JPEG ≤ 512KB, encode base64
5.  Gemma 4 E2B multimodal inference via `AiService`
6.  Output JSON `record_transactions` (semua tipe `buy`, status `pending`)
7.  Preview card tampil — user bisa langsung konfirmasi atau edit dulu
8.  User tap "Simpan" atau konfirmasi via suara

**System Prompt (Vision — Struk):**
```text
Kamu adalah parser struk belanja WarungPintar.
Dari gambar struk/nota, ekstrak semua item yang dibeli beserta harga total per item.
Semua transaksi dari struk adalah tipe "buy" (kulakan/modal), status "pending".
Output HANYA JSON valid sesuai skema record_transactions.
Konversi semua harga ke sen (× 100).
Jika gambar tidak terbaca, output: {"error": "image_unreadable"}.

TOOLS: [lihat Appendix A — record_transactions]
```

**Implementasi Dart (Riverpod + GetIt):**
```dart
// Controller menggunakan Riverpod
Future<void> parseReceiptImage(File imageFile) async {
  final compressed = await FlutterImageCompress.compressWithFile(
    imageFile.path, minWidth: 800, quality: 70,
  );
  final base64Image = base64Encode(compressed!);
  
  // Panggil Service via DI
  final aiService = getIt<AiService>();
  final result = await aiService.infer(
    systemPrompt: visionReceiptSystemPrompt,
    userInput: "", // Vision only
    imageBase64: base64Image,
  );
  
  // Handle Result pattern konsisten
  switch(result) {
    case Success(data: final toolCall): 
      // Parse toolCall & insert to DB
    case Error(failure: final f): 
      // Show UI error based on AiFailure type
  }
}
```

### 6.7 Agent 5: Vision Product Parser (Foto Kemasan — Master Barang)

**Objektif:** Foto kemasan produk → AI baca nama produk + ukuran/berat → pre-fill form master barang. **AI tidak menebak harga** — harga wajib disebutkan user via suara.

**User Flow:**
1.  Di tab Katalog → tap FAB → "Foto Kemasan"
2.  Camera intent → foto kemasan produk
3.  Gemma 4 vision inference → ekstrak nama + ukuran
4.  Preview form pre-filled: nama produk, ukuran, kategori (AI tebak dari nama)
5.  AI bertanya via suara: *"Nama produk: Tepung Terigu Segitiga Biru 1 kg. Harga berapa Bu?"*
6.  User jawab via suara: "Delapan ribu"
7.  AI parse harga → insert ke `stock` dengan `default_price_sen`

**System Prompt (Vision — Kemasan):**
```text
Kamu membantu menambah barang baru di WarungPintar dari foto kemasan.
Dari gambar kemasan produk, ekstrak:
- Nama produk (brand + jenis + ukuran/berat jika ada)
- Estimasi kategori (Sembako, Minuman, Snack, dll)
JANGAN menebak harga — harga tidak ada di kemasan.
Output HANYA JSON valid.

TOOLS: [lihat Appendix A — parse_product_from_image]
```

---

## 7. Non-Blocking Pending Workflow

### 7.1 Status Transaksi

```
PENDING   → baru dicatat via suara/foto, belum dikonfirmasi
CONFIRMED → sudah dikonfirmasi user (via suara atau manual)
DELETED   → soft delete, tidak hilang dari audit log
```

### 7.2 Aturan Kalkulasi Dashboard

-   **Omzet terkonfirmasi:** hanya transaksi `status = confirmed`
-   **Pending indicator:** banner kuning di dashboard menampilkan jumlah pending
-   **Transaksi pending di list:** tampil dengan tanda `~Rp` (tilde) dan badge kuning — bukan angka pasti

### 7.3 Tidak Ada Batas Waktu

Transaksi pending bisa dikonfirmasi kapan saja — 5 menit atau 3 jam setelah dicatat. Tidak ada auto-expire. Pending tetap ada sampai user konfirmasi atau hapus.

### 7.4 Ambigu & Klarifikasi

Item dengan `needs_clarification = true` ditampilkan dengan badge merah di pending list. User harus memilih item yang tepat sebelum bisa dikonfirmasi.

---

## 8. Master Data

### 8.1 Master Barang (Katalog)

**Fitur:**
-   List barang dengan search dan filter per kategori
-   Tambah barang via: foto kemasan (Agent 5) + suara untuk harga, atau manual form
-   Edit barang — perubahan harga membuat **entry baru di price history**, bukan overwrite
-   Soft delete — barang tidak pernah benar-benar dihapus
-   Badge "harga berubah N×" jika ada lebih dari satu entry di price history

**Aturan harga:**
-   Setiap perubahan harga disimpan sebagai record baru di tabel `price_history`
-   Setiap transaksi menyimpan `price_at_transaction_sen` — tidak bergantung pada harga saat ini
-   Riwayat harga tidak bisa diedit atau dihapus (append-only)

### 8.2 Master Kategori

Diakses via drawer dari halaman Katalog — tidak ada tab tersendiri.

**Fitur:**
-   List kategori dengan jumlah barang per kategori
-   Tambah kategori baru (nama saja)
-   Edit nama kategori
-   Hapus kategori hanya jika tidak ada barang aktif — modal konfirmasi

---

## 9. Audit Log & Logging untuk Juri

### 9.1 Prinsip Audit Log

-   **Append-only** — tidak ada UPDATE atau DELETE pada tabel `audit_logs`
-   Setiap aksi pada transaksi menghasilkan satu row audit
-   Raw AI output (JSON mentah dari Gemma sebelum parsing) disimpan verbatim
-   STT transcript mentah disimpan verbatim
-   Tersedia via drawer di setiap transaksi

### 9.2 Action Types

```sql
'CREATED_BY_AI_VOICE'    -- transaksi dari suara, status pending
'CREATED_BY_AI_IMAGE'    -- transaksi dari foto struk, status pending
'CREATED_MANUAL'         -- transaksi dari form manual
'CONFIRMED_BY_USER'      -- konfirmasi — bisa single atau bulk via suara
'CONFIRMED_BULK_VOICE'   -- konfirmasi semua atau parsial via voice agent
'EDITED_BY_USER'         -- edit harga atau nama, sebelum atau setelah confirm
'NEEDS_CLARIFICATION'    -- AI menandai item ambigu
'CLARIFIED_BY_USER'      -- user memilih item yang tepat
'DELETED'                -- soft delete
```

### 9.3 Struktur Row Audit Log

```
id                TEXT    -- UUIDv7
transaction_id    TEXT    -- FK ke transactions
action            TEXT    -- dari enum di atas
raw_input_source  TEXT    -- STT transcript atau path image
ai_raw_output     TEXT    -- JSON mentah dari Gemma (sebelum _stripJsonFences)
state_snapshot    TEXT    NOT NULL,                         -- JSON dump row saat itu
created_at        DATETIME
```

### 9.4 Bukti Teknis untuk Juri

Di drawer audit log setiap transaksi, ditampilkan:

1.  **STT Transcript** — teks mentah yang didengar (bukti input nyata)
2.  **Raw AI JSON** — output Gemma sebelum diparsing (bukti function calling aktif)
3.  **Idempotency Key** — bukti anti-double-submit aktif
4.  **Input Method** — voice / image / manual
5.  **Timestamp chain** — dari capture → inference → insert → confirm

Di video demo: split screen menampilkan Logcat filter `WarungPintar/AuditLog` saat transaksi masuk — raw JSON Gemma terlihat real-time.

---

## 10. Enterprise-Grade Architecture & Data Integrity

### 10.1 Integer Money Protocol (Sen)

-   **Aturan:** TIDAK PERNAH simpan nilai moneter sebagai `FLOAT`, `DECIMAL`, atau `DOUBLE`
-   **Implementasi:** Semua nilai Rupiah × 100 sebelum insert, disimpan sebagai `BIGINT` (sen)
-   **UI:** Dibagi 100 dan diformat via `NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)`
-   **Contoh:** User input `Rp 45.000` → Disimpan: `4500000` → Ditampilkan: `Rp 45.000`

### 10.2 Idempotency Constraint (Anti Double-Submit)

Device low-end lag saat Gemma 4 inference menyebabkan user double-tap. Setiap input voice/image generate `UUIDv4` sebagai `idempotency_key`. SQLite enforce `UNIQUE` constraint. Submit kedua diabaikan secara silent.

```dart
Future<void> insertTransaction(TransactionModel tx) async {
  final idemKey = const Uuid().v4();
  try {
    await db.execute('''
      INSERT INTO transactions
        (id, idempotency_key, item_name, quantity, amount_sen,
         price_at_transaction_sen, transaction_type, status, input_method)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      Uuid().v7(), idemKey, tx.itemName, tx.quantity,
      tx.amountSen, tx.priceAtTransactionSen,
      tx.type, 'pending', tx.inputMethod
    ]);
  } on DatabaseException catch (e) {
    if (e.isUniqueConstraintError()) return; // Silent ignore duplikat
    rethrow;
  }
}
```

### 10.3 Offline-First Primary Keys (UUIDv7)

-   Tidak pernah gunakan `AUTOINCREMENT` integer
-   UUIDv7 (time-sortable) via package `uuid ^4.3.3`
-   Memungkinkan sorting by creation time tanpa `ORDER BY created_at`
-   Aman untuk roadmap cloud sync — tidak ada collision risk

### 10.4 Flutter Isolate untuk AI Inference

```dart
class GemmaIsolateService {
  static Future<String> infer(String prompt, String input, String? imageBase64) async {
    final responsePort = ReceivePort();
    _sendPort.send({
      'prompt': prompt,
      'input': input,
      'image': imageBase64,
      'replyPort': responsePort.sendPort,
    });
    return await responsePort.first as String;
  }

  static void _gemmaWorker(SendPort mainSendPort) async {
    // Singleton — tidak pernah load ulang selama app hidup
    final gemma = await GemmaModel.load(
      'assets/gemma-4-E2B-it-litertlm-Q4_K_M.litertlm'
    );
    final port = ReceivePort();
    mainSendPort.send(port.sendPort);
    await for (final msg in port) {
      final result = await gemma.generate(
        prompt: msg['prompt'] + msg['input'],
        imageBase64: msg['image'],
        maxTokens: 512,
      );
      (msg['replyPort'] as SendPort).send(result);
    }
  }
}
```

### 10.5 Robust JSON Parser

```dart
String _stripJsonFences(String raw) {
  var clean = raw.replaceAll(RegExp(r'```json\s*'), '');
  clean = clean.replaceAll(RegExp(r'```\s*'), '');
  final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
  if (jsonMatch == null) throw const FormatException('No JSON found');
  final parsed = jsonDecode(jsonMatch.group(0)!);
  return jsonEncode(parsed);
}

ToolCallResult parseToolCall(String jsonStr) {
  try {
    final clean = _stripJsonFences(jsonStr);
    final map = jsonDecode(clean) as Map<String, dynamic>;
    if (!map.containsKey('name')) throw FormatException('Missing name');
    if (!map.containsKey('arguments')) throw FormatException('Missing arguments');
    return ToolCallResult.success(map);
  } on FormatException catch (e) {
    return ToolCallResult.fallback(reason: e.message);
  }
}
```

### 10.6 Price History — Harga Tidak Boleh Overwrite

```dart
Future<void> updateItemPrice(String stockId, int newPriceSen, String reason) async {
  // Buat entry baru di price_history — JANGAN update kolom di stock
  await db.execute('''
    INSERT INTO price_history (id, stock_id, price_sen, reason, effective_from)
    VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
  ''', [Uuid().v7(), stockId, newPriceSen, reason]);

  // Update cache harga saat ini di stock (untuk referensi AI)
  await db.execute('''
    UPDATE stock SET default_price_sen = ?, last_updated = CURRENT_TIMESTAMP
    WHERE id = ?
  ''', [newPriceSen, stockId]);
  // Transaksi lama TIDAK terpengaruh — mereka menyimpan price_at_transaction_sen
}
```

---

## 11. Database Schema (SQLite WAL Mode)

```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA foreign_keys = ON;

-- Transaksi utama
CREATE TABLE transactions (
    id                      TEXT    PRIMARY KEY,               -- UUIDv7
    idempotency_key         TEXT    UNIQUE NOT NULL,           -- Anti double-submit
    item_name               TEXT    NOT NULL,
    quantity                INTEGER NOT NULL CHECK(quantity > 0),
    amount_sen              INTEGER NOT NULL CHECK(amount_sen >= 0),
    price_at_transaction_sen INTEGER NOT NULL,                 -- Snapshot harga saat transaksi
    transaction_type        TEXT    NOT NULL CHECK(transaction_type IN ('sell', 'buy')),
    status                  TEXT    NOT NULL DEFAULT 'pending'
                              CHECK(status IN ('pending', 'confirmed', 'deleted')),
    needs_clarification     INTEGER DEFAULT 0,                 -- 1 jika item ambigu
    input_method            TEXT    NOT NULL CHECK(input_method IN ('voice', 'image', 'manual')),
    confirmed_at            DATETIME,                          -- NULL jika masih pending
    created_at              DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_deleted              INTEGER DEFAULT 0
);

CREATE INDEX idx_tx_date   ON transactions(date(created_at));
CREATE INDEX idx_tx_type   ON transactions(transaction_type);
CREATE INDEX idx_tx_status ON transactions(status);
CREATE INDEX idx_tx_method ON transactions(input_method);

-- Audit log — append-only, tidak boleh di-UPDATE/DELETE
CREATE TABLE audit_logs (
    id               TEXT    PRIMARY KEY,                      -- UUIDv7
    transaction_id   TEXT    NOT NULL REFERENCES transactions(id),
    action           TEXT    NOT NULL CHECK(action IN (
                       'CREATED_BY_AI_VOICE',
                       'CREATED_BY_AI_IMAGE',
                       'CREATED_MANUAL',
                       'CONFIRMED_BY_USER',
                       'CONFIRMED_BULK_VOICE',
                       'EDITED_BY_USER',
                       'NEEDS_CLARIFICATION',
                       'CLARIFIED_BY_USER',
                       'DELETED'
                     )),
    raw_input_source TEXT,   -- STT transcript atau path image
    ai_raw_output    TEXT,   -- JSON mentah dari Gemma sebelum parsing
    state_snapshot   TEXT    NOT NULL,                         -- JSON dump row saat itu
    created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Stok / Master Barang
CREATE TABLE stock (
    id                   TEXT    PRIMARY KEY,                  -- UUIDv7
    item_name            TEXT    UNIQUE NOT NULL,
    current_qty          INTEGER DEFAULT 0,
    default_price_sen    INTEGER DEFAULT 0,                    -- Cache harga terkini
    low_stock_threshold  INTEGER DEFAULT 5,
    category_id          TEXT    REFERENCES categories(id),
    is_deleted           INTEGER DEFAULT 0,
    last_updated         DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Riwayat harga — append-only
CREATE TABLE price_history (
    id             TEXT    PRIMARY KEY,                        -- UUIDv7
    stock_id       TEXT    NOT NULL REFERENCES stock(id),
    price_sen      INTEGER NOT NULL,
    reason         TEXT,                                       -- "Naik inflasi", "Ganti supplier", dll
    effective_from DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Master Kategori
CREATE TABLE categories (
    id         TEXT    PRIMARY KEY,                            -- UUIDv7
    name       TEXT    UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Pengaturan app
CREATE TABLE app_settings (
    key        TEXT PRIMARY KEY,
    value      TEXT NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

## 12. UI/UX Specifications

### 12.1 Prinsip Desain untuk Usia 40+

Mengacu pada ERP best practice untuk pengguna 40–70 tahun:

| Elemen | Nilai |
|---|---|
| Body / input teks | 16–18sp |
| Label form | 16sp minimum |
| Teks tombol | 16–18sp |
| Heading section | 20–24sp |
| Caption / helper | 14sp minimum |
| Touch target semua elemen | 48dp minimum |
| Kontras teks | WCAG AAA (7:1) |
| Warna selalu dikombinasi dengan ikon + label teks | Wajib |

### 12.2 Bento Box Dashboard Layout

-   **Border:** 0.5px solid `#E0E0E0`, radius `12px`, elevation `0px`
-   **Background:** `#FFFFFF` di atas scaffold `#F8F9FA`
-   **Hierarki:**
    -   Full-width (lebar penuh): Omzet Terkonfirmasi Hari Ini
    -   2 kolom: Profit (hijau) | Modal Keluar (merah)
    -   Banner pending: kuning, selalu di atas bento grid jika ada pending
    -   Scroll horizontal: stock alert (barang hampir habis)
    -   List: 5 transaksi terakhir dengan badge status + badge input method

### 12.3 FAB Ekspansi Tiga Mode

```
[Tap FAB] → Ekspansi ke 3 sub-FAB:
  🎤  Suara    — voice input panjang multi-item
  📷  Foto     — kamera (struk supplier atau kemasan produk)
  ✏️  Manual   — form fallback
```

Saat FAB expand: konten di belakang di-dim (overlay semi-transparan). Tap FAB lagi (berubah jadi ×) untuk tutup.

Sub-FAB foto memunculkan pilihan kedua:
```
[Tap Foto] → Bottom sheet:
  📄  Foto Struk Supplier  → Agent 4 (Vision Struk)
  📦  Foto Kemasan Produk  → Agent 5 (Vision Kemasan)
```

### 12.4 Pending Banner (Non-Blocking)

```
┌─────────────────────────────────────────────┐
│  ⏳ 7 transaksi pending  [🎤 Konfirmasi]    │  ← Kuning, selalu di atas
└─────────────────────────────────────────────┘
```

-   Muncul hanya jika ada pending
-   Angka update real-time tanpa reload (Reactive via Riverpod)
-   Tap "Konfirmasi" langsung buka Agent 3 (voice confirm)

### 12.5 Status Badge Transaksi

Setiap transaksi di list menampilkan dua badge:

| Badge | Warna | Contoh |
|---|---|---|
| Input method | Biru (voice), Hijau (image), Abu (manual) | 🎤 suara |
| Status | Hijau (confirmed), Kuning (pending), Merah (clarify) | ⏳ pending |

### 12.6 Haptic Matrix

| State | Haptic |
|---|---|
| AI parse sukses, langsung confirmed | 1 vibrasi pendek (50ms) |
| AI parse sukses, masuk pending | 2 vibrasi ringan (30ms–50ms) |
| Item ambigu, perlu klarifikasi | 3 vibrasi ringan cepat |
| Konfirmasi bulk selesai | 1 vibrasi panjang (120ms) |
| Error / validasi gagal | 3 vibrasi berat |
| Aksi destruktif (delete) | 1 vibrasi berat (100ms) |

### 12.7 Typography & Color

-   **Font:** Plus Jakarta Sans (screen-optimized, karakter yang jelas untuk usia 40+)
-   **Numerik:** `font-variant-numeric: tabular-nums` untuk semua `amount_sen`
-   **Primary:** `#1976D2`
-   **Confirmed / Profit:** `#059669` (kontras 4.5:1+ di putih)
-   **Pending:** `#BA7517` pada background `#FAEEDA`
-   **Error / Modal Keluar:** `#DC2626`
-   **Pending amount:** didahului tilde `~Rp` untuk membedakan dari angka pasti

### 12.8 Toast & Error Handling

| Tipe | Dismiss |
|---|---|
| Sukses | Auto-dismiss 3 detik |
| Info | Auto-dismiss 4 detik |
| Warning | Manual dismiss |
| Error | **Manual dismiss — tidak pernah auto** |

---

## 13. Development Protocol

### 13.1 Sprint 6 Hari

| Hari | Focus | Deliverable |
|---|---|---|
| **Day 1** | Base & DI & Router | Flutter scaffold, Folder Structure setup, GetIt setup, GoRouter config, SQLite DDL lengkap, UUIDv7, Riverpod providers, `analysis_options.yaml`. |
| **Day 2** | AI Runtime | flutter_gemma load, Gemma Isolate, JSON parser robust, system prompt semua agent, Error Handling pattern. |
| **Day 3** | Agent 1, 2, 3 | Onboarding, long-speech voice transaction, pending confirmation voice. |
| **Day 4** | Agent 4, 5 + Master | Vision struk, vision kemasan + suara harga, CRUD master barang+kategori, price history. |
| **Day 5** | UI/UX + Audit | Bento Box, pending banner, badge system, audit log drawer, haptic matrix, Unit Test & Integration Test. |
| **Day 6** | Deliverables | Video recording, Kaggle Notebook, writeup, GitHub, APK build (obfuscated). |

**Cut priority jika waktu habis (urutan aman):**
1.  Chart di Laporan (keep list, cut chart)
2.  PDF export (replace CSV)
3.  Bahasa Sunda (keep Indonesia saja)

**Tidak boleh di-cut:**
-   Agent 4 Vision Struk (differentiator utama)
-   Agent 5 Vision Kemasan (differentiator kedua)
-   Pending workflow non-blocking
-   Audit log dengan raw AI output
-   Offline compliance

### 13.2 Quality Assurance

**Unit Test Wajib (Dengan Mocks):**
```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

// Generate mocks: dart run build_runner build
@GenerateMocks([AiService, TransactionRepository])
void main() {
  late MockAiService mockAiService;
  late MockTransactionRepository mockRepo;

  setUp(() {
    mockAiService = MockAiService();
    mockRepo = MockTransactionRepository();
  });

  test('Agent 2: Parse voice input returns valid ToolCall', () async {
    // Arrange
    final input = "Jual beras 3 kilo 45000";
    final expected = ToolCall(name: 'record_transactions', arguments: {...});
    when(mockAiService.infer(
      systemPrompt: anyNamed('systemPrompt'),
      userInput: input,
      imageBase64: null
    )).thenAnswer((_) async => Success(expected));

    // Act
    final result = await mockAiService.infer(systemPrompt: "prompt", userInput: input);

    // Assert
    expect(result, isA<Success<ToolCallResult, AiFailure>>());
    verify(mockAiService.infer(systemPrompt: anyNamed('systemPrompt'), userInput: input)).called(1);
  });

  test('Money: string to sen conversion', () {
    expect(rupiahToSen('45000'), equals(4500000));
    expect(senToDisplay(4500000), equals('Rp 45.000'));
  });

  test('JSON fence stripper handles malformed output', () {
    const raw = '```json\n{"name": "test"}\n```';
    expect(stripJsonFences(raw), equals('{"name": "test"}'));
  });
}
```

**Integration Test (Database):**
```dart
test('Idempotency: duplicate insert silent', () async {
  // Gunakan DB nyata di test environment
  final db = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();
  final dao = db.transactionDao;

  await dao.insertTransaction(sampleTx, idemKey: 'key-001');
  await dao.insertTransaction(sampleTx, idemKey: 'key-001');
  
  final rows = await dao.findAllTransactions();
  expect(rows.length, equals(1));
});
```

**Device Test:**
-   Physical Android ≤ 4GB RAM, Airplane Mode ON
-   Double-tap submit: hanya 1 row di database
-   Voice panjang (10+ item): semua masuk pending, tidak crash
-   Konfirmasi bulk via suara: semua item pindah ke confirmed
-   Memory pressure: tidak crash, model tidak di-unload

---

## 14. Kaggle Notebook (Technical Proof)

### 14.1 Struktur Notebook

```
Section 1: Setup & Model Loading
  - Load Gemma 4 E2B dari Kaggle Models
  - Verify LiteRT runtime

Section 2: Function Calling Proof — Agent 2 (Voice)
  - Input: ucapan multi-item bahasa Indonesia
  - Output: JSON array transactions valid
  - Validasi schema compliance + status pending

Section 3: Function Calling Proof — Agent 3 (Confirm)
  - Input: "semua benar" dan "ganti lima puluh ribu"
  - Output: JSON confirm_transactions actions

Section 4: Multimodal Vision Proof — Agent 4 (Struk)
  - Input: gambar struk belanja (sample)
  - Output: JSON record_transactions
  - Accuracy vs ground truth manual

Section 5: Multimodal Vision Proof — Agent 5 (Kemasan)
  - Input: gambar kemasan produk
  - Output: JSON parse_product (nama + kategori, tanpa harga)
  - Verifikasi: tidak ada harga di output

Section 6: JSON Robustness Test
  - Simulasi output dengan markdown fence, trailing text
  - Tunjukkan _stripJsonFences() bekerja
  - Edge case: output kosong, JSON malformed

Section 7: Integer Money Validation
  - "45.000" → 4500000 → "Rp 45.000"
  - Float vs integer: tunjukkan precision loss float

Section 8: Price History Isolation Test
  - Insert transaksi harga lama
  - Update harga item
  - Verifikasi transaksi lama tidak berubah

Section 9: Performance Benchmark
  - Inference time per query (voice)
  - Inference time per image (vision)
  - Memory usage estimate
```

---

## 15. Hackathon Submission Strategy

### 15.1 Kaggle Writeup (< 1.500 kata)

1.  **Digital Equity Gap (200 kata):** Mengapa SaaS cloud dan form gagal untuk UMKM. Ibu Warsih saat jam ramai.
2.  **Five Gemma 4 Agents (500 kata):** Onboarding, long-speech kasir, voice confirm pending, vision struk, vision kemasan.
3.  **Enterprise Integrity at Edge (400 kata):** Price history immutable, pending non-blocking, UUIDv7, idempotency, audit log raw AI output.
4.  **Bukti Teknis (200 kata):** Kaggle Notebook, Logcat, APK demo.
5.  **Roadmap (100 kata):** P2P Bluetooth sync, RAG lokal, QRIS offline.
6.  **Links (100 kata):** GitHub, APK, YouTube.

### 15.2 YouTube Video Storyboard (3:00)

**[0:00–0:20] Hook**
Warung ramai. Ibu Warsih melayani 3 pembeli sekaligus, buku catatan tertumpuk. Teks: *"Setiap hari, 64 juta warung mencatat transaksi... dengan cara ini."*

**[0:20–0:40] Problem**
Teks besar: *"Software terlalu rumit. Internet tidak selalu ada. Jam ramai tidak ada waktu ketik."*

**[0:40–1:05] Onboarding**
Airplane Mode terlihat di status bar. App pertama buka. AI tanya. Ibu Warsih jawab natural. Dashboard populate. Teks: *"Zero form. Zero cloud."*

**[1:05–1:35] Long-Speech Multi-Item**
Ibu Warsih melayani 3 pembeli, tap mic sekali: *"Beras tiga kilo empat lima ribu, kopi dua saset tiga ribu, telur enam butir sembilan ribu, kerupuk setengah kilo delapan ribu."* FAB morph. Pending banner muncul: "4 transaksi pending". Timer: < 8 detik.

**[1:35–1:55] Voice Bulk Confirm**
30 menit kemudian. Ibu Warsih tahan mic: *"Semua benar."* Pending badge hilang. Dashboard omzet naik. Teks: *"Konfirmasi 4 transaksi. Satu napas."*

**[1:55–2:20] Vision Struk**
Pak Budi datang dengan nota. Tap kamera → foto nota. Teks: *"Gemma 4 membaca struk..."* Preview card muncul. Konfirmasi. Semua masuk ledger. Teks: *"Foto struk → Tercatat."*

**[2:20–2:40] Vision Kemasan + Audit Log**
Tambah barang baru. Foto kemasan Tepung Terigu. AI pre-fill nama. Tanya harga via suara. Masuk katalog. Split: app kiri, audit log kanan — raw JSON Gemma terlihat. Teks: *"Bukti nyata. Bukan demo palsu."*

**[2:40–2:55] Impact**
Akhir hari. Ibu Warsih tap export PDF. Laporan bersih. Buku tulis ditutup. Teks: *"Laba hari ini: Rp 287.000. Tanpa hitung manual."*

**[2:55–3:00] Outro**
Logo + Gemma 4 Good badge. GitHub + APK link.

---

## Appendix A: Tool Call JSON Schema Lengkap

```json
{
  "tools": [
    {
      "name": "setup_business",
      "description": "Membuat kategori dan inventaris awal warung dari percakapan onboarding.",
      "parameters": {
        "type": "object",
        "properties": {
          "categories": { "type": "array", "items": { "type": "string" } },
          "items": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "name":              { "type": "string" },
                "category":          { "type": "string" },
                "default_price_sen": { "type": "integer" }
              },
              "required": ["name", "category", "default_price_sen"]
            }
          }
        },
        "required": ["categories", "items"]
      }
    },
    {
      "name": "record_transactions",
      "description": "Mencatat satu atau lebih transaksi. Status selalu pending.",
      "parameters": {
        "type": "object",
        "properties": {
          "transactions": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "item_name":           { "type": "string" },
                "quantity":            { "type": "integer", "minimum": 1 },
                "total_price_sen":     { "type": "integer", "minimum": 0 },
                "transaction_type":    { "type": "string", "enum": ["sell", "buy"] },
                "needs_clarification": { "type": "boolean", "default": false }
              },
              "required": ["item_name", "quantity", "total_price_sen", "transaction_type"]
            }
          }
        },
        "required": ["transactions"]
      }
    },
    {
      "name": "confirm_transactions",
      "description": "Konfirmasi, edit, atau lewati transaksi pending via suara.",
      "parameters": {
        "type": "object",
        "properties": {
          "actions": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "transaction_id": { "type": "string" },
                "action":         { "type": "string", "enum": ["confirm", "edit_price", "skip", "delete"] },
                "new_price_sen":  { "type": "integer" }
              },
              "required": ["transaction_id", "action"]
            }
          },
          "confirm_all": { "type": "boolean", "default": false }
        },
        "required": ["actions"]
      }
    },
    {
      "name": "parse_product_from_image",
      "description": "Ekstrak nama dan kategori produk dari foto kemasan. TIDAK menghasilkan harga.",
      "parameters": {
        "type": "object",
        "properties": {
          "product_name":      { "type": "string" },
          "estimated_category": { "type": "string" },
          "size_or_weight":    { "type": "string" }
        },
        "required": ["product_name", "estimated_category"]
      }
    },
    {
      "name": "clarify",
      "description": "Digunakan ketika AI tidak cukup informasi untuk melanjutkan.",
      "parameters": {
        "type": "object",
        "properties": {
          "question": { "type": "string" }
        },
        "required": ["question"]
      }
    }
  ]
}
```

---

## Appendix B: Dependency Definitions

```yaml
name: warung_pintar
description: "Gemma 4 Good Hackathon — Offline Multimodal ERP untuk UMKM"
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management & DI
  flutter_riverpod: ^2.6.0
  get_it: ^7.6.0
  
  # Routing
  go_router: ^14.0.0

  # AI & Vision
  flutter_gemma: ^0.2.0
  speech_to_text: ^7.0.0
  flutter_image_compress: ^2.2.0
  image_picker: ^1.1.0

  # Database & Utils
  sqflite: ^2.3.0
  path: ^1.9.0
  uuid: ^4.3.3
  intl: ^0.19.0
  fl_chart: ^0.69.0
  vibration: ^1.8.3
  logger: ^2.0.0
  
  # Export
  pdf: ^3.11.0
  share_plus: ^10.0.0
  path_provider: ^2.1.0
  file_picker: ^8.0.0
  permission_handler: ^11.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.0
```

---

## Appendix C: Static Analysis Configuration

Konfigurasi `analysis_options.yaml` untuk memaksakan best practices dan menghindari bug umum (seperti forget to close streams).

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore
    
linter:
  rules:
    - avoid_print: true          # Gunakan package `logger` untuk Logcat proof
    - prefer_const_constructors: true
    - prefer_const_declarations: true
    - cancel_subscriptions: true # Kritis: Mencegah memory leak dari STT streams
    - close_sinks: true          # Kritis: Mencegah file handle leak
    - unawaited_futures: true    # Kritis: Memastikan async DB calls ditangani
```

---

## Appendix D: Checklist Submission Final

```
TEKNIS
[ ] APK jalan di device fisik ≤ 4GB RAM, Airplane Mode ON
[ ] Arsitektur: Folder Structure sesuai Section 5.1
[ ] DI: GetIt ter-setup dengan AiService Interface
[ ] Routing: GoRouter handle navigation & redirects
[ ] Agent 1 (onboarding) berfungsi
[ ] Agent 2 (long-speech multi-item) → pending queue
[ ] Agent 3 (voice bulk confirm) → "semua benar" dan parsial
[ ] Agent 4 (vision struk) → pending queue
[ ] Agent 5 (vision kemasan + voice harga) → master barang
[ ] Price history immutable — transaksi lama tidak berubah
[ ] Pending tidak masuk omzet confirmed
[ ] JSON parser robust — tidak crash pada output malformed
[ ] Idempotency: double submit = 1 row
[ ] Audit log: raw AI JSON tersimpan setiap transaksi
[ ] 0 hardcoded network URL
[ ] Build: APK Obfuscated
[ ] Linter: analysis_options.yaml aktif & passed

BUKTI VERIFIABLE
[ ] Audit log drawer menampilkan STT transcript + raw JSON Gemma
[ ] Screenshot Logcat: zero HttpClient call
[ ] Screenshot Android Network Profiler: 0 outbound connection
[ ] Kaggle Notebook publik: semua 5 agent dibuktikan
[ ] GitHub repo publik (Apache 2.0), README jelas, APK di Releases

DELIVERABLES
[ ] Video YouTube ≤ 3 menit, Airplane Mode visible di 3+ scene
[ ] Kaggle writeup < 1.500 kata
[ ] README: cara install, cara test offline, architecture diagram (Riverpod + GetIt)
```

---

**END OF PRODUCT REQUIREMENTS DOCUMENT v9.0.0**