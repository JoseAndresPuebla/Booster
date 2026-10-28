---
name: Tactile Neo-Glass Vault
colors:
  surface: '#11131b'
  surface-dim: '#11131b'
  surface-bright: '#373942'
  surface-container-lowest: '#0c0e16'
  surface-container-low: '#191b24'
  surface-container: '#1d1f28'
  surface-container-high: '#282a32'
  surface-container-highest: '#33343e'
  on-surface: '#e2e1ee'
  on-surface-variant: '#bac9cc'
  inverse-surface: '#e2e1ee'
  inverse-on-surface: '#2e3039'
  outline: '#849396'
  outline-variant: '#3b494c'
  surface-tint: '#00daf3'
  primary: '#c3f5ff'
  on-primary: '#00363d'
  primary-container: '#00e5ff'
  on-primary-container: '#00626e'
  inverse-primary: '#006875'
  secondary: '#ffe9b5'
  on-secondary: '#3d2f00'
  secondary-container: '#fcc800'
  on-secondary-container: '#6d5500'
  tertiary: '#ffe4fc'
  on-tertiary: '#570066'
  tertiary-container: '#fcbaff'
  on-tertiary-container: '#9900b1'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#9cf0ff'
  primary-fixed-dim: '#00daf3'
  on-primary-fixed: '#001f24'
  on-primary-fixed-variant: '#004f58'
  secondary-fixed: '#ffe08d'
  secondary-fixed-dim: '#f2c000'
  on-secondary-fixed: '#241a00'
  on-secondary-fixed-variant: '#584400'
  tertiary-fixed: '#ffd6fe'
  tertiary-fixed-dim: '#faabff'
  on-tertiary-fixed: '#35003f'
  on-tertiary-fixed-variant: '#7b008f'
  background: '#11131b'
  on-background: '#e2e1ee'
  surface-variant: '#33343e'
typography:
  headline-xl:
    fontFamily: Outfit
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
  headline-xl-mobile:
    fontFamily: Outfit
    fontSize: 30px
    fontWeight: '800'
    lineHeight: 38px
  headline-lg:
    fontFamily: Outfit
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Outfit
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: Outfit
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Outfit
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18px
  label-md:
    fontFamily: Outfit
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
  label-sm:
    fontFamily: Outfit
    fontSize: 9px
    fontWeight: '800'
    lineHeight: 12px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.25rem
---

## Brand & Style

This design system establishes a high-end digital sanctuary for trading card game collectors, combining the tactile thrill of a real-world pack opening with the serenity of a museum-grade archival vault. The visual signature bridges contemporary physical skeuomorphism and atmospheric glassmorphism. Surfaces feel like weighted acrylic slabs, slabbed grading cases (PSA/BGS aesthetic), and dark anti-reflective museum vitrines.

The interface evokes anticipation, prestige, and tangible value. Interactions must mimic physics: card tilts respond to device gyroscopes with responsive chromatic dispersion, pack foils tear with haptic detents, and card sleeves settle with micro-damped spring physics.

Franchise identities do not overwhelm the core architecture; instead, the deep obsidian framework acts as an inert luxury stage where franchise-specific dynamic accents (Electric Amber, Mythic Flame Orange, Crimson Red, Arcane Violet, and Championship Gold) ignite via ambient rim-lighting, energy particle fields, and foil sheen highlights.

## Colors

The core palette is anchored in an uncompromising deep-space obsidian scale, ensuring all rarity foils and holographic shaders pop with maximum luminous contrast.

### Foundation & Surfaces
- **Canvas Base (`#0A0C14`):** The absolute background, representing unlit vault space.
- **Surface Layer 1 (`#121524`):** Smoky midnight slate used for structural containers, bottom sheets, and inactive deck trays.
- **Surface Layer 2 (`#1B1F36`):** Elevated tactile surfaces, modal backdrops, and interactive panels.
- **Glass Tint (`rgba(255, 255, 255, 0.04)` to `rgba(255, 255, 255, 0.08)`): Frosted overlays providing optical depth without compromising legibility.
- **Glass Hairline Stroke (`rgba(255, 255, 255, 0.08)`): Ultra-thin edge highlight applied to all floating cards, slabs, and modular containers.

