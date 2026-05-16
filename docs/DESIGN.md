---
name: WarungPintar Design System
colors:
  surface: '#fcf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fcf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae7e7'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1c1b1b'
  on-surface-variant: '#414752'
  inverse-surface: '#313030'
  inverse-on-surface: '#f3f0ef'
  outline: '#717783'
  outline-variant: '#c1c6d4'
  surface-tint: '#005faf'
  primary: '#005dac'
  on-primary: '#ffffff'
  primary-container: '#1976d2'
  on-primary-container: '#fffdff'
  inverse-primary: '#a5c8ff'
  secondary: '#1b6d24'
  on-secondary: '#ffffff'
  secondary-container: '#a0f399'
  on-secondary-container: '#217128'
  tertiary: '#9a4300'
  on-tertiary: '#ffffff'
  tertiary-container: '#c05600'
  on-tertiary-container: '#fffdff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d4e3ff'
  primary-fixed-dim: '#a5c8ff'
  on-primary-fixed: '#001c3a'
  on-primary-fixed-variant: '#004786'
  secondary-fixed: '#a3f69c'
  secondary-fixed-dim: '#88d982'
  on-secondary-fixed: '#002204'
  on-secondary-fixed-variant: '#005312'
  tertiary-fixed: '#ffdbca'
  tertiary-fixed-dim: '#ffb68f'
  on-tertiary-fixed: '#331200'
  on-tertiary-fixed-variant: '#773200'
  background: '#fcf9f8'
  on-background: '#1c1b1b'
  surface-variant: '#e5e2e1'
typography:
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
    lineHeight: 26px
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
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 8px
  margin-page: 16px
  gutter: 16px
  touch-target-min: 48px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style
The design system is engineered for the high-utility needs of micro-merchants operating in vibrant, often high-glare outdoor environments. The brand personality is **reliable, utilitarian, and empowering**, focusing on extreme clarity over decorative flair. 

The aesthetic follows a **High-Contrast Functionalism** approach. It rejects soft shadows and subtle gradients—which wash out under direct sunlight—in favor of crisp 1px borders, generous whitespace, and robust hit states. The goal is to evoke a sense of digital infrastructure that is as sturdy and dependable as a physical storefront.

## Colors
The palette is optimized for maximum luminance contrast. 

- **Surface:** A pure `#FFFFFF` background is mandatory to ensure the highest possible contrast ratio against text.
- **Action:** Primary Action Blue (`#1976D2`) provides a clear, recognizable interactive signal.
- **Status:** Success Green (`#2E7D32`), Warning Orange (`#EF6C00`), and Error Red (`#C62828`) use slightly deeper shades than standard web palettes to maintain legibility against white backgrounds in bright light.
- **Typography:** Text is set in `#1A1A1A`, avoiding pure black to reduce "ink bleed" on high-brightness screens while remaining deep enough for extreme readability.

## Typography
The design system utilizes **Inter** for its exceptional legibility and systematic weight distribution. 

To ensure accessibility for all age groups and lighting conditions:
- **Minimum sizes:** No body text falls below 16px. 
- **Headings:** Minimum heading size is 20px. 
- **Weight:** Use Semi-Bold (600) or Bold (700) for interactive labels and headers to ensure they don't disappear when the screen brightness is lowered to save battery.
- **Line Height:** Tight line heights are avoided; a minimum of 1.5x for body text ensures merchants can easily track lines of text while managing busy stalls.

## Layout & Spacing
This design system is built on a strict **8dp baseline grid**. All spatial increments must be multiples of 8.

- **Margins:** Standard mobile page margins are set to 16px to maximize content area while providing a safe "thumb zone" for one-handed operation.
- **Touch Targets:** A hard minimum of 48x48px for all interactive elements (buttons, checkboxes, navigation items) is enforced to accommodate rapid, high-pressure interaction.
- **Grid:** A 4-column fluid grid is used for mobile, with 16px gutters between cards or columns.

## Elevation & Depth
Depth is communicated through **structural containment** rather than shadows. Shadows are strictly prohibited as they lack the necessary contrast for outdoor use.

- **Tiers:** Use background color contrast to show hierarchy. The primary background is always White (#FFFFFF). Secondary areas (like headers or footers) can use a very light grey (#F5F5F5) if distinction is required.
- **Borders:** 1px solid borders in `#E0E0E0` define the boundaries of cards, inputs, and sections.
- **Active State:** For pressed or active states, use a subtle 2px inset border or a light grey fill (#F5F5F5) to provide immediate tactile feedback without relying on blur effects.

## Shapes
Shapes are **Soft (4px / 0.25rem)**. This slight rounding provides a modern, approachable feel while maintaining the structural rigidity required for a high-density, grid-based layout. 

- **Buttons & Inputs:** Use the standard 4px radius.
- **Cards:** Can scale up to 8px (rounded-lg) to clearly contain nested content.
- **Status Badges:** Use a pill-shaped (full) radius to distinguish them from interactive buttons.

## Components
Consistent component styling ensures the app is predictable for users who may be less tech-savvy.

- **Buttons:** Large, high-contrast blocks. Primary buttons use white text on the Primary Action Blue. Tertiary/Ghost buttons must use a 1px border to define their hit area.
- **Icons:** Use **Material Symbols Outlined**. Icons should never stand alone; they must always be accompanied by a text label (e.g., in bottom navigation or action bars) to ensure zero ambiguity.
- **Input Fields:** Use a 1px `#E0E0E0` border with a 16px internal padding. Labels must be persistent (top-aligned) rather than floating to maintain context during entry.
- **Cards:** Cards should not have shadows. Use a 1px solid border. Group related data (like transaction history) within these cards to create visual "containers" of information.
- **Lists:** Every list item must have a minimum height of 56px to ensure easy tapping. Use a 1px divider line between items.
- **Checkboxes & Radios:** Scaled up to 24x24px within a 48px touch target area. Use high-contrast fills for the checked state.