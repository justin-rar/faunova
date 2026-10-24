---
name: Faunova
colors:
  surface: '#fcf9f2'
  surface-dim: '#dcdad3'
  surface-bright: '#fcf9f2'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3ec'
  surface-container: '#f0eee7'
  surface-container-high: '#ebe8e1'
  surface-container-highest: '#e5e2db'
  on-surface: '#1c1c18'
  on-surface-variant: '#434841'
  inverse-surface: '#31312c'
  inverse-on-surface: '#f3f0e9'
  outline: '#747970'
  outline-variant: '#c3c8be'
  surface-tint: '#4d6449'
  primary: '#445b40'
  on-primary: '#ffffff'
  primary-container: '#5c7457'
  on-primary-container: '#def9d5'
  inverse-primary: '#b3ceac'
  secondary: '#735b25'
  on-secondary: '#ffffff'
  secondary-container: '#fedb99'
  on-secondary-container: '#785f29'
  tertiary: '#495a46'
  on-tertiary: '#ffffff'
  tertiary-container: '#61735d'
  on-tertiary-container: '#e3f7dc'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#cfeac7'
  primary-fixed-dim: '#b3ceac'
  on-primary-fixed: '#0b200a'
  on-primary-fixed-variant: '#364c32'
  secondary-fixed: '#ffdea0'
  secondary-fixed-dim: '#e3c282'
  on-secondary-fixed: '#261a00'
  on-secondary-fixed-variant: '#5a430f'
  tertiary-fixed: '#d4e8ce'
  tertiary-fixed-dim: '#b8ccb2'
  on-tertiary-fixed: '#101f0f'
  on-tertiary-fixed-variant: '#3a4b38'
  background: '#fcf9f2'
  on-background: '#1c1c18'
  surface-variant: '#e5e2db'
typography:
  display-editorial:
    fontFamily: Noto Serif
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 38px
  headline-species:
    fontFamily: Noto Serif
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  subhead-species:
    fontFamily: Noto Serif
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 22px
  title-ui:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
  body-default:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-medium:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '500'
    lineHeight: 22px
  body-compact:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-prominent:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
  label-caption:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system establishes a tranquil, nature-grounded, editorial environment tailored for wildlife discovery across the Indonesian archipelago. The interface draws inspiration from botanical field notebooks and high-end natural history journals, balancing utilitarian fieldwork efficiency with a gentle, tactile editorial sensibility.

Key style directives:
- **Calm, Earthy Editorial:** Photo-first focus utilizing warm ivory backdrops and botanical sage tones. Visual pacing feels deliberate, quiet, and unhurried.
- **Natural Tactility:** Low-contrast ghost borders and translucent frosted glass overlays replace artificial drop shadows and skeuomorphic gradients.
- **Strict Clarity:** Natural Indonesian interface copy, clear botanical taxonomy, and stark legibility outdoors under bright sunlight.
- **Purity of Medium:** Flat tone surfaces, absence of saturated modern neon accents, and zero artificial 3D renders.

## Colors

The palette is rooted in tropical foliage, mist, and aged parchment. Contrast ratios must strictly preserve readability under natural ambient outdoor light.

### Palette Architecture
- **Page Canvas (`#F7F4ED`):** Warm Ivory base layer for primary viewports, background screens, and translucent navigation chrome.
- **Primary / Brand Anchor (`#5C7457`):** Deep Sage for top app bars, primary interactive text, active iconography, and high-emphasis dark buttons.
- **Accent / Interactive Highlight (`#C8A96B`):** Warm Gold reserved for focal calls-to-action, floating camera shutter triggers, and verification badges.
- **Tertiary Accent (`#8FA28A`):** Mid Sage for structured decorative blocks, subtle card accents, and secondary surfaces.
- **Surface & Containers (`#C7D3C0`):** Light Sage for nested card fills, list items, search inputs, and inactive chip backgrounds.
- **Text & Core Outlines (`#1F2A1E`):** Deep Forest Green serving as the dark neutral for titles, body text, data points, and standard line icons.
- **Editorial Gold Accent (`#7F6326`):** Deepened Ochre Gold used strictly when gold serves as text, taxonomy badges, or thin graphical line work on Ivory backgrounds.
- **Critical / Status (`#B3261E`):** Earth Red reserved for endangered species flags, alert states, destructive actions, and active favorite/like indicators.

