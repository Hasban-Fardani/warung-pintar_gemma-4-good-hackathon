# Product Requirements Document: WarungPintar Cimahi
## Gemma 4 Good Hackathon Submission — Digital Equity & LiteRT Track

**Version:** 10.0.0 (AI Runtime Technical Specification Added)
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

Ibu miski bisa mencatat transaksi lewat suara panjang (multi-item sekaligus), memfoto struk belanja agar AI membaca dan mencatatnya otomatis, menambah barang baru lewat foto kemasan, serta mengkonfirmasi transaksi pending via suara — semua tanpa satu form yang diisi manual.

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

### 2.1 Primary — Ibu miski (Pemilik Warung)
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
Mengantar barang dua kali seminggu dengan nota pengiriman. Ibu miski perlu catat stok masuk massal — via foto nota atau suara sambil berbicara dengan Pak Budi.

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

Saat FAB expand: konten di belakang di-dim (overlay semi-transparan).
Tap FAB lagi (berubah jadi ×) untuk tutup.

Sub-FAB foto memunculkan pilihan kedua:
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

1.  **Digital Equity Gap (200 kata):** Mengapa SaaS cloud dan form gagal untuk UMKM. Ibu miski saat jam ramai.
2.  **Five Gemma 4 Agents (500 kata):** Onboarding, long-speech kasir, voice confirm pending, vision struk, vision kemasan.
3.  **Enterprise Integrity at Edge (400 kata):** Price history immutable, pending non-blocking, UUIDv7, idempotency, audit log raw AI output.
4.  **Bukti Teknis (200 kata):** Kaggle Notebook, Logcat, APK demo.
5.  **Roadmap (100 kata):** P2P Bluetooth sync, RAG lokal offline.
6.  **Links (100 kata):** GitHub, APK, YouTube.

### 15.2 YouTube Video Storyboard (3:00)

**[0:00–0:20] Hook**
Warung ramai. Ibu miski melayani 3 pembeli sekaligus, buku catatan tertumpuk. Teks: *"Setiap hari, 64 juta warung mencatat transaksi... dengan cara ini."*

**[0:20–0:40] Problem**
Teks besar: *"Software terlalu rumit. Internet tidak selalu ada. Jam ramai tidak ada waktu ketik."*

**[0:40–1:05] Onboarding**
Airplane Mode terlihat di status bar. App pertama buka. AI tanya. Ibu miski jawab natural. Dashboard populate. Teks: *"Zero form. Zero cloud."*

**[1:05–1:35] Long-Speech Multi-Item**
Ibu miski melayani 3 pembeli, tap mic sekali: *"Beras tiga kilo empat lima ribu, kopi dua saset tiga ribu, telur enam butir sembilan ribu, kerupuk setengah kilo delapan ribu."* FAB morph. Pending banner muncul: "4 transaksi pending". Timer: < 8 detik.

**[1:35–1:55] Voice Bulk Confirm**
30 menit kemudian. Ibu miski tahan mic: *"Semua benar."* Pending badge hilang. Dashboard omzet naik. Teks: *"Konfirmasi 4 transaksi. Satu napas."*

**[1:55–2:20] Vision Struk**
Pak Budi datang dengan nota. Tap kamera → foto nota. Teks: *"Gemma 4 membaca struk..."* Preview card muncul. Konfirmasi. Semua masuk ledger. Teks: *"Foto struk → Tercatat."*

**[2:20–2:40] Vision Kemasan + Audit Log**
Tambah barang baru. Foto kemasan Tepung Terigu. AI pre-fill nama. Tanya harga via suara. Masuk katalog. Split: app kiri, audit log kanan — raw JSON Gemma terlihat. Teks: *"Bukti nyata. Bukan demo palsu."*

**[2:40–2:55] Impact**
Akhir hari. Ibu miski tap export PDF. Laporan bersih. Buku tulis ditutup. Teks: *"Laba hari ini: Rp 287.000. Tanpa hitung manual."*

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
  
  # Networking (untuk model download — Section 16)
  dio: ^5.4.0

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
[ ] Model delivery: download on first launch + SHA-256 verify (Section 16)
[ ] Cold start UX: degraded mode aktif saat model loading (Section 16)
[ ] STT: bahasa pack id-ID availability check on startup (Section 16)
[ ] Fallback hierarchy Level 1–3 implemented (Section 16)
[ ] Vision quality gate: brightness + min size check sebelum inference (Section 16)

BUKTI VERIFIABLE
[ ] Audit log drawer menampilkan STT transcript + raw JSON Gemma
[ ] Screenshot Logcat: zero HttpClient call (saat normal operasi, bukan saat download model)
[ ] Screenshot Android Network Profiler: 0 outbound connection setelah model ter-download
[ ] Kaggle Notebook publik: semua 5 agent dibuktikan
[ ] GitHub repo publik (Apache 2.0), README jelas, APK di Releases

