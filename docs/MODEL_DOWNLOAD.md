# Model Download — Technical Documentation

## Overview

The WarungPintar app uses an on-device Gemma 4 E2B model for AI features (voice transactions, receipt parsing, product identification). This document describes how the model is downloaded, stored, and verified before use.

---

## Architecture

### Key Files

| File | Purpose |
|------|---------|
| `lib/core/ai/model_download_config.dart` | URL, filename, SHA-256 config constants |
| `lib/core/ai/model_download_service.dart` | StateNotifier managing download lifecycle |
| `lib/core/ai/gemma_isolate_service.dart` | Loads and runs Gemma inference in separate isolate |
| `lib/core/ai/app_init_notifier.dart` | Orchestrates download → load → ready flow |
| `lib/core/ai/model_storage.dart` | Helper for reading model bytes (chunked, memory-safe) |
| `lib/features/onboarding/presentation/pages/model_download_screen.dart` | UI for manual download trigger |

---

## Download Configuration

```dart
// model_download_config.dart

// Local filename on disk
static const String modelFileName = 'gemma-4-E2B-it-litert-lm.litertlm';

// SHA-256 hash for verification — empty string skips check
static const String modelSha256 = '';

// Primary download URL (HuggingFace direct resolve)
static const String primaryUrl =
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it-litert-lm.litertlm';

// Fallback URL — empty (disabled)
static const String fallbackUrl = '';

// No mirrors
static const List<String> mirrorUrls = [];

// Expected file size (2.5GB default)
static const int expectedFileSizeBytes = 2684354560; // 2.5 GB

// Chunked download: 4 parallel chunks × 50MB each
static const int chunkSizeBytes = 50 * 1024 * 1024;
static const int parallelChunkCount = 4;
```

---

## Download Flow

```
User triggers download (first launch or manual)
           │
           ▼
┌─────────────────────────────────────────┐
│ ModelDownloadNotifier.startDownload()   │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 1. Check WiFi connectivity             │
│    - WiFi required (prevents mobile)  │
│    - Shows DownloadWaitingWifi state   │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 2. Get local model path               │
│    ${dir.path}/models/gemma-4-E2B-it-litert-lm.litertlm │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 3. Check for existing partial file    │
│    - Resume if file exists + > 0 bytes│
│    - Delete + restart if forceRestart  │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 4. _downloadWithChunks()              │
│    - GET HEAD to get Content-Length   │
│    - Calculate 50MB chunks            │
│    - Download each chunk with Range   │
│      header via Dio                   │
│    - 4 parallel downloads             │
│    - Write directly to same file at  │
│      specific byte offsets            │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 5. _verifyDownload()                  │
│    - If SHA-256 empty → SKIP (return true)│
│    - Otherwise compute SHA-256 in     │
│      isolate and compare             │
│    - Delete file + fail if mismatch  │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 6. DownloadComplete state            │
│    - AppInitNotifier picks this up   │
│    - Triggers GemmaIsolateService    │
│      .initialize(modelPath)          │
└─────────────────────────────────────────┘
```

---

## State Machine

```
ModelDownloadState (sealed class hierarchy):

DownloadIdle(isResumable, alreadyDownloadedBytes)
    │
    ▼ startDownload()
DownloadWaitingWifi
    │ (user connects WiFi)
    ▼ resumeDownload()
DownloadProgress(percent, downloadedBytes, totalBytes,
                 estimatedSecondsRemaining, currentChunk, downloadSpeedMBps)
    │
    ▼ (all chunks complete)
DownloadVerifying(percent) ── SHA-256 in isolate
    │
    ▼ (valid)
DownloadComplete
    │
    ▼ (invalid or error)
DownloadFailed(reason, canRetry, retryAfterSeconds)
    │
    ▼ (user cancels)
DownloadCancelled(savedBytes)
```

---

## Chunked Download Details

The download uses HTTP `Range` headers to download chunks in parallel:

```
File: 2.5GB total, 50MB per chunk → 50 chunks total, 4 parallel

Chunk 0: Range: bytes=0-52428799
Chunk 1: Range: bytes=52428800-104857599
Chunk 2: Range: bytes=104857600-157286399
Chunk 3: Range: bytes=157286400-209715199
... (remaining chunks after these 4 complete)
```

Each chunk writes directly to its byte offset using `File.open(mode: FileMode.write).setPosition()` — no in-memory buffering of full file.

---

## SHA-256 Verification

```dart
Future<bool> _verifySha256InIsolate(String filePath) async {
  // Skip if no hash configured
  final expectedHash = ModelDownloadConfig.modelSha256;
  if (expectedHash.isEmpty) {
    return true; // Trust the download
  }

  // Spawn isolate to compute hash without blocking UI
  final receivePort = ReceivePort();
  await Isolate.spawn(
    _verifySha256IsolateEntry,
    _Sha256VerifyMessage(
      filePath: filePath,
      expectedHash: expectedHash,
      sendPort: receivePort.sendPort,
    ),
  );

  final result = await receivePort.first as _Sha256VerifyResult;
  return result.isValid;
}
```

The isolate reads the file in chunks, computes SHA-256 incrementally, and sends result back. With `modelSha256 = ''`, verification is skipped entirely.

---

## Model Loading (Post-Download)

```dart
// app_init_notifier.dart
Future<void> initialize() async {
  // 1. Check if model file exists
  final modelPath = await modelStorage.getModelPath();

  if (!await File(modelPath).exists()) {
    // Trigger download flow
    ref.read(modelDownloadProvider.notifier).startDownload();
    return;
  }

  // 2. Load into Gemma isolate
  await GemmaIsolateService.initialize(modelPath: modelPath);

  // 3. Set state to AppInitModelReady
  state = const AppInitModelReady();
}
```

```dart
// gemma_isolate_service.dart
static Future<void> initialize({required String modelPath}) async {
  _modelPath = modelPath;
  _isolate = await Isolate.spawn(_gemmaWorker, (sendPort, modelPath));
  _sendPort = await receivePort.first as SendPort;
  _isInitialized = true;
}
```

---

## Graceful Degradation

If model download fails permanently:

```
DioException (all URLs/mirrors exhausted)
        │
        ▼
DownloadFailed(reason: 'Semua mirror gagal...')
        │
        ▼
AppInitNotifier sees DownloadFailed
        │
        ▼
AppInitModelFailed → PermanentManualModeBanner
        │
        ▼
User sees: gray banner "Mode Manual Aktif"
          Voice FAB disabled, Camera FAB disabled
          All features still work via manual forms
```

---

## Offline Behavior

- Model is downloaded ONCE and stored in `getApplicationDocumentsDirectory()/models/`
- Subsequent launches: `File(modelPath).exists()` → skip to `GemmaIsolateService.initialize()`
- Normal app operation (transactions, catalog, reports) works 100% offline after model is loaded
- Zero network calls during normal operation (per AGENT.md rules)

---

## File Location

```
Android: /data/data/com.warungpintar/app_flutter/models/gemma-4-E2B-it-litert-lm.litertlm
iOS:     Application Documents directory/models/gemma-4-E2B-it-litert-lm.litertlm
```
