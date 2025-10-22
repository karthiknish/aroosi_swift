# Phase 0 · Design & Asset Inventory

## Brand Foundations
- **Primary palette** (from `lib/theme/colors.dart`):
  - Primary pink `#EC4899` (primary), dark `#BE185D`.
  - Secondary dusty blue `#5F92AC`.
  - Accent muted gold `#D6B27C`.
  - Aurora gradient accents: rose `#FF8FB7`, iris `#A78BFA`, sky `#7DD3FC`, sunset `#FFB98B`.
  - Neutral surfaces: white `#FFFFFF`, secondary surface `#F9F7F5`.
  - Status colors: error `#B45E5E`, success `#7BA17D`, warning `#F59E0B`, info `#3B82F6`.
- **Typography** (`lib/theme/typography.dart`):
  - Headings use custom **Boldonse** typeface (single weight mapped to 400/700).
  - Body copy uses **Nunito Sans** via Google Fonts.
  - Captions reuse Nunito Sans with muted color.
- **Spacing & Motion**: `lib/theme/spacing.dart` and `lib/theme/motion.dart` define grid spacing (4pt scale) and standard animation curves/durations; replicate in Swift as constants.

## Assets Overview (`assets/`)
- **Fonts**: `assets/fonts/Boldonse-Regular.ttf` (only variant shipped). Requires license verification and conversion to `.otf` if needed for iOS asset catalog.
- **Images**: `assets/images/`
  - `placeholder.png` (user avatar fallback).
  - `welcome.jpg` (onboarding hero). `.keep` indicates directory placeholder; expect designers to supply additional illustrations.
- **Localization**: `assets/translations/`
  - `en.json` (English), `fa.json` (Dari), `ps.json` (Pashto). Keys follow snake_case; values include pluralization contexts. Need converter to `.strings` + `.stringsdict`.
- **Icebreaker Data**: `icebreaker_data.json` seeds Firestore (already documented in `data-contracts.md`). Consider transforming to bundled JSON for offline previews.

## Required Exports & Actions
1. Request latest Figma component library (colors, typography, iconography) to align SwiftUI tokens.
2. Obtain vector sources for onboarding/hero imagery (SVG/EPS) for multi-resolution export.
3. Validate Boldonse font licensing for inclusion in App Store binary; acquire woff/otf if necessary.
4. Plan localization pipeline: convert JSON to `Localizable.strings`, maintain source of truth (likely Phrase or in-repo JSON).
5. Audit for additional media (video/audio) referenced elsewhere (`lib/features/islamic_education` downloads remote assets; no bundled media yet).

## Outstanding Questions
- Do we standardize on SF Symbols replacements for certain Flutter icons? Need icon inventory.
- Should gradients be represented via asset catalogs or programmatic SwiftUI gradients? Capture from Flutter `widgets` usage.
- Confirm if dark mode styling exists; current Flutter theme appears light-only.