DELIVERABLES
[ ] Video YouTube ≤ 3 menit, Airplane Mode visible di 3+ scene
[ ] Kaggle writeup < 1.500 kata
[ ] README: cara install, cara test offline, architecture diagram (Riverpod + GetIt)
```

---

## Section 16: AI Runtime Technical Specification

> **Patch v10.0.0** — Menutup 10 gap teknis yang tidak tercakup di Section sebelumnya.
> Section ini bersifat **additive** — tidak mengubah konten Section 1–15.

---

### 16.1 Model Delivery Strategy

#### 16.1.1 Mekanisme: Bundle via Git LFS ZIP + Local Extraction

Strategi penyampaian file model `gemma-4-E2B-it-litertlm-Q4_K_M.litertlm` (estimasi ~2.5GB) diubah dari mekanisme *download-on-first-launch* menjadi mekanisme bundle ZIP:

- **Git LFS**: File berukuran besar dikompres dalam format `.zip` (`gemma.zip`) dan dikelola melalui Git LFS (`git lfs track "*.zip"`) untuk menghindari batasan 100MB dari GitHub.
- **App Asset**: `gemma.zip` ditempatkan dalam `assets/models/gemma.zip` dan didaftarkan di `pubspec.yaml`. APK yang dihasilkan akan menyertakan model ini.
- **Runtime Extraction**: Pada saat aplikasi pertama kali dijalankan, `AppInitNotifier` akan mengekstrak file ZIP tersebut ke Application Documents Directory secara asinkron (menggunakan isolat via `compute` dan package `archive`), lalu memuatnya melalui instruksi `FlutterGemma.installModel().fromFile()`.

Alasan Transisi:
- Menghindari isu memori tidak terpakai/korup dari pengunduhan yang tidak selesai.
- Menjamin status "Offline First" yang sejati (tanpa koneksi internet sama sekali, aplikasi siap digunakan sejak APK terinstal).
- Karena ini adalah kompetisi Hackathon (dan bukan rilis Google Play), batasan ukuran maksimal APK (Play Store) dapat dihiraukan.

**Kode Logika Instalasi (Referensi `app_init_notifier.dart`):**

```dart
// Ekstraksi Zip Asinkron ke Documents Directory
final extractedFile = await compute(_extractZipFromAsset, 'assets/models/gemma.zip');
await FlutterGemma.installModel(
  modelType: ModelType.gemma4,
  fileType: ModelFileType.litertlm,
).fromFile(extractedFile.path).install();
```

#### 16.1.4 UI Progress Download

```dart
// lib/features/dashboard/presentation/widgets/model_download_banner.dart
//
// Widget ini ditampilkan fullscreen overlay di atas SplashScreen
// selama state == MODEL_DOWNLOADING. Bukan snackbar — ini blocking UX
// karena tanpa model, app belum bisa beroperasi sama sekali.

class ModelDownloadScreen extends ConsumerWidget {
  const ModelDownloadScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatEta(int seconds) {
    if (seconds < 60) return '$seconds detik';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(modelDownloadProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download_outlined, size: 64, color: Color(0xFF1976D2)),
            const SizedBox(height: 24),
            const Text(
              'Mengunduh AI WarungPintar',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ini hanya dilakukan sekali. Setelah selesai,\napp berjalan 100% offline.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (downloadState is DownloadProgress) ...[
              LinearProgressIndicator(
                value: downloadState.percent,
                minHeight: 10,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: const Color(0xFFE0E0E0),
                color: const Color(0xFF1976D2),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(downloadState.percent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_formatBytes(downloadState.downloadedBytes)} / ${_formatBytes(downloadState.totalBytes)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Estimasi selesai: ${_formatEta(downloadState.estimatedSecondsRemaining)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            if (downloadState is DownloadVerifying)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Memverifikasi integritas file...'),
                ],
              ),
            if (downloadState is DownloadFailed)
              Column(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    (downloadState).reason,
                    style: const TextStyle(color: Color(0xFFDC2626)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(modelDownloadProvider.notifier).startDownload(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
```

---

### 16.2 Cold Start UX & Degraded Mode

#### 16.2.1 State Machine App Initialization

Didefinisikan sebagai `sealed class` di `lib/core/ai/app_init_state.dart`:

```dart
// lib/core/ai/app_init_state.dart

sealed class AppInitState {
  const AppInitState();
}

/// Model belum terdownload sama sekali — tampilkan ModelDownloadScreen
final class AppInitModelDownloading extends AppInitState {
  const AppInitModelDownloading();
}

/// Model sudah ada di disk, sedang di-load ke memori via flutter_gemma
final class AppInitModelLoading extends AppInitState {
  const AppInitModelLoading();
}

/// Model siap — AI fully operational
final class AppInitModelReady extends AppInitState {
  const AppInitModelReady();
}

/// Model gagal load (file korup, RAM tidak cukup, dll)
/// App masuk permanent manual mode — data tetap bisa dicatat ke SQLite
final class AppInitModelFailed extends AppInitState {
  final String reason;
  const AppInitModelFailed(this.reason);
}
```

Transisi state dikelola oleh `AppInitNotifier`:

```dart
// lib/core/ai/app_init_notifier.dart

final appInitProvider =
    StateNotifierProvider<AppInitNotifier, AppInitState>(
  (ref) => AppInitNotifier(ref),
);

class AppInitNotifier extends StateNotifier<AppInitState> {
  AppInitNotifier(this._ref) : super(const AppInitModelLoading());

  final Ref _ref;

  Future<void> initialize() async {
    // Step 1: Apakah model sudah ada dan valid?
    final modelReady = await ModelStorage.isModelReady();
    if (!modelReady) {
      state = const AppInitModelDownloading();
      // Tunggu download selesai — watch downloadProvider
      _ref.listen(modelDownloadProvider, (_, next) {
        if (next is DownloadComplete) _loadModel();
        if (next is DownloadFailed) {
          state = AppInitModelFailed((next).reason);
        }
      });
      await _ref.read(modelDownloadProvider.notifier).startDownload();
      return;
    }

    // Step 2: Load model ke memori
    await _loadModel();
  }

  Future<void> _loadModel() async {
    state = const AppInitModelLoading();
    try {
      await GemmaIsolateService.initialize(
        modelPath: await ModelStorage.modelPath,
      );
      state = const AppInitModelReady();
    } catch (e) {
      state = AppInitModelFailed('Model gagal dimuat: $e');
    }
  }
}
```

#### 16.2.2 Degraded Mode saat MODEL_LOADING

Selama state `AppInitModelLoading`, app **tidak menampilkan layar kosong** — dashboard tetap bisa diakses dengan batasan:

| Fitur | Status di Degraded Mode |
|---|---|
| Input manual (form) | ✅ Aktif penuh |
| Lihat transaksi & laporan | ✅ Aktif penuh |
| SQLite read/write | ✅ Aktif penuh |
| FAB sub-tombol Suara 🎤 | ❌ Disabled, tooltip: "AI sedang memuat..." |
| FAB sub-tombol Foto 📷 | ❌ Disabled, tooltip: "AI sedang memuat..." |
| Banner loading | ✅ Tampil di atas dashboard |

```dart
// lib/features/dashboard/presentation/widgets/ai_loading_banner.dart

class AiLoadingBanner extends ConsumerWidget {
  const AiLoadingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitProvider);

    // Hanya tampil saat MODEL_LOADING
    if (initState is! AppInitModelLoading) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFF3CD), // kuning muda
      child: Row(
        children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBA7517)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'AI sedang memuat — fitur suara & foto akan aktif sebentar lagi',
              style: TextStyle(fontSize: 13, color: Color(0xFFBA7517)),
            ),
          ),
        ],
      ),
    );
  }
}
```

```dart
// lib/features/dashboard/presentation/widgets/ai_aware_fab.dart
// FAB yang sadar terhadap status AI

