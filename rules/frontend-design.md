---
paths:
  - "**/*.{ts,tsx,js,jsx}"
  - "**/*.{css,scss}"
  - "**/*.html"
---

# Frontend Design Baseline

## Non-Negotiable Standards

- Semantic HTML first: `<nav>`, `<main>`, `<article>`, `<button>`, `<dialog>`
- WCAG AA contrast: 4.5:1 text, 3:1 large text/UI elements
- `prefers-reduced-motion` respected on ALL animations
- `prefers-color-scheme` respected for light/dark
- Mobile-first responsive: test 320px, 375px, 768px, 1024px, 1440px
- Focus styles on all interactive elements (`:focus-visible` ring/outline)
- No placeholder-only labels on form inputs
- Images: `alt` text, explicit `width`/`height`, WebP/AVIF with fallbacks
- Social metadata: `favicon.ico`, `apple-icon.png`, `icon.svg`, `opengraph-image.png` (1200x630), `metadataBase`, OpenGraph + Twitter card in root layout — **every deployed site, no exceptions**

## Design Standard

Every page must look **intentionally designed**, not generated.
Static rectangles are drafts, not finished work.

NEVER deliver generic Bootstrap/template aesthetics. If it looks like AI slop, it's not done.

## Full Design Guidance

The `/ui-design` skill provides complete design direction — creative process,
animation techniques, typography, color systems, and a post-build polish checklist.
It auto-triggers when building UI, or invoke manually with `/ui-design`.
