# WarungPintar Cimahi - Logcat Proof Strategy

This document outlines the methodology to prove offline-first execution, strict 0-network constraints, and the validity of AI Agent operations during the Hackathon video submission and jury testing.

## 1. Network Constraint Proof
The primary claim of the application is that the LLM runs strictly on-device without any cloud dependencies (post-download).

### 1.1 Airplane Mode Demonstration
- **Video Capture:** Ensure the Android status bar clearly shows the Airplane Mode icon `✈️` across all critical Agent demonstrations.
- **Action:** Execute Voice Transaction, Struk Vision, and Kemasan Vision in this state.

### 1.2 Android Network Profiler
- **Tooling:** Use Android Studio's Network Profiler.
- **Condition:** After the first-launch model download completes (State `AppInitModelReady`).
- **Proof Requirement:** The timeline must show a flat line (0 outbound connections, 0 KB/s transfer) while the user invokes the AI Service repeatedly.
- **Zero HttpClient Evidence:** Search Logcat for `HttpClient` or `Dio`. Ensure zero network exceptions or connection requests during normal operations.

## 2. Audit Log Visibility
The application saves verbatim AI output and transcriptions to the SQLite `audit_logs` table.

### 2.1 Logcat Filtering Strategy
To demonstrate that Gemma 4 is actively calling functions in real-time, we will use a split-screen video recording strategy:
- **Left Screen:** App UI (Dashboard / Inference Process)
- **Right Screen:** Android Studio Logcat

**Logcat Filter:**
```
package:mine tag:WarungPintar/AuditLog
```

### 2.2 Expected Log Output
Whenever an agent finishes executing, the app logger should print the audit log payload:

```json
[WarungPintar/AuditLog] INFO: New Transaction Audit
{
  "action": "CREATED_BY_AI_VOICE",
  "raw_input_source": "Beras tiga kilo empat lima ribu",
  "ai_raw_output": "```json\n{\"name\": \"record_transactions\", \"arguments\": {\"transactions\": [{\"item_name\": \"Beras\", \"quantity\": 3, \"total_price_sen\": 4500000, \"transaction_type\": \"sell\", \"needs_clarification\": false}]}}\n```",
  "inference_time_ms": 2847,
  "tokens_per_second": 12.4
}
```

This acts as undeniable proof that:
1. The AI is actually emitting JSON locally.
2. The LLM function calling is genuine and not hardcoded logic.
3. The prompt budget constraints are observed.