class AiAwareFab extends ConsumerWidget {
  const AiAwareFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitProvider);
    final aiReady = initState is AppInitModelReady;

    return SpeedDial( // atau custom FAB expansion
      children: [
        SpeedDialChild(
          child: const Icon(Icons.mic),
          label: 'Suara',
          onTap: aiReady ? () => _openVoiceInput(context) : null,
          backgroundColor: aiReady ? const Color(0xFF1976D2) : Colors.grey,
          tooltip: aiReady ? null : 'AI sedang memuat...',
        ),
        SpeedDialChild(
          child: const Icon(Icons.camera_alt),
          label: 'Foto',
          onTap: aiReady ? () => _openCameraInput(context) : null,
          backgroundColor: aiReady ? const Color(0xFF1976D2) : Colors.grey,
          tooltip: aiReady ? null : 'AI sedang memuat...',
        ),
        SpeedDialChild(
          child: const Icon(Icons.edit),
          label: 'Manual',
          onTap: () => _openManualInput(context), // selalu aktif
          backgroundColor: const Color(0xFF1976D2),
        ),
      ],
    );
  }

  void _openVoiceInput(BuildContext context) { /* ... */ }
  void _openCameraInput(BuildContext context) { /* ... */ }
  void _openManualInput(BuildContext context) { /* ... */ }
}
```

#### 16.2.3 State Machine Diagram (Teks)

```
APP_LAUNCH
    │
    ▼
[cek ModelStorage.isModelReady()]
    │
    ├─ false ──► MODEL_DOWNLOADING
    │                │
    │                ├─ DownloadComplete ──► MODEL_LOADING
    │                └─ DownloadFailed  ──► MODEL_FAILED (permanent manual mode)
    │
    └─ true ──► MODEL_LOADING
                    │
                    ├─ load sukses ──► MODEL_READY (AI fully operational)
                    └─ load gagal ──► MODEL_FAILED (permanent manual mode)
