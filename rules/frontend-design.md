# Frontend Design Quality

## Core Principle
Build interfaces that look **intentionally designed**, not generated. Avoid the "AI slop" aesthetic: generic gradients, oversized padding, placeholder-quality layouts, and cookie-cutter component libraries.

## Typography
- Establish a clear type hierarchy: display, heading, subheading, body, caption
- Use font size ratios (e.g., 1.25 or 1.333 modular scale) — not arbitrary sizes
- Limit to 2 font families max. Prefer system fonts or well-paired Google Fonts
- Set line-height: 1.4–1.6 for body text, 1.1–1.2 for headings
- Use `font-display: swap` for web fonts

## Color
- Define a semantic color system: primary, secondary, accent, success, warning, error, neutral
- Use HSL for color manipulation — consistent saturation and lightness across the palette
- Ensure WCAG AA contrast ratios (4.5:1 text, 3:1 large text/UI elements)
- Dark mode: reduce saturation, don't just invert. Use dark grays (#1a1a2e) not pure black (#000)
- Limit to 5–7 colors. Derive shades/tints from base colors (50–950 scale)

## Spacing & Layout
- Use a consistent spacing scale (4px base: 4, 8, 12, 16, 24, 32, 48, 64, 96)
- CSS Grid for page layout, Flexbox for component layout
- Respect content density — don't over-pad. White space should feel intentional
- Container max-width: 1200–1440px for content, with responsive padding

## Responsive Design
- Mobile-first: start with the smallest viewport, add complexity via `min-width` breakpoints
- Breakpoints: 640px (sm), 768px (md), 1024px (lg), 1280px (xl)
- Use `clamp()` for fluid typography: `font-size: clamp(1rem, 0.5rem + 1.5vw, 1.5rem)`
- Test at 320px, 375px, 768px, 1024px, 1440px minimum
- Touch targets: minimum 44x44px on mobile

## Components
- Interactive elements must have visible focus states (outline, ring, not just color change)
- Buttons: clear hierarchy (primary solid, secondary outline, tertiary ghost)
- Forms: labels always visible (no placeholder-only labels), clear error states, inline validation
- Cards: consistent border radius, subtle shadows (avoid heavy drop-shadows)
- Loading: use skeletons over spinners for content areas

## Animation & Motion
- Use `prefers-reduced-motion` media query — always provide a reduced alternative
- Keep transitions under 300ms for UI feedback, 500ms max for layout shifts
- Ease functions: `ease-out` for entrances, `ease-in` for exits, `ease-in-out` for transitions
- Animate transforms and opacity (GPU-accelerated), not width/height/margin

## Accessibility
- Semantic HTML first: `<nav>`, `<main>`, `<article>`, `<button>`, `<dialog>`
- All images need `alt` text (decorative images: `alt=""`)
- `aria-label` for icon-only buttons
- Keyboard navigation: all interactive elements focusable and operable
- Skip navigation link for keyboard users
- Color is never the only indicator — pair with icons, text, or patterns

## Performance
- Optimize images: WebP/AVIF with `<picture>` fallbacks, explicit `width`/`height`
- Lazy load below-fold images and heavy components
- Critical CSS inlined, non-critical deferred
- `will-change` only when animating, remove after

## Rules
1. ALWAYS use semantic HTML elements before reaching for divs
2. ALWAYS include focus styles for interactive elements
3. ALWAYS test responsive layouts at mobile, tablet, and desktop breakpoints
4. ALWAYS respect `prefers-reduced-motion` and `prefers-color-scheme`
5. NEVER use placeholder text as the only label for form inputs
6. NEVER use color alone to convey information
7. PREFER CSS custom properties (variables) for theming over hardcoded values
8. PREFER native CSS features (`gap`, `clamp()`, `container queries`) over JS-based layout