### Accessibility Enforcement Rules
- **Prohibited:** Never apply pure white (`#FFFFFF`) text over Light Sage (`#C7D3C0`) or Gold (`#C8A96B`).
- **White Text Boundary:** White (`#FFFFFF`) text is exclusively permitted on Deep Sage (`#5C7457`) or Deep Forest Green (`#1F2A1E`).
- **Dark Text Rule:** All copy overlaid on Gold (`#C8A96B`), Light Sage (`#C7D3C0`), and Mid Sage (`#8FA28A`) must use Deep Forest Green (`#1F2A1E`).
- **Ivory Contrast Rule:** Any non-photo gold typography or iconography overlaid on Warm Ivory (`#F7F4ED`) must use Deepened Ochre Gold (`#7F6326`) to satisfy WCAG AA contrast.

## Typography

The typographical landscape blends the literary dignity of classical taxonomy plates with the functional legibility of modern mobile wayfinding. 

### Font Roles
- **Editorial & Taxonomy (Noto Serif):** Used for species binomials, regional animal vernacular titles, editorial hero pull-quotes, and narrative habitat accounts. It delivers historical gravitas and natural authority.
- **Product Interface (Plus Jakarta Sans):** Applied to app headings, search fields, navigation items, metadata chips, technical timestamps, and functional action labels.

### Typographic Discipline
- **Three-Size Rule:** Any single mobile viewport should restrict itself to a maximum of three distinct font sizes to maintain compositional calm.
- **Scientific Names:** Binomial nomenclature (e.g., *Panthera tigris sumatrae*) must always be set in Serif Italic using `subhead-species` or `body-default`.
- **Text Bounds:** Body text never drops below 13px (`body-compact`); metadata and navigation captions stay strictly at 11px (`label-caption`).

## Layout & Spacing

Layout geometry is tailored to a handheld Android form factor (standard base frame 390x844 dp) using an 8pt mathematical rhythm.

### Grid & Margins
- **Canvas Margins:** Fixed 16px (`1rem` / `margin`) horizontal screen padding across both sides of the display.
- **Internal Column Gutters:** 16px (`1rem` / `gutter`) spacing between elements in 2-column species catalog grids.
- **Micro Spacing:** 4px (`space-xs`) for icon-to-label inline offsets; 8px (`space-sm`) for card internal gaps and stacked text pairs.
- **Macro Spacing:** 16px (`space-md`) for content block separation; 24px (`space-lg`) between major content sections; 32px (`space-xl`) before major editorial dividers.

### Vertical Canvas Flow
- Full-bleed photography containers may extend to screen edges (0px margin), but their internal titles and overlays must respect the 16px safe margin.
- Content scrolling areas must include 96px bottom padding (`space-xl` + bottom bar accommodation) to prevent navigation overlap.

## Elevation & Depth

To preserve an organic, editorial journal feel, this system rejects heavy drop shadows, synthetic ambient lighting, and high-opacity blurs. Depth is achieved purely through soft surface stacking, boundary definition, and calibrated glassmorphism.

### Depth Principles
- **No Heavy Shadows:** Standard UI surfaces do not cast cast-shadows. Elevation is conveyed by placing Light Sage (`#C7D3C0`) containers over the Warm Ivory (`#F7F4ED`) canvas.
- **Ghost Outlines:** Containers and nested modules utilize a crisp 1px border. Acceptable border colors are solid `#C7D3C0` on Ivory, or `rgba(31, 42, 30, 0.1)` on tinted card surfaces.
- **Frosted Glass (Navigation & Overlays):** 
  - Background: Warm Ivory (`#F7F4ED`) set to 75% opacity (`rgba(247, 244, 237, 0.75)`).
  - Backdrop Blur: `blur(16px)` with an accompanying saturation boost of 120%.
  - Border: 1px solid `rgba(255, 255, 255, 0.6)` on the upper boundary to catch ambient light.
- **Tactile Floating Shutter:** The central camera action button uses a gentle, tinted ambient glow (`0px 4px 16px rgba(200, 169, 107, 0.35)`) to signal physical tap readiness without relying on harsh black drop shadows.

## Shapes

The shape system expresses an organic, pebble-like softness that complements wildlife imagery while keeping UI controls structural and stable.