```

---

### 16.3 Gemma 4 E2B Capability Clarification

#### 16.3.1 Context Window

Gemma 4 E2B (2 billion parameter, instruction-tuned, quantized Q4_K_M via LiteRT) memiliki context window **8.192 token** berdasarkan spesifikasi arsitektur Gemma 4 yang dipublikasikan Google. Untuk keamanan (menghindari truncation), WarungPintar membatasi total prompt context (system prompt + user input + stock context) di **6.000 token**, menyisakan 2.192 token untuk output.

```dart
// lib/core/ai/prompt_budget.dart
class PromptBudget {
  static const int contextWindowTokens    = 8192;
  static const int maxPromptTokens        = 6000; // ~73% dari context window
  static const int maxOutputTokens        = 512;  // cukup untuk JSON multi-item
  static const int safetyMarginTokens     = 1680; // buffer tersisa
}
```

#### 16.3.2 Mengapa 512 Token Output Cukup untuk JSON Multi-Item

Estimasi token per item transaksi dalam output JSON:

```
{
  "name": "record_transactions",                    →  ~8 token
  "arguments": {                                    →  ~3 token
    "transactions": [                               →  ~4 token
      {                                             →  ~2 token
        "item_name": "Beras Premium 5kg",           → ~10 token
        "quantity": 3,                              →  ~5 token
        "total_price_sen": 4500000,                 →  ~7 token
        "transaction_type": "sell",                 →  ~8 token
        "needs_clarification": false                →  ~6 token
      }                                             →  ~2 token
    ]                                               →  ~2 token
  }                                                 →  ~2 token
}                                                   →  ~2 token
```

**Estimasi per item: ~30 token.**
Dengan batas 512 token output: `512 / 30 ≈ 17 item per satu ucapan`.
Dalam realita penggunaan Ibu miski, satu ucapan paling banyak 10–12 item — **512 token lebih dari cukup**.

#### 16.3.3 Konfirmasi Multimodal Vision Support

`flutter_gemma ^0.2.0` dengan backend LiteRT mendukung multimodal input (teks + gambar) untuk model yang dicompile dengan vision encoder aktif. Gemma 4 E2B `litertlm` varian instruction-tuned menyertakan vision encoder berdasarkan dokumentasi LiteRT-LM Google.

**Implementasi verifikasi di runtime:**

```dart
// lib/core/ai/gemma_capability_check.dart
class GemmaCapabilityCheck {
  /// Kirim inference test dengan gambar dummy 1x1 pixel saat cold start.
  /// Jika sukses → vision aktif. Jika error → log warning, disable vision FAB.
  static Future<bool> checkVisionSupport(GemmaModel gemma) async {
    try {
      const dummyBase64 = '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJ'
          'CQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgy'
          'PC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIy'
          'MjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAFgAB'
          'AQEAAAAAAAAAAAAAAAAABgUEB//EAB4QAAICAgMBAAAAAAAAAAAAAAECAxEEEiEx/8QA'
          'FABAQAAAAAAAAAAAAAAAAAAAAP/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIR'
          'AxEAPwCwABr2H5QAH//Z'; // JPEG 1x1 pixel base64
      final result = await gemma.generate(
        prompt: 'Describe this image in one word.',
        imageBase64: dummyBase64,
        maxTokens: 10,
      );
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
```

#### 16.3.4 Batasan: Tidak Ada Token Streaming

`flutter_gemma ^0.2.0` **tidak mendukung streaming token per token** — output dikembalikan sebagai satu string setelah inference selesai. Ini berarti:

- Tidak ada typing animation saat inference berlangsung
- UI menampilkan `CircularProgressIndicator` selama inference
- Untuk voice inference ~5–8 detik, ini acceptable untuk target user Ibu miski
- Streaming akan dipertimbangkan jika `flutter_gemma ^0.3.0` tersedia sebelum submission

---

### 16.4 STT Offline Verification

#### 16.4.1 Engine yang Digunakan

`speech_to_text ^7.0.0` pada Android menggunakan **Android `SpeechRecognizer` API** bawaan sistem, yang memanfaatikan on-device speech recognition engine. Ini berarti:

- Tidak ada network call selama STT berlangsung
- Bahasa pack harus terinstall di device (tidak otomatis)
- Kualitas recognition bergantung pada Android version dan OEM customization

**Verifikasi offline behavior di runtime:**

```dart
// lib/core/voice/voice_service_impl.dart
import 'package:speech_to_text/speech_to_text.dart';

class VoiceServiceImpl implements VoiceService {
  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;

  @override
  Future<VoiceInitResult> initialize() async {
    _isInitialized = await _stt.initialize(
      onStatus: _onStatus,
      onError: _onError,
      // debugLogging: false di production
    );

    if (!_isInitialized) {
      return VoiceInitResult.failed('STT engine tidak tersedia di device ini');
    }

    // Cek ketersediaan bahasa id-ID
    final locales = await _stt.locales();
    final hasIndonesian = locales.any(
      (locale) => locale.localeId.startsWith('id'),
    );

    if (!hasIndonesian) {
      return VoiceInitResult.missingLanguagePack();
    }

    return VoiceInitResult.success();
  }
}

// Result type untuk inisialisasi STT
sealed class VoiceInitResult {
  const VoiceInitResult();
  factory VoiceInitResult.success()             => const VoiceInitSuccess();
  factory VoiceInitResult.failed(String reason) => VoiceInitFailed(reason);
  factory VoiceInitResult.missingLanguagePack() => const VoiceInitMissingPack();
}
final class VoiceInitSuccess     extends VoiceInitResult { const VoiceInitSuccess(); }
final class VoiceInitFailed      extends VoiceInitResult {
  final String reason;
  const VoiceInitFailed(this.reason);
}
final class VoiceInitMissingPack extends VoiceInitResult { const VoiceInitMissingPack(); }
```

#### 16.4.2 Dialog Language Pack Missing

Jika `id-ID` language pack tidak terdeteksi, tampilkan dialog dengan deep link ke Android Language Settings:

```dart
// lib/core/voice/language_pack_dialog.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LanguagePackDialog extends StatelessWidget {
  const LanguagePackDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bahasa Belum Terpasang'),
      content: const Text(
        'Fitur suara membutuhkan paket bahasa Indonesia (id-ID) '
        'yang terpasang di Android. Silakan pasang melalui Pengaturan '
        'Bahasa, lalu restart aplikasi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Nanti'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Deep link ke Android Language & Input settings
            final uri = Uri.parse('android-app://com.android.settings/.LanguageSettings');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              // Fallback: buka Settings umum
              await launchUrl(Uri.parse('package:com.android.settings'));
            }
          },
          child: const Text('Buka Pengaturan'),
        ),
      ],
    );
  }

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Harus explicitly dismiss
      builder: (_) => const LanguagePackDialog(),
    );
  }
}
```

#### 16.4.3 VAD (Voice Activity Detection) Threshold

`speech_to_text` menggunakan VAD bawaan Android. Konfigurasi WarungPintar:

```dart
// lib/core/voice/voice_config.dart
class VoiceConfig {
  /// Berapa milidetik diam setelah ada suara sebelum STT dianggap selesai.
  /// Nilai 2000ms dipilih untuk memberi ruang jeda alami Ibu miski
  /// saat menyebut daftar item panjang (mis. jeda pikir antar item).
  static const int vadSilenceThresholdMs = 2000;

  /// Bahasa target STT
  static const String localeId = 'id-ID';

  /// Durasi maksimum satu sesi listening (30 detik)
  /// Jika user masih bicara setelah ini, auto-submit dan proses
  static const int maxListenDurationMs = 30000;

  /// Minimum confidence score untuk menerima hasil STT (0.0–1.0)
  /// Di bawah nilai ini → minta user ulangi
  static const double minConfidenceScore = 0.5;
}
```

```dart
// Penggunaan di VoiceServiceImpl
Future<void> startListening({required Function(String) onResult}) async {
  await _stt.listen(
    localeId: VoiceConfig.localeId,
    listenFor: const Duration(milliseconds: VoiceConfig.maxListenDurationMs),
    pauseFor: const Duration(milliseconds: VoiceConfig.vadSilenceThresholdMs),
    onResult: (result) {
      if (result.finalResult && result.confidence >= VoiceConfig.minConfidenceScore) {
        onResult(result.recognizedWords);
      }
    },
  );
}
```

#### 16.4.4 Known Limitation: Noise Pre-Processing

Tidak ada audio pre-processing tambahan (noise gate, bandpass filter, normalization) pada versi ini. STT mengandalkan sepenuhnya engine Android. Pada kondisi warung ramai dengan noise tinggi, recognition accuracy mungkin menurun. Ini adalah **known limitation** yang tercatat dan tidak diselesaikan dalam scope hackathon.

---

### 16.5 Inference Timeout & Retry Logic

#### 16.5.1 Nilai Timeout Konkret

| Jenis Inference | Timeout | Alasan |
|---|---|---|
| Voice inference (teks saja) | **30 detik** | Prompt lebih ringan, tanpa gambar |
| Vision inference (teks + gambar) | **45 detik** | Vision encoder lebih berat, terutama di device ≤ 4GB RAM |

#### 16.5.2 Retry Strategy

- **Maksimal 2x retry** setelah failure pertama
- **Exponential backoff:** retry pertama setelah 1 detik, retry kedua setelah 3 detik
- Setelah 2x retry gagal → error snackbar + fallback ke input manual
- Retry hanya dilakukan untuk `InferenceTimeoutFailure` dan `ModelNotLoadedFailure`
- **Tidak** retry untuk `InvalidJsonOutputFailure` pada level ini — ditangani oleh Fallback Level 1 (Section 16.6)

#### 16.5.3 Implementasi Dart Retry Wrapper

```dart
// lib/core/ai/inference_retry.dart

