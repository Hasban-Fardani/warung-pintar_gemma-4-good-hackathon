---
name: WarungPintar Design System
version: 2.0.0
source_of_truth: YAML tokens below are the ONLY valid color references. Ignore any hex values mentioned in prose sections — prose is for intent, YAML is for implementation.
colors:
  # Surfaces
  surface: '#ffffff'
  surface-dim: '#dcd9d9'
  surface-bright: '#fcf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae7e7'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1a1a1a'
  on-surface-variant: '#414752'
  inverse-surface: '#313030'
  inverse-on-surface: '#f3f0ef'

  # Borders
  outline: '#717783'
  outline-variant: '#e0e0e0'

  # Primary (Blue — interactive actions, active states, links)
  primary: '#005dac'
  primary-container: '#1976d2'
  on-primary: '#ffffff'
  on-primary-container: '#ffffff'
  inverse-primary: '#a5c8ff'
  primary-fixed: '#d4e3ff'
  primary-fixed-dim: '#a5c8ff'
  on-primary-fixed: '#001c3a'
  on-primary-fixed-variant: '#004786'

  # Secondary (Green — confirmed transactions, profit, success states ONLY)
  secondary: '#2e7d32'
  secondary-container: '#e8f5e9'
  on-secondary: '#ffffff'
  on-secondary-container: '#1b5e20'
  secondary-fixed: '#a3f69c'
  secondary-fixed-dim: '#88d982'
  on-secondary-fixed: '#002204'
  on-secondary-fixed-variant: '#005312'

  # Tertiary (Orange — warnings, pending states)
  tertiary: '#ef6c00'
  tertiary-container: '#fff3e0'
  on-tertiary: '#ffffff'
  on-tertiary-container: '#e65100'
  tertiary-fixed: '#ffdbca'
  tertiary-fixed-dim: '#ffb68f'
  on-tertiary-fixed: '#331200'
  on-tertiary-fixed-variant: '#773200'

  # Error (Red — errors, modal keluar/buy transactions)
  error: '#c62828'
  error-container: '#ffdad6'
  on-error: '#ffffff'
  on-error-container: '#93000a'

  # Background
  background: '#fcf9f8'
  on-background: '#1a1a1a'
  surface-variant: '#e5e2e1'
  surface-tint: '#005dac'

typography:
  # Desktop/Tablet
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.02em

  # Mobile — minimum sizes enforced for 40+ users
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md-mobile:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  body-mobile:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  label-mobile:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  caption-mobile:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px

rounded:
  sm: 0.125rem    # 2px — very subtle rounding
  DEFAULT: 0.25rem  # 4px — buttons, inputs
  md: 0.375rem    # 6px
  lg: 0.5rem      # 8px — cards
  xl: 0.75rem     # 12px — modals, bottom sheets
  xxl: 1rem       # 16px — large cards, FAB background
  full: 9999px    # pill shape — badges, active tab indicator

spacing:
  unit: 8px
  margin-page: 16px
  gutter: 16px
  touch-target-min: 48px
  stack-xs: 4px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
  stack-xl: 32px
  card-padding: 16px
  button-padding-h: 24px
  button-padding-v: 12px
  icon-gap: 8px       # gap between icon and label
  list-item-min-height: 56px

elevation:
  # Shadows are ALLOWED for floating elements only (FAB, modals, dropdowns, tooltips)
  # For cards and static elements: use border (1px outline-variant) instead of shadow
  level-0: 'none'
  level-1: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06)'   # subtle — inputs focused
  level-2: '0 2px 8px rgba(0,0,0,0.10), 0 1px 4px rgba(0,0,0,0.08)'   # cards on hover
  level-3: '0 4px 16px rgba(0,0,0,0.12), 0 2px 6px rgba(0,0,0,0.08)'  # FAB, floating panels
  level-4: '0 8px 24px rgba(0,0,0,0.14), 0 4px 8px rgba(0,0,0,0.10)'  # modals, bottom sheets

states:
  # Interactive state overlays — apply ON TOP of base background
  hover:
    overlay: 'rgba(0, 93, 172, 0.06)'   # primary at 6% opacity
  pressed:
    overlay: 'rgba(0, 93, 172, 0.12)'   # primary at 12% opacity
    transform: 'scale(0.97)'
    duration: '80ms'
  focused:
    outline: '2px solid #005dac'
    outline-offset: '2px'
  disabled:
    opacity: '0.38'
    cursor: 'not-allowed'
  selected:               # active tab, selected list item
    background: '#005dac'
    color: '#ffffff'
  selected-subtle:        # chips, filter pills
    background: '#d4e3ff'
    color: '#005dac'
    border: '1px solid #005dac'

