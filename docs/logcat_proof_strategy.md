# WarungPintar Cimahi — Logcat Proof Strategy

This document outlines the strategy for capturing verifiable proof that the WarungPintar Cimahi app operates in a strictly "Zero-Network / Offline-First" environment after the initial model download, fulfilling PRD §16.9 and Appendix D requirements for the Kaggle hackathon.

## 1. Objective

Prove to the judges that **zero outbound network requests** occur during inference (Voice STT, Vision, and Text LLM generation).

## 2. Tools Required

- Android device or emulator (Android 10+)
- `adb` (Android Debug Bridge)
- Screen recording software (e.g., OBS or `scrcpy`)
- Android Studio Network Profiler (optional but highly recommended)

## 3. Execution Steps

### Step 3.1: Enable Airplane Mode
1. Install the obfuscated release APK (`scripts/build_release.sh`).
2. Ensure the Gemma 4 E2B `.bin` model is already downloaded to the device.
3. Turn **ON** Airplane mode on the device.

### Step 3.2: Configure `adb logcat` Filtering
We will use a dual-pane terminal or screen setup. 

**Terminal 1 (Monitoring Network Libraries):**
We want to prove that popular networking libraries (`HttpClient`, `OkHttp`, `Dio`) are completely silent.
```bash
adb logcat | grep -iE "HttpClient|OkHttp|Dio|Network|Volley|Retrofit"
```
*Expected: Empty output after the app launches.*

**Terminal 2 (Monitoring App Logs & Inference):**
We want to capture the inference logs coming directly from the Gemma isolate.
```bash
adb logcat -s flutter WarungPintar
```
*Expected: We should see logs like `[WarungGemmaManager] Starting inference...` and the raw JSON output.*

### Step 3.3: Perform the Test Actions
While the screen is recording (capturing the app screen and the terminals):
1. **Action 1 (Voice):** Tap the Voice button and speak "Indomie goreng dua". 
   - *Observe: STT runs locally. Gemma parses locally. Logcat shows local token generation.*
2. **Action 2 (Vision):** Capture an image using the camera (or mock a photo of a receipt).
   - *Observe: Image is processed. No network spike.*

### Step 3.4: Network Profiler (Alternative/Additional Proof)
1. Attach Android Studio to the running process.
2. Open the "Network" tab in the Profiler.
3. Perform inference actions.
4. Take a screenshot showing a completely flat line (0 Bytes/s) in the Network Profiler timeline while CPU spikes (indicating local inference).

## 4. Expected Deliverables for Submission

1. **Uncut Video (`proof_zero_network.mp4`):**
   - Shows device entering Airplane mode.
   - Shows app performing complex voice/vision tasks.
   - Shows empty `adb logcat` network grep alongside the app.
2. **Screenshot (`proof_profiler.png`):**
   - Flatline network profiler alongside CPU spike during inference.
3. **Log Export (`inference_logs.txt`):**
   - Export of the `adb logcat` demonstrating local parsing execution times (e.g., `Inference completed in 1.2s`).