/// Wrapper retry dengan exponential backoff untuk AiService.infer().
/// Digunakan oleh semua agent — bukan di dalam AiService itu sendiri,
/// melainkan di use case layer agar testable secara terpisah.

class InferenceRetry {
  static const int _maxRetries        = 2;
  static const int _firstBackoffMs    = 1000;  // 1 detik
  static const int _secondBackoffMs   = 3000;  // 3 detik

  static const int _voiceTimeoutSec   = 30;
  static const int _visionTimeoutSec  = 45;

  /// [isVision]: true jika ada imageBase64 (pakai timeout lebih panjang)
  static Future<Result<ToolCallResult, AiFailure>> runWithRetry({
    required AiService aiService,
    required String systemPrompt,
    required String userInput,
    String? imageBase64,
  }) async {
    final timeoutDuration = Duration(
      seconds: imageBase64 != null ? _visionTimeoutSec : _voiceTimeoutSec,
    );

    int attempt = 0;
    AiFailure? lastFailure;

    while (attempt <= _maxRetries) {
      try {
        final result = await aiService.infer(
          systemPrompt: systemPrompt,
          userInput: userInput,
          imageBase64: imageBase64,
        ).timeout(
          timeoutDuration,
          onTimeout: () => const Error(InferenceTimeoutFailure()),
        );

        // Jika sukses, langsung return — tidak perlu retry
        if (result is Success) return result;

        // Jika failure yang tidak perlu di-retry, langsung return error
        final failure = (result as Error<ToolCallResult, AiFailure>).failure;
        if (failure is InvalidJsonOutputFailure) {
          // JSON malformed → tangani di Fallback Level 1 (Section 16.6)
          return result;
        }

        lastFailure = failure;
      } catch (e) {
        lastFailure = ModelNotLoadedFailure();
      }

      // Backoff sebelum retry
      if (attempt < _maxRetries) {
        final backoffMs = attempt == 0 ? _firstBackoffMs : _secondBackoffMs;
        await Future.delayed(Duration(milliseconds: backoffMs));
      }

      attempt++;
    }

    // Semua retry habis
    return Error(lastFailure ?? const ModelNotLoadedFailure());
  }
}
```

**Penggunaan di use case:**

```dart
// lib/features/transaction/domain/usecases/record_voice_transaction_usecase.dart

class RecordVoiceTransactionUseCase {
  final AiService _aiService;

  const RecordVoiceTransactionUseCase(this._aiService);

  Future<Result<List<TransactionModel>, AiFailure>> call(String sttTranscript) async {
    final result = await InferenceRetry.runWithRetry(
      aiService: _aiService,
      systemPrompt: AgentPrompts.voiceTransaction,
      userInput: sttTranscript,
      imageBase64: null,
    );

    return switch (result) {
      Success(data: final toolCall) => _parseTransactions(toolCall),
      Error(failure: final f)       => Error(f),
    };
  }

  Result<List<TransactionModel>, AiFailure> _parseTransactions(ToolCallResult toolCall) {
    // ... parsing logic
    return Success([]);
  }
}
```

---

### 16.6 Fallback Hierarchy

Tiga level fallback didefinisikan secara bertingkat. Level 1 ditangani dulu, jika gagal baru ke Level 2, dan seterusnya.

#### 16.6.1 Level 1 — JSON Malformed Output

**Trigger:** `InvalidJsonOutputFailure` — model output bukan JSON valid (ada markdown fence, trailing text, atau JSON tidak lengkap).

**Aksi:**
1. Panggil `_stripJsonFences()` pada raw output (sudah ada di Section 10.5)
2. Coba parse ulang hasil cleaned output
3. Jika berhasil → lanjut normal
4. Jika tetap gagal → retry inference 1x dengan prompt tambahan yang lebih eksplisit

```dart
// lib/core/ai/fallback/level1_json_repair.dart

class Level1JsonRepair {
  static Future<Result<ToolCallResult, AiFailure>> attempt({
    required AiService aiService,
    required String systemPrompt,
    required String userInput,
    required String rawMalformedOutput,
    String? imageBase64,
  }) async {
    // Coba strip fence dulu
    try {
      final cleaned = _stripJsonFences(rawMalformedOutput);
      final parsed  = parseToolCall(cleaned);
      return Success(parsed);
    } catch (_) {
      // Strip tidak cukup — retry inference dengan instruksi lebih ketat
    }

    // Retry inference dengan reinforcement prompt
    const jsonRepairSuffix =
        '\n\nPENTING: Output HARUS berupa JSON murni tanpa teks lain, '
        'tanpa markdown code fence, tanpa penjelasan. '
        'Mulai langsung dengan karakter { dan akhiri dengan }.';

    final retryResult = await aiService.infer(
      systemPrompt: systemPrompt + jsonRepairSuffix,
      userInput: userInput,
      imageBase64: imageBase64,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => const Error(InferenceTimeoutFailure()),
    );

    return retryResult;
  }