motion:
  # Duration
  duration-instant: '80ms'     # pressed feedback
  duration-fast: '150ms'       # FAB sub-item appear
  duration-default: '200ms'    # page transitions, modals
  duration-slow: '300ms'       # complex animations
  duration-slower: '400ms'     # bottom sheet slide up

  # Easing
  easing-standard: 'cubic-bezier(0.2, 0, 0, 1)'         # most transitions
  easing-decelerate: 'cubic-bezier(0, 0, 0, 1)'          # elements entering screen
  easing-accelerate: 'cubic-bezier(0.3, 0, 1, 1)'        # elements leaving screen
  easing-spring: 'cubic-bezier(0.34, 1.56, 0.64, 1)'     # FAB expand, bounce effects

  # Specific animations
  fab-expand:
    duration: '200ms'
    easing: spring
    sub-item-stagger: '40ms'    # each sub-FAB appears 40ms after previous
  toast-enter:
    duration: '150ms'
    easing: decelerate
    from: 'translateY(8px) opacity(0)'
  toast-exit:
    duration: '100ms'
    easing: accelerate
  bottom-sheet-enter:
    duration: '300ms'
    easing: decelerate
    from: 'translateY(100%)'
  page-transition:
    duration: '200ms'
    easing: standard
---

## Source of Truth Rule

**YAML tokens above are the single source of truth.** When implementing any component, reference token names (e.g., `primary`, `outline-variant`, `stack-md`) — not raw hex values. This ensures consistency when tokens are updated.

---

## Brand & Style Intent

WarungPintar is built for micro-merchants aged 40–60 operating in busy, often outdoor environments. The design personality is **reliable, clear, and empowering** — not playful, not corporate.

Visual hierarchy is achieved through **color contrast + elevation**, not decoration. The goal is an interface that communicates status instantly, even when the user is serving three customers simultaneously.

---

## Color Usage Rules

Colors have strict semantic roles. Using a color outside its role is a bug, not a style choice.