### Dynamic Franchise Accents
The global accent dynamically switches based on the active collection vault:
- **Pokémon Mode:** Primary Cyan (`#00E5FF`) with Electric Amber (`#FFCB05`) accents.
- **Magic: The Gathering Mode:** Mythic Flame Orange (`#FF6F00`) with Vintage Gold (`#D4AF37`) metallic highlights.
- **One Piece Mode:** Crimson Red (`#D32F2F`) grounded against Deep Navy (`#0D1B2A`).
- **Riftbound Mode:** Arcane Violet (`#7B1FA2`) radiating Cyber Magenta (`#E040FB`).
- **WWE SuperCard Mode:** Championship Gold (`#FFD700`) paired with Ringside Ruby (`#B71C1C`).

### Semantic Status
- **Success / Mint Condition:** `#00E676`
- **Warning / Near Mint:** `#FFD600`
- **Error / Void:** `#FF1744`
- **Info / Unopened:** `#00B0FF`

## Typography

Typography establishes an editorial luxury hierarchy balancing technical collector metrics and modern consumer playfulness.

- **Headline Display (Outfit):** Bold, geometric, and sculptural. Used for vault values, card rarity classes (Secret Rare, Mythic, Alternate Art), and unboxing sequence summaries.
- **Interface Body (Plus Jakarta Sans):** Highly legible at small sizes, warm, rounded, and clean. Used for set checklists, card lore, grading details, and collection breakdowns.
- **Collector Badges & Metrics (Outfit):** High-density uppercase numerals, population counts, market fluctuations (+/- percentages), and serial IDs (`#001/165`) employ `label-sm` and `label-md` with `0.08em` tracking for a crisp, laser-etched badge aesthetic.

## Layout & Spacing

The layout is built for native iOS and Android touch screens, optimized for thumb-reach ergonomics and immersive 3D gestures.

- **Grid Architecture:** 4-column fluid mobile grid with `1.25rem` outer canvas padding and `1rem` column gutters.
- **Vertical Rythm:** Stacks adhere to an 8pt spatial baseline (`0.5rem` / `1rem` / `1.5rem` / `2.25rem`). Micro elements (badge paddings, card subtext) use half-step 4pt units (`0.25rem`).
- **Viewport Safe Zones:** Bottom sheets and fixed interaction rails maintain at least `2.5rem` padding from the screen bottom to gracefully clear device home indicators.
- **Card Showcase Proportions:** Standard cards conform strictly to a 2.5:3.5 aspect ratio (5:7 ratio). In multi-column grid views, card slabs span 2 columns with a fixed `12px` gap. In pack inspection mode, cards dynamically occupy 85% of screen height with automatic horizontal centering.

## Elevation & Depth

Visual depth is achieved through a multi-tiered glassmorphism model paired with chromatic lighting:

- **Level 0 (Floor):** Canvas background `#0A0C14` with ambient radial color bleeds emitting from current franchise theme (250px blur, 15% opacity).
- **Level 1 (Docked Containers & Trays):** Smoky Midnight Slate `#121524` with `backdrop-filter: blur(16px)` and an interior top-highlight gradient `linear-gradient(180deg, rgba(255,255,255,0.06) 0%, rgba(255,255,255,0.00) 100%)`.
- **Level 2 (Floating Glass Slabs & Cards):** Translucent acrylic tier with `backdrop-filter: blur(24px)`, base surface `rgba(18, 21, 36, 0.72)`, bounded by a sharp `1px` border of `rgba(255, 255, 255, 0.08)`. Shadow: `0 12px 32px -4px rgba(0, 0, 0, 0.60)`.
- **Level 3 (Inspected Card / Active Pack):** 3D perspective elevation. Surface casts a dual shadow: an ambient core drop `0 24px 48px rgba(0,0,0,0.80)` layered over a dynamic franchise accent underglow `0 0 40px rgba(accent_rgb, 0.35)`.
- **Specular Edge Sheen:** A razor-sharp internal rim stroke (`inset 0 1px 0 rgba(255, 255, 255, 0.15)`) applied to interactive modals and card slabs to simulate beveled acrylic edges.