  static String _stripJsonFences(String raw) {
    var clean = raw.replaceAll(RegExp(r'```json\s*'), '');
    clean = clean.replaceAll(RegExp(r'```\s*'), '');
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
    if (jsonMatch == null) throw const FormatException('No JSON found after strip');
    jsonDecode(jsonMatch.group(0)!); // validate
    return jsonMatch.group(0)!;
  }
}
```

#### 16.6.2 Level 2 — Inference Gagal 2x (AI Input Disabled)

**Trigger:** Semua retry (Section 16.5) dan Level 1 repair gagal.

**Aksi:**
- Disable FAB Suara dan Foto (sama seperti Degraded Mode di Section 16.2)
- Tampilkan banner warning merah di atas dashboard
- Input manual tetap aktif penuh
- State ini bersifat **session-scoped** — jika user restart app dan model berhasil load, kembali normal

```dart
// lib/core/ai/app_init_state.dart — tambahan state
final class AppInitAiDegraded extends AppInitState {
  final String reason;
  const AppInitAiDegraded(this.reason);
}
```

```dart
// lib/features/dashboard/presentation/widgets/ai_degraded_banner.dart

class AiDegradedBanner extends ConsumerWidget {
  const AiDegradedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitProvider);
    if (initState is! AppInitAiDegraded) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFEDED),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI sedang bermasalah — gunakan input manual',
              style: TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
            ),
          ),
          TextButton(
            onPressed: () {
              // User bisa coba reload model
              ref.read(appInitProvider.notifier).initialize();
            },
            child: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
```

**Penanganan di use case setelah failure Level 2:**

```dart
// Di presenter/controller setelah InferenceRetry.runWithRetry() return Error
switch (failure) {
  case ModelNotLoadedFailure() || InferenceTimeoutFailure():
    // Trigger Level 2
    ref.read(appInitProvider.notifier).markAsDegraded(failure.message);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI tidak merespons — silakan gunakan input manual'),
        duration: Duration(seconds: 5),
        backgroundColor: Color(0xFFDC2626),
      ),
    );
    // Buka form manual secara otomatis
    context.push('/manual-input');

  case InvalidJsonOutputFailure():
    // Sudah ditangani Level 1 — jika sampai sini berarti Level 1 juga gagal
    ref.read(appInitProvider.notifier).markAsDegraded(failure.message);
    // ...sama seperti di atas
}
```

#### 16.6.3 Level 3 — Model Tidak Bisa Load Sama Sekali (Permanent Manual Mode)

**Trigger:** `AppInitModelFailed` — model tidak bisa di-load (RAM tidak cukup, file korup, LiteRT crash).

**Aksi:**
- App berjalan sepenuhnya dalam **Manual Mode**
- Semua data tetap tersimpan normal ke SQLite
- Banner permanen berwarna abu gelap di atas semua halaman
- FAB Suara dan Foto dihapus dari tampilan (bukan hanya disabled)
- User tetap bisa akses semua fitur manual: input transaksi, lihat laporan, kelola katalog

```dart
// lib/features/dashboard/presentation/widgets/permanent_manual_mode_banner.dart

class PermanentManualModeBanner extends ConsumerWidget {
  const PermanentManualModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitProvider);
    if (initState is! AppInitModelFailed) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF424242),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white70, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode Manual Aktif — fitur AI tidak tersedia',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Semua data tetap aman:**

```dart
// Data integrity tidak bergantung pada AI — SQLite berjalan independen
// Semua transaksi manual tetap masuk dengan input_method = 'manual'
// Status pending/confirmed tetap berjalan normal
// Laporan, export PDF/CSV tetap berfungsi
// Audit log tetap mencatat dengan action = 'CREATED_MANUAL'
```

---

### 16.7 Vision Input Quality Gate

Validasi kualitas gambar dilakukan **sebelum** memanggil inference — mencegah waste waktu 45 detik untuk gambar yang sudah pasti tidak bisa dibaca.

#### 16.7.1 Tiga Kriteria Validasi

| Kriteria | Nilai Minimum | Alasan |
|---|---|---|
| Ukuran file | ≥ 10.240 bytes (10 KB) | Di bawah ini kemungkinan besar blank/corrupt |
| Resolusi | ≥ 400 × 400 px | Terlalu kecil untuk OCR teks struk |
| Brightness rata-rata | ≥ 40 (skala 0–255) | Di bawah ini gambar terlalu gelap |

#### 16.7.2 Implementasi Quality Gate

```dart
// lib/core/vision/image_quality_gate.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Hasil validasi kualitas gambar sebelum dikirim ke inference
sealed class ImageQualityResult {
  const ImageQualityResult();
}
final class ImageQualityPass   extends ImageQualityResult { const ImageQualityPass(); }
final class ImageQualityFail   extends ImageQualityResult {
  final ImageQualityFailReason reason;
  const ImageQualityFail(this.reason);
}

enum ImageQualityFailReason {
  fileTooSmall,   // < 10 KB
  resolutionTooLow, // < 400x400
  tooDark,        // brightness < 40
}

class ImageQualityGate {
  static const int _minFileSizeBytes = 10240;       // 10 KB
  static const int _minWidth         = 400;
  static const int _minHeight        = 400;
  static const double _minBrightness = 40.0;        // 0–255 scale

  /// Validasi gambar sebelum inference.
  /// Proses sampling pixel dilakukan pada versi thumbnail untuk efisiensi.
  static Future<ImageQualityResult> validate(File imageFile) async {
    // 1. Cek ukuran file
    final fileSize = await imageFile.length();
    if (fileSize < _minFileSizeBytes) {
      return const ImageQualityFail(ImageQualityFailReason.fileTooSmall);
    }

    // 2. Decode gambar untuk cek resolusi dan brightness
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ImageQualityFail(ImageQualityFailReason.fileTooSmall);
    }

    // 3. Cek resolusi minimum
    if (decoded.width < _minWidth || decoded.height < _minHeight) {
      return const ImageQualityFail(ImageQualityFailReason.resolutionTooLow);
    }

    // 4. Brightness check via pixel sampling (ambil 100 pixel acak, hitung rata-rata)
    final brightness = _sampleBrightness(decoded);
    if (brightness < _minBrightness) {
      return const ImageQualityFail(ImageQualityFailReason.tooDark);
    }

    return const ImageQualityPass();
  }

  /// Ambil rata-rata brightness dari 100 pixel tersebar merata di gambar
  static double _sampleBrightness(img.Image image) {
    const sampleCount = 100;
    double totalLuminance = 0;
    final stepX = image.width  ~/ 10;
    final stepY = image.height ~/ 10;

    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 10; col++) {
        final x = col * stepX + stepX ~/ 2;
        final y = row * stepY + stepY ~/ 2;
        final pixel = image.getPixel(x, y);
        // Luminance perceptual (ITU-R BT.709)
        final luminance =
            0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b;
        totalLuminance += luminance;
      }
    }

    return totalLuminance / sampleCount;
  }
}
```