| Color | Role | Example |
|-------|------|---------|
| `primary` (#005DAC) | All interactive actions, active states, links, FAB | Active tab indicator, primary buttons, focused input border |
| `secondary` (#2E7D32) | Confirmed transactions, profit values, success badges | "Confirmed" badge, profit card value, success toast |
| `tertiary` (#EF6C00) | Pending states, warnings | "Pending" badge, pending banner, stock alert |
| `error` (#C62828) | Errors, buy/modal transactions, destructive actions | "Modal Keluar" card, error toast, delete confirmation |
| `on-surface` (#1A1A1A) | Primary body text | Transaction names, card labels |
| `on-surface-variant` (#414752) | Secondary text, captions, inactive labels | Inactive nav labels, helper text |
| `outline-variant` (#E0E0E0) | Card borders, dividers, input borders (default state) | Card borders, list dividers |

**CRITICAL RULE — Green is NOT for navigation:**
`secondary` (green) must NEVER be used as an active tab indicator, button background, or any primary action color. Green = confirmed/profit/success only. Active states always use `primary` (blue).

---

## Typography Rules

- Minimum body text: **16px** (body-mobile)
- Minimum label/caption: **12px** (caption-mobile) — use sparingly
- Minimum heading: **20px** (headline-md-mobile)
- All monetary values: `font-variant-numeric: tabular-nums` to prevent layout shift when numbers change
- Monetary values preceded by `~` use `on-surface-variant` color to indicate "approximate/pending"

---

## Elevation Rules

Elevation communicates **which elements float above others**. Use it purposefully:

| Element | Elevation Level | Implementation |
|---------|----------------|----------------|
| Cards (static) | 0 | 1px border `outline-variant`, no shadow |
| Cards (hover/active) | 1 | `level-1` shadow |
| Input (focused) | 1 | `level-1` shadow + `primary` border |
| FAB | 3 | `level-3` shadow |
| Bottom sheet, Modal | 4 | `level-4` shadow |
| Tooltip, Dropdown | 3 | `level-3` shadow |

Static page content (headers, list items, nav bar) uses **zero elevation** — borders only.

---

## Component Specifications

### Bottom Navigation Bar

```
Height: 64px (including safe area inset)
Background: surface (#FFFFFF)
Top border: 1px solid outline-variant (#E0E0E0)
Elevation: none (border only)

Tab item:
  Width: equal distribution (screen width / tab count)
  Touch target: 48px minimum height

Active tab:
  Indicator: pill shape, background primary (#005DAC), height 32px, width 64px
  Icon color: on-primary (#FFFFFF) inside indicator
  Label color: primary (#005DAC)
  Font: label-mobile (14px, weight 500)

Inactive tab:
  Icon color: on-surface-variant (#414752)
  Label color: on-surface-variant (#414752)
  Font: label-mobile (14px, weight 500)

NEVER use secondary (green) for active state.
```

### FAB (Floating Action Button) — Expandable

```
Main FAB:
  Size: 56x56px
  Shape: rounded-full (circle)
  Background: primary (#005DAC)
  Icon color: on-primary (#FFFFFF)
  Icon: add (collapsed), close (expanded)
  Elevation: level-3
  Position: bottom-right, margin 16px from edge and 16px above nav bar

Expand behavior:
  Direction: UPWARD from FAB position
  Alignment: RIGHT-aligned to FAB right edge (NOT left-aligned)
  Overlay: semi-transparent black rgba(0,0,0,0.4) covers content behind FAB
  Overlay tap: dismisses FAB expansion
  Animation: easing-spring, 200ms, sub-items stagger 40ms

Sub-FAB items (3 items, from bottom to top: Manual, Kamera, Suara):
  Layout: Row(label, SizedBox(8px), CircleAvatar(icon))
  Label position: LEFT of icon circle (label appears first, then icon)
  Label container:
    background: surface (#FFFFFF)
    border: 1px solid outline-variant (#E0E0E0)
    border-radius: rounded-lg (8px)
    padding: 8px 12px
    font: label-mobile (14px, weight 500)
    color: on-surface (#1A1A1A)
    elevation: level-2
    min-width: 80px (prevent text clipping)
    max-width: 120px
  Icon circle:
    size: 48x48px
    background: surface-container-low (#F6F3F2)
    border: 1px solid outline-variant (#E0E0E0)
    icon color: primary (#005DAC)
    elevation: level-2

CRITICAL — sub-FAB label clipping fix:
  Container must have sufficient right padding to not clip against screen edge.
  The entire Row (label + icon) must be right-aligned to FAB.
  Use: Align(alignment: Alignment.centerRight) wrapping each sub-item Row.
  Ensure label container has overflow: visible or minimum width enforced.
```

### Cards (Bento Box Dashboard)

```
Background: surface-container-lowest (#FFFFFF)
Border: 1px solid outline-variant (#E0E0E0)
Border-radius: rounded-lg (8px)
Padding: 16px
Elevation: none (border only, no shadow)

Hover/pressed state: elevation level-1 (subtle shadow appears)

Omzet card (full width):
  Label: label-md (14px), on-surface-variant, uppercase, letter-spacing 0.08em
  Value: headline-lg-mobile (24px bold), primary (#005DAC)
  Icon: 20px, primary color, left of label

Profit card (half width):
  Value: headline-md-mobile (20px bold), secondary (#2E7D32)
  
Modal Keluar card (half width):
  Value: headline-md-mobile (20px bold), error (#C62828)
```

### Transaction List Items

```
Min height: 56px
Padding: 12px 16px
Divider: 1px solid outline-variant between items

Left: icon circle 40x40px
  Sell (jual): background secondary-container (#E8F5E9), icon color secondary (#2E7D32)
  Buy (beli): background error-container (#FFDAD6), icon color error (#C62828)

Center: item name (body-md, on-surface) + timestamp (caption-mobile, on-surface-variant)
Right: amount
  Sell: secondary (#2E7D32), prefix '+'
  Buy: error (#C62828), prefix '-'
  Pending: on-surface-variant, prefix '~'

Status badge:
  Confirmed: background secondary-container, text on-secondary-container, pill shape
  Pending: background tertiary-container (#FFF3E0), text on-tertiary-container (#E65100), pill
  Clarify: background error-container, text on-error-container, pill
```

### Input Fields

```
Height: 56px (touch-target-min + padding)
Border: 1px solid outline-variant (#E0E0E0)
Border-radius: rounded-DEFAULT (4px)
Padding: 16px horizontal, 12px vertical
Background: surface-container-lowest (#FFFFFF)
Font: body-mobile (16px)

Label: persistent top-aligned (NOT floating placeholder)
  Font: label-mobile (14px, weight 500)
  Color: on-surface-variant
  Margin-bottom: 6px

States:
  Default: border outline-variant
  Focused: border primary (#005DAC) 2px + elevation level-1
  Error: border error (#C62828) 2px
  Disabled: opacity 0.38, background surface-container
  Filled (has value): border on-surface-variant
```

### Buttons

```
Primary button:
  Height: 48px
  Background: primary (#005DAC)
  Text: on-primary (#FFFFFF), label-lg (16px, weight 600)
  Border-radius: rounded-DEFAULT (4px)
  Padding: 0 24px
  Elevation: none (flat)
  Pressed: scale(0.97) + overlay rgba(255,255,255,0.12), duration 80ms

Secondary/Outline button:
  Height: 48px
  Background: transparent
  Border: 1px solid primary (#005DAC)
  Text: primary (#005DAC), label-lg (16px, weight 600)
  Border-radius: rounded-DEFAULT (4px)
  Pressed: background primary-fixed (#D4E3FF)

Destructive button:
  Same as primary but background error (#C62828)
  Only for delete/irreversible actions with confirmation dialog

Disabled state (all buttons):
  Opacity: 0.38
  Pointer events: none
```

### Status Badges / Chips

```
Shape: pill (border-radius full)
Height: 24px
Padding: 0 10px
Font: caption-mobile (12px, weight 500)

Input method badges:
  Voice: background primary-fixed (#D4E3FF), text on-primary-fixed-variant (#004786)
  Image: background secondary-fixed (#A3F69C), text on-secondary-fixed-variant (#005312)
  Manual: background surface-container-high, text on-surface-variant

Status badges:
  Confirmed: background secondary-container (#E8F5E9), text secondary (#2E7D32)
  Pending: background tertiary-container (#FFF3E0), text tertiary (#EF6C00)
  Needs clarification: background error-container (#FFDAD6), text error (#C62828)
```

### Pending Banner

```
Background: tertiary-container (#FFF3E0)
Border: 1px solid tertiary (#EF6C00)
Border-radius: rounded-lg (8px)
Padding: 12px 16px
Margin: 0 16px (page margin)

Icon: warning, color tertiary (#EF6C00), size 20px
Text: label-mobile (14px, weight 500), on-tertiary-container (#E65100)
Action button: text-only, primary color, right-aligned
```

### Toast / Snackbar

```
Position: top of screen, below AppBar (NOT bottom — avoid covering FAB)
Width: screen width - 32px (16px margin each side)
Margin-top: 8px below AppBar
Border-radius: rounded-lg (8px)
Padding: 12px 16px
Min-height: 48px
Elevation: level-3
Animation: toast-enter spec (slide down from top + fade in)

Success: background secondary (#2E7D32), text on-secondary (#FFFFFF)
Info: background primary (#005DAC), text on-primary (#FFFFFF)
Warning: background tertiary (#EF6C00), text on-tertiary (#FFFFFF)
Error: background error (#C62828), text on-error (#FFFFFF)

Dismiss:
  Success/Info: auto-dismiss after 3000ms
  Warning: manual dismiss only
  Error: manual dismiss only (never auto-dismiss)
```

---

## Anti-Patterns — Hal yang Dilarang

```
❌ Menggunakan secondary (green) untuk active tab, button utama, atau elemen navigasi
❌ Menggunakan shadow pada card statis atau elemen non-floating
❌ Teks body di bawah 16px (kecuali caption pada badge — minimum 12px)
❌ Label teks pada badge/chip yang terpotong — enforce min-width
❌ FAB sub-item label yang muncul di luar batas layar atau terpotong
❌ Warna hardcode di kode (gunakan token name, bukan hex langsung)
❌ Active state yang hanya bergantung pada warna saja tanpa perubahan shape/icon
❌ Toast/snackbar yang auto-dismiss untuk pesan error
❌ Dua bottom navigation bar dalam satu screen
❌ Input field tanpa persistent label (floating placeholder saja tidak cukup)
❌ Elemen interaktif dengan touch target < 48px
❌ Monetary values menggunakan float — selalu integer (sen) diformat ke Rupiah
```