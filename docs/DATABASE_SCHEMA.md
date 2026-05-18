# WarungPintar — SQLite Database Schema

> **Version:** 2  
> **Database:** `warung_pintar.db` (WAL mode)  
> **Location:** `getApplicationDocumentsDirectory()` / `app_flutter/warung_pintar.db`

---

## ⚙️ Database Configuration

```sql
PRAGMA journal_mode = WAL
PRAGMA synchronous = NORMAL
PRAGMA foreign_keys = ON
```

---

## 📊 Schema Overview

| Table | Purpose | Primary Key | Rows |
|-------|---------|-------------|------|
| `categories` | Product categories (hierarchical) | UUIDv7 | - |
| `stock` | Product masterdata | UUIDv7 | - |
| `transactions` | Sales/purchase transactions | UUIDv7 | - |
| `audit_logs` | Immutable action audit trail | UUIDv7 | - |
| `price_history` | Price change history (append-only) | UUIDv7 | - |
| `app_settings` | Key-value app configuration | TEXT | - |

---

## 🏗️ Table Definitions

### 1. `categories`

Product categories with optional parent (hierarchical structure).

```sql
CREATE TABLE categories (
  id         TEXT    PRIMARY KEY,
  name       TEXT    UNIQUE NOT NULL,
  parent_id  TEXT    REFERENCES categories(id),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUIDv7 |
| `name` | TEXT | UNIQUE NOT NULL | Category name (e.g., "Makanan", "Minuman") |
| `parent_id` | TEXT | REFERENCES categories(id) | Self-reference for hierarchy (nullable) |
| `created_at` | DATETIME | DEFAULT CURRENT_TIMESTAMP | - |

**Example:**
```
id=uuid-xxx, name=Makanan, parent_id=null
id=uuid-yyy, name=Rokok, parent_id=null
id=uuid-zzz, name=Sultan, parent_id=uuid-yyy
```

---

### 2. `stock`

Product masterdata with current quantity and default price.

```sql
CREATE TABLE stock (
  id                   TEXT    PRIMARY KEY,
  item_name            TEXT    UNIQUE NOT NULL,
  current_qty          INTEGER DEFAULT 0,
  default_price_sen    INTEGER DEFAULT 0,
  low_stock_threshold  INTEGER DEFAULT 5,
  category_id          TEXT    REFERENCES categories(id),
  is_deleted           INTEGER DEFAULT 0,
  last_updated         DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUIDv7 |
| `item_name` | TEXT | UNIQUE NOT NULL | Product name |
| `current_qty` | INTEGER | DEFAULT 0 | Current stock quantity |
| `default_price_sen` | INTEGER | DEFAULT 0 | Default selling price in **sen** (Rp × 100) |
| `low_stock_threshold` | INTEGER | DEFAULT 5 | Alert threshold |
| `category_id` | TEXT | REFERENCES categories(id) | FK to categories |
| `is_deleted` | INTEGER | DEFAULT 0 | Soft delete flag (0=active, 1=deleted) |
| `last_updated` | DATETIME | DEFAULT CURRENT_TIMESTAMP | - |

**Money Rule:** `default_price_sen` is always in INTEGER sen.  
**Display:** `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(sen / 100)`

---

### 3. `transactions`

Sales and purchase transactions with idempotency.

```sql
CREATE TABLE transactions (
  id                       TEXT    PRIMARY KEY,
  idempotency_key          TEXT    UNIQUE NOT NULL,
  item_name                TEXT    NOT NULL,
  quantity                 INTEGER NOT NULL CHECK(quantity > 0),
  amount_sen              INTEGER NOT NULL CHECK(amount_sen >= 0),
  price_at_transaction_sen INTEGER NOT NULL,
  transaction_type         TEXT    NOT NULL CHECK(transaction_type IN ('sell', 'buy')),
  status                   TEXT    NOT NULL DEFAULT 'pending'
                            CHECK(status IN ('pending', 'confirmed', 'deleted')),
  needs_clarification      INTEGER DEFAULT 0,
  input_method             TEXT    NOT NULL
                            CHECK(input_method IN ('voice', 'image', 'manual')),
  confirmed_at             DATETIME,
  created_at              DATETIME DEFAULT CURRENT_TIMESTAMP,
  is_deleted               INTEGER DEFAULT 0
)
```

**Indexes:**
```sql
CREATE INDEX idx_tx_date   ON transactions(date(created_at))
CREATE INDEX idx_tx_type   ON transactions(transaction_type)
CREATE INDEX idx_tx_status ON transactions(status)
CREATE INDEX idx_tx_method ON transactions(input_method)
```

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUIDv7 |
| `idempotency_key` | TEXT | UNIQUE NOT NULL | UUIDv4 for duplicate prevention |
| `item_name` | TEXT | NOT NULL | Product name |
| `quantity` | INTEGER | NOT NULL, CHECK > 0 | - |
| `amount_sen` | INTEGER | NOT NULL, CHECK >= 0 | **Total amount in sen** |
| `price_at_transaction_sen` | INTEGER | NOT NULL | Price per unit at time of transaction (snapshot) |
| `transaction_type` | TEXT | IN ('sell', 'buy') | Transaction type |
| `status` | TEXT | DEFAULT 'pending' | Workflow: pending → confirmed → deleted |
| `needs_clarification` | INTEGER | DEFAULT 0 | AI flagged for human review |
| `input_method` | TEXT | IN ('voice', 'image', 'manual') | How transaction was created |
| `confirmed_at` | DATETIME | nullable | When user confirmed |
| `created_at` | DATETIME | DEFAULT CURRENT_TIMESTAMP | - |
| `is_deleted` | INTEGER | DEFAULT 0 | Soft delete |

**Critical Rules:**
- `price_at_transaction_sen` is a **snapshot** — NEVER join to current `stock.default_price_sen`
- `amount_sen` is total, NOT per-unit
- `idempotency_key` UNIQUE constraint prevents double-submit

---

### 4. `audit_logs`

Immutable audit trail for every AI action.

```sql
CREATE TABLE audit_logs (
  id               TEXT    PRIMARY KEY,
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
  raw_input_source TEXT,
  ai_raw_output    TEXT,
  state_snapshot   TEXT    NOT NULL,
  created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUIDv7 |
| `transaction_id` | TEXT | NOT NULL, FK | Reference to transactions |
| `action` | TEXT | ENUM | Action type |
| `raw_input_source` | TEXT | nullable | STT transcript or image path |
| `ai_raw_output` | TEXT | nullable | Raw Gemma JSON output (verifiable proof) |
| `state_snapshot` | TEXT | NOT NULL | Full row state as JSON at action time |
| `created_at` | DATETIME | DEFAULT CURRENT_TIMESTAMP | - |

**Stored Verbatim:**
- `raw_input_source` — exact STT transcript or image path
- `ai_raw_output` — raw AI JSON before parsing

---

### 5. `price_history`

Append-only price change history.

```sql
CREATE TABLE price_history (
  id             TEXT    PRIMARY KEY,
  stock_id       TEXT    NOT NULL REFERENCES stock(id),
  price_sen      INTEGER NOT NULL,
  reason         TEXT,
  effective_from DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUIDv7 |
| `stock_id` | TEXT | NOT NULL, FK | Reference to stock |
| `price_sen` | INTEGER | NOT NULL | Price in sen |
| `reason` | TEXT | nullable | e.g., "AI update", "manual" |
| `effective_from` | DATETIME | DEFAULT CURRENT_TIMESTAMP | When price took effect |

**Immutable Rules:**
- ❌ NEVER UPDATE existing `price_history` record
- ✅ INSERT new record for every price change
- ✅ UPDATE `stock.default_price_sen` for AI context only

---

### 6. `app_settings`

Key-value store for app configuration.

```sql
CREATE TABLE app_settings (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `key` | TEXT | PRIMARY KEY | Setting key |
| `value` | TEXT | NOT NULL | Setting value (JSON string) |
| `updated_at` | DATETIME | DEFAULT CURRENT_TIMESTAMP | - |

---

## 🔗 Relationships

```
categories (1) ──── (∞) stock
    │                    │
    │                    │
    (∞)                  (∞)
    │                    │
categories (self-ref)   │
                          │
                   transactions (∞) ──── (1) audit_logs
                          │
                          │
                   price_history (∞) ──── (1) stock
```

---

## 💰 Money Protocol

| Field | Type | Unit | Example |
|-------|------|------|---------|
| `amount_sen` | INTEGER | sen (Rp × 100) | 4500000 = Rp 45.000 |
| `price_at_transaction_sen` | INTEGER | sen | 4500000 = Rp 45.000 |
| `default_price_sen` | INTEGER | sen | 4500000 = Rp 45.000 |
| `price_sen` (price_history) | INTEGER | sen | 4500000 = Rp 45.000 |

**Conversion:**
```dart
// Rupiah → Sen
int rupiahToSen(String rupiah) => 
  (double.parse(rupiah.replaceAll('.', '')) * 100).round();

// Sen → Display
String senToDisplay(int sen) => 
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
    .format(sen / 100);

// Example
rupiahToSen("45000")    // → 4500000
senToDisplay(4500000)    // → "Rp 45.000"
```

**NEVER use float/double for money!**

---

## 🔄 Idempotency Flow

```
User submits voice/image
    ↓
Generate UUIDv4 idempotency_key
    ↓
INSERT transactions (idempotency_key UNIQUE)
    ↓
[If duplicate] → SQLite ignores, no error
[If new] → Transaction created
```

---

## 📁 File Location

| Environment | Path |
|-------------|------|
| Android | `/data/user/0/com.example.warung_pintar_cimahi/app_flutter/warung_pintar.db` |
| iOS | Application Documents Directory |
| Debug | `build/` directory |

---

## 🔧 Migration Strategy

Version tracking via `PRAGMA user_version`.

| Version | Changes |
|---------|---------|
| 1 | Initial schema |
| 2 | Added `parent_id` to `categories` |

```sql
-- Migration example (v1 → v2)
ALTER TABLE categories ADD COLUMN parent_id TEXT REFERENCES categories(id);
```

---

> **Last Updated:** 2026-05-19  
> **Source:** `lib/core/database/database_service.dart`