#### 16.7.3 Dialog Feedback ke User

```dart
// lib/core/vision/image_quality_dialog.dart

class ImageQualityFailDialog extends StatelessWidget {
  final ImageQualityFailReason reason;
  const ImageQualityFailDialog({super.key, required this.reason});

  String get _message => switch (reason) {
    ImageQualityFailReason.fileTooSmall =>
        'Foto tidak terbaca — mungkin terlalu buram atau tidak tertangkap kamera. '
        'Coba ambil foto lagi.',
    ImageQualityFailReason.resolutionTooLow =>
        'Foto terlalu kecil. Pastikan struk atau kemasan mengisi sebagian besar layar kamera.',
    ImageQualityFailReason.tooDark =>
        'Foto terlalu gelap. Coba lagi dengan cahaya lebih baik — dekat jendela '
        'atau nyalakan lampu.',
  };

  String get _title => switch (reason) {
    ImageQualityFailReason.fileTooSmall   => 'Foto Tidak Terdeteksi',
    ImageQualityFailReason.resolutionTooLow => 'Foto Terlalu Kecil',
    ImageQualityFailReason.tooDark         => 'Foto Terlalu Gelap',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.camera_alt_outlined, color: Color(0xFFBA7517)),
          const SizedBox(width: 8),
          Text(_title),
        ],
      ),
      content: Text(_message, style: const TextStyle(fontSize: 15)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true), // true = coba lagi
          child: const Text('Foto Ulang'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // false = batal
          child: const Text('Batal'),
        ),
      ],
    );
  }

  /// Return true jika user pilih "Foto Ulang", false jika "Batal"
  static Future<bool> show(BuildContext context, ImageQualityFailReason reason) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImageQualityFailDialog(reason: reason),
    );
    return result ?? false;
  }
}
```

#### 16.7.4 Integrasi Quality Gate ke Vision Flow

```dart
// lib/features/vision/domain/usecases/parse_receipt_usecase.dart

class ParseReceiptUseCase {
  final AiService _aiService;
  const ParseReceiptUseCase(this._aiService);

  Future<Result<List<TransactionModel>, AiFailure>> call({
    required File imageFile,
    required BuildContext context, // untuk show dialog
  }) async {
    // STEP 1: Quality Gate — sebelum inference dipanggil
    final qualityResult = await ImageQualityGate.validate(imageFile);
    if (qualityResult is ImageQualityFail) {
      // Tampilkan dialog, tawarkan foto ulang
      final retry = await ImageQualityFailDialog.show(context, qualityResult.reason);
      if (retry) {
        return const Error(ImageUnreadableFailure()); // caller akan open camera lagi
      }
      return const Error(ImageUnreadableFailure());
    }

    // STEP 2: Compress & encode
    final compressed = await FlutterImageCompress.compressWithFile(
      imageFile.path, minWidth: 800, quality: 70,
    );
    if (compressed == null || compressed.isEmpty) {
      return const Error(ImageUnreadableFailure());
    }
    final base64Image = base64Encode(compressed);

    // STEP 3: Inference dengan retry
    final inferResult = await InferenceRetry.runWithRetry(
      aiService: _aiService,
      systemPrompt: AgentPrompts.visionReceipt,
      userInput: '',
      imageBase64: base64Image,
    );

    // STEP 4: Fallback Level 1 jika JSON malformed
    if (inferResult is Error) {
      final failure = (inferResult as Error<ToolCallResult, AiFailure>).failure;
      if (failure is InvalidJsonOutputFailure) {
        final repaired = await Level1JsonRepair.attempt(
          aiService: _aiService,
          systemPrompt: AgentPrompts.visionReceipt,
          userInput: '',
          rawMalformedOutput: failure.rawOutput,
          imageBase64: base64Image,
        );
        return _mapToTransactions(repaired);
      }
      return Error(failure);
    }

    return _mapToTransactions(inferResult);
  }

  Result<List<TransactionModel>, AiFailure> _mapToTransactions(
    Result<ToolCallResult, AiFailure> result,
  ) {
    return switch (result) {
      Success(data: final toolCall) => Success(_parseTransactions(toolCall)),
      Error(failure: final f)       => Error(f),
    };
  }

  List<TransactionModel> _parseTransactions(ToolCallResult toolCall) {
    // ... parsing logic sesuai schema record_transactions
    return [];
  }
}
```

---

### 16.8 Integrasi Section 16 ke Dependency Injection

Semua service baru dari Section 16 didaftarkan di `lib/core/di/injection.dart`:

```dart
Future<void> setupDependencies() async {
  // === Existing (Section 5.2) ===
  getIt.registerLazySingleton<DatabaseService>(() => DatabaseServiceImpl());
  getIt.registerLazySingleton<AiService>(() => GemmaAiService());
  getIt.registerLazySingleton<VoiceService>(() => VoiceServiceImpl());
  getIt.registerFactory<TransactionRepository>(
    () => TransactionRepositoryImpl(getIt()),
  );

  // === Section 16 Additions ===

  // Model download — singleton karena ada state download aktif
  getIt.registerLazySingleton<ModelDownloadNotifier>(
    () => ModelDownloadNotifier(),
  );

  // Image quality gate — stateless, bisa factory
  getIt.registerFactory<ImageQualityGate>(() => ImageQualityGate());

  // Use cases dengan retry + fallback built-in
  getIt.registerFactory<ParseReceiptUseCase>(
    () => ParseReceiptUseCase(getIt<AiService>()),
  );
  getIt.registerFactory<RecordVoiceTransactionUseCase>(
    () => RecordVoiceTransactionUseCase(getIt<AiService>()),
  );
}
```