## Shapes

The design system uses deliberate roundedness to match modern graded acrylic card slabs:

- **Cards & Slabbing Protectors:** Hard-locked to an explicit `18px` corner radius, echoing the physical dimensions of luxury protective acrylic slabs.
- **Pills & Status Chips:** Fully radiused capsules (`9999px`) for set badges, population indicators, and market change tags.
- **Modals & Bottom Drawers:** `24px` top corner radius for smooth sheet slides.
- **Buttons & Input Fields:** `14px` border radius, balancing tactile thumb interaction with sleek structure.

## Components

### 1. Collector Cards & Acrylic Slabs
- **Structure:** 5:7 aspect ratio container with an explicit `18px` border radius.
- **Surface:** Stacked layers consisting of:
  1. Base artwork / card canvas.
  2. Procedural holographic foil mesh (reacts to device tilt).
  3. Acrylic frosted frame (`rgba(255, 255, 255, 0.04)` overlay).
  4. Perimeter stroke: `1px solid rgba(255, 255, 255, 0.08)`.
- **Grade Badge Overlay:** Floating pill at top right containing the grade numerical rating (e.g., `GEM MT 10`) backed by a frosted glass matrix with gold foil border (`#FFD700`).

### 2. Buttons
- **Primary (Rip Pack / Confirm):** High-energy tactile pill or rounded rectangle (`14px` radius). Filled with a franchise gradient, anchored with an inner bevel highlight (`inset 0 1px 0 rgba(255, 255, 255, 0.40)`) and a subtle ambient outer glow matching the accent color. Heavy font weight (`Outfit`, 700).
- **Secondary (Inspect / Filter):** Glass slab style. Surface `rgba(255, 255, 255, 0.05)`, border `1px solid rgba(255, 255, 255, 0.12)`, text color `#FFFFFF`. On tap, scales down to `0.97` with haptic feedback.
- **Ghost / Utility:** Transparent fill, muted text (`rgba(255, 255, 255, 0.60)`), transitioning to white on interaction.

### 3. Pack Opener Foil Component
- **Surface:** Metallic sheen cylinder with horizontal foil crimp lines at top and bottom.
- **Interaction Strip:** Dotted laser-perforated line across the top with shimmering particle trail prompting a swipe gesture.
- **Tear Behavior:** Custom vector rip path revealing the ambient rim lighting of the top card beneath.

### 4. Input Fields & Search Bars
- **Surface:** Frosted Obsidian `rgba(18, 21, 36, 0.85)` with `14px` border radius and `1px` border of `rgba(255, 255, 255, 0.08)`.
- **Text:** `Plus Jakarta Sans`, 14px, with placeholder text tinted to `rgba(255, 255, 255, 0.35)`.
- **Focus State:** Border transitions smoothly to the active franchise primary accent color with a subtle `0 0 12px rgba(accent, 0.25)` outward halo.

### 5. Chips & Metadata Badges
- **Rarity Badges:** Capsule shape (`9999px`), height `22px`, internal padding `0 8px`. Semi-transparent core matching rarity tier with text set in `Outfit` uppercase `label-sm` (`9px`, weight 800).
- **Set Filters:** Segmented glass pills that fill with full opacity franchise accent when selected.

### 6. Vault Value & Stat Tiles
- **Structure:** Modular neo-glass containers (`16px` radius).
- **Content:** Header label (`label-md`, uppercase, muted), followed by a dominant typographic monetary balance (`headline-lg`, `Outfit`), paired with a trend pill (+12.4% green glass chip).