### Shape Hierarchy
- **Cards & Primary Panels:** `16px` border-radius (`rounded-2xl`). Used for species profiles, observation log entries, and image containers.
- **Buttons, Form Fields & Dialogs:** `12px` border-radius (`rounded-xl`). Balances touch target clarity with cohesive corner geometry.
- **Pills & Shutter Triggers:** Fully rounded / circular (`9999px`). Reserved exclusively for status indicators, filter tags, and circular action buttons (such as the center camera capture icon).
- **Nested Card Harmony:** When an element is placed within a card (e.g., an image within a 16px card), the inner element's radius scales down to 10px–12px to prevent visual pinching.

## Components

All interface components are rendered with natural Indonesian labels and uniform outline iconography (2px line weight, rounded joins).

### Navigation Bar (Translucent Bottom Chrome)
- **Structure:** Fixed bottom dock spanning full screen width (390px), height 72px plus device safe inset.
- **Surface:** Frosted Warm Ivory (`rgba(247, 244, 237, 0.75)`) with `16px` backdrop-filter blur and a 1px top border of `rgba(255, 255, 255, 0.8)`.
- **Items (5 Tabs):**
  1. *Beranda* (Home): Outline hut/leaf icon with caption. Active state uses Deep Sage (`#5C7457`).
  2. *Cari* (Explore/Search): Magnifying glass icon.
  3. *Kamera* (Capture): Elevated center circular button (56px diameter). Gold (`#C8A96B`) background, 1px border (`#7F6326`), dark green icon (`#1F2A1E`).
  4. *Game* (Quizzes/Badges): Compass or puzzle leaf icon.
  5. *Profil* (Profile): User outline icon.
- **Inactive Tabs:** Icon and text set to Deep Forest Green with 50% opacity (`rgba(31, 42, 30, 0.5)`).

### Buttons
- **Primary / Action (Accent Gold):**
  - Background: Gold (`#C8A96B`).
  - Text/Icon: Deep Forest Green (`#1F2A1E`), font weight 600.
  - Border radius: 12px. Height: 48px.
  - Usage: "Identifikasi Spesies", "Simpan Catatan", "Mulai Jelajah".
- **Secondary (Deep Sage):**
  - Background: Deep Sage (`#5C7457`).
  - Text/Icon: White (`#FFFFFF`), font weight 600.
  - Border radius: 12px. Height: 48px.
  - Usage: "Bagikan Temuan", "Ikuti Ekspedisi".
- **Ghost / Tertiary (Ivory / Transparent):**
  - Background: Transparent or `#F7F4ED`.
  - Border: 1px solid `rgba(31, 42, 30, 0.15)`.
  - Text: Deep Forest Green (`#1F2A1E`).
  - Usage: "Batal", "Lihat Taksonomi Lengkap".

### Chips & Filter Tags
- **Default State:** Light Sage (`#C7D3C0`) background, Deep Forest Green (`#1F2A1E`) text, 12px radius or pill-shaped, height 32px.
- **Active State:** Deep Sage (`#5C7457`) background with crisp White (`#FFFFFF`) text.
- **Endangered/Alert Chip:** Subtle tint `rgba(179, 38, 30, 0.12)`, text and 1px border in Red (`#B3261E`).

### Cards (Observation & Species Logs)
- **Base Style:** Background Light Sage (`#C7D3C0`) or Pure Ivory (`#FFFFFF`) sitting on Canvas (`#F7F4ED`). 1px border `rgba(31, 42, 30, 0.08)`. Radius 16px.
- **Internal Layout:** 
  - Edge-to-edge or 8px inset image header (aspect ratio 4:3 or 16:9).
  - Common Indonesian name in `headline-species` (Noto Serif, `#1F2A1E`).
  - Scientific binomial in `subhead-species` (Noto Serif Italic, `#5C7457`).
  - Location and date metadata in `label-caption` with mini outline pin icon.

### Form Inputs & Search Fields
- **Search Bar:** Height 44px, background Light Sage (`#C7D3C0`) at 60% opacity or Warm Ivory with 1px border (`#C7D3C0`). Radius 12px.
- **Placeholder:** Deep Forest Green at 45% opacity (`rgba(31, 42, 30, 0.45)`). Indonesian sample copy: *"Cari nama burung, mamalia, reptil..."*
- **Focus State:** 1.5px border in Deep Sage (`#5C7457`).

### Checkbox & Radio Selections
- **Box/Ring:** 20px size, 1.5px outline in Deep Sage (`#5C7457`).
- **Checked State:** Deep Sage fill with white checkmark or inner dot. No neon blues or saturated synthetic hues.