---

### 16.9 Checklist Teknis Section 16

Tambahan ke Appendix D — semua item di bawah ini harus hijau sebelum submission:

```
SECTION 16 — AI RUNTIME TECHNICAL SPECIFICATION

MODEL DELIVERY
[ ] File model TIDAK di-bundle ke APK
[ ] Download on first launch dengan Dio + resume support (Range header)
[ ] Progress bar linear + persentase + estimasi waktu tampil selama download
[ ] SHA-256 verification setelah download selesai
[ ] Fallback URL ke GitHub Releases jika Kaggle tidak accessible
[ ] ModelStorage.modelPath menggunakan getApplicationDocumentsDirectory

COLD START UX
[ ] AppInitState sealed class: ModelDownloading, ModelLoading, ModelReady, ModelFailed, AiDegraded
[ ] Degraded Mode: FAB Suara + Foto disabled dengan tooltip "AI sedang memuat..."
[ ] Banner kuning tampil selama MODEL_LOADING
[ ] Input manual tetap bisa dipakai selama model loading
[ ] Banner merah tampil saat Level 2 fallback aktif
[ ] Banner abu tampil saat Level 3 (permanent manual mode)

GEMMA 4 CAPABILITY
[ ] Context window limit 6000 token dari maximum 8192
[ ] maxOutputTokens = 512 di semua inference call
[ ] Vision support check (1x1 pixel test) saat cold start
[ ] Tidak ada streaming token — CircularProgressIndicator selama inference

STT OFFLINE
[ ] speech_to_text menggunakan Android SpeechRecognizer API (on-device)
[ ] Cek ketersediaan id-ID locale saat app startup
[ ] Dialog + deep link ke Android Language Settings jika id-ID tidak ada
[ ] VAD silence threshold = 2000ms (pauseFor: Duration(milliseconds: 2000))
[ ] Min confidence score = 0.5 sebelum transcript diteruskan ke inference

TIMEOUT & RETRY
[ ] Voice inference timeout = 30 detik
[ ] Vision inference timeout = 45 detik
[ ] Maksimal 2x retry dengan backoff 1s, 3s
[ ] InferenceRetry.runWithRetry() dipakai di semua agent use case

FALLBACK HIERARCHY
[ ] Level 1: _stripJsonFences() + retry inference 1x dengan reinforcement prompt
[ ] Level 2: AppInitAiDegraded, disable AI FAB, banner merah, buka form manual
[ ] Level 3: AppInitModelFailed, permanent manual mode, banner abu, semua data aman

VISION QUALITY GATE
[ ] Validasi file size ≥ 10 KB sebelum inference
[ ] Validasi resolusi ≥ 400×400 px sebelum inference
[ ] Brightness sampling 100 pixel, rata-rata ≥ 40/255 sebelum inference
[ ] Dialog "Foto Ulang" dengan pesan spesifik per failure reason
[ ] Quality gate dijalankan SEBELUM compression dan encoding base64
```

---

## Bootstrap Sequence Anti-Deadlock
- Setiap layanan AI (STT, Model, Vision) diinisialisasi secara berurutan dengan timeout ketat
- Jika satu layanan gagal, layanan tersebut ditandai sebagai `degraded`, bukan menyebabkan crash aplikasi
- Timeout per langkah: 30 detik. Jika timeout, lewati dan lanjut ke langkah berikutnya untuk layanan non-critical
- Seluruh proses bootstrap tidak memblokir UI utama; tampilkan progress bar linear dengan estimasi waktu
- State machine per layanan: `notStarted → inProgress → success/failed`
- Critical services (Model AI, Database) yang gagal akan mengaktifkan `Permanent Manual Mode`

## Prinsip Prompt per Agent
Setiap system prompt mengikuti struktur empat lapis yang konsisten:
```
[KONTEKS SISTEM]   ← Role dan batasan global agen, diulang setiap sesi
[KONTEKS DATA]     ← Data aktual dari SQLite (stock_context, max 20 item terbaru)
[INSTRUKSI KETAT]  ← Aturan output: format JSON, larangan menebak, fallback clarify
[PERINTAH USER]    ← Transkrip suara atau deskripsi gambar dari input pengguna
```
Aturan wajib:
- Spesifik: Setiap prompt hanya berisi instruksi untuk satu tugas tunggal
- Batasan Output: Wajib menyebutkan "Output HANYA JSON valid sesuai skema {tool_name}"
- Panduan Keamanan: "Jangan pernah menebak harga jika tidak ada di konteks" dan "Jangan menghasilkan data fiktif"
- Fallback: "Jika informasi kurang, output: {\"name\": \"clarify\", \"arguments\": {\"question\": \"...\"}}"
- Vision: "Jika gambar tidak terbaca, output: {\"error\": \"image_unreadable\"}"

## Logging Performa Agent
Setiap kali Agent menyelesaikan inferensi, catat metrik berikut di `audit_logs.state_snapshot`:
```json
{
  "agent_name": "voice_transaction",
  "inference_time_ms": 2847,
  "time_to_first_token_ms": 412,
  "total_tokens": 189,
  "tokens_per_second": 12.4,
  "model_name": "gemma-4-e2b-it-litertlm-Q4_K_M",
  "device_ram_gb": 3.8,
  "timestamp": "2026-05-17T08:23:41Z"
}
```
Metrik ini ditampilkan di drawer audit log sebagai bukti performa on-device dan bahan benchmarking optimasi.


**END OF PRODUCT REQUIREMENTS DOCUMENT v10.0.0**