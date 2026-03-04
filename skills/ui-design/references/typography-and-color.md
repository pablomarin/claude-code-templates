# Typography & Color Reference

## Fluid Typography Scale

```css
:root {
  --text-xs: clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem);
  --text-sm: clamp(0.875rem, 0.8rem + 0.35vw, 1rem);
  --text-base: clamp(1rem, 0.9rem + 0.5vw, 1.125rem);
  --text-lg: clamp(1.125rem, 1rem + 0.65vw, 1.25rem);
  --text-xl: clamp(1.25rem, 1.1rem + 0.8vw, 1.5rem);
  --text-2xl: clamp(1.5rem, 1.2rem + 1.5vw, 2rem);
  --text-3xl: clamp(2rem, 1.5rem + 2.5vw, 3rem);
}
```

Modular scale ratios: 1.25 (major third) or 1.333 (perfect fourth). Line-height: 1.4-1.6 body, 1.1-1.2 headings. Always `font-display: swap` on `@font-face`.

## Font Strategy

| Role        | Usage            | Example                                          |
| ----------- | ---------------- | ------------------------------------------------ |
| **Display** | Hero headlines   | Playfair Display, Cabinet Grotesk, Clash Display |
| **Heading** | Section titles   | Satoshi, General Sans, Sora                      |
| **Body**    | Paragraphs, UI   | Instrument Sans, Plus Jakarta Sans, DM Sans      |
| **Caption** | Labels, metadata | Body font at smaller size                        |

2 families max. Pair distinctive display with refined body. AVOID Inter, Roboto, Arial, Space Grotesk unless brand requires.

## OKLCH Color System

```css
:root {
  --color-primary: oklch(55% 0.25 250);
  --color-primary-light: oklch(70% 0.2 250);
  --color-primary-dark: oklch(40% 0.25 250);
  --color-accent: oklch(65% 0.3 30);
  --color-success: oklch(60% 0.2 145);
  --color-warning: oklch(70% 0.2 80);
  --color-error: oklch(55% 0.25 25);
  --color-neutral-50: oklch(98% 0 0);
  --color-neutral-500: oklch(55% 0.01 250);
  --color-neutral-900: oklch(15% 0 0);
}
```

HSL fallback: `@supports not (color: oklch(0% 0 0)) { }`. Semantic tokens: primary, accent, success, warning, error, neutral. 5-7 base colors, derive shades by adjusting lightness. Bold dominant colors with sharp accents beat timid palettes.

## WCAG Contrast

- **Normal text**: 4.5:1 minimum (WCAG AA)
- **Large text** (18px+) and **UI elements**: 3:1 minimum
- OKLCH helps: equal lightness deltas produce equal visual contrast across hues
- Target AA, aim for AAA (7:1 text, 4.5:1 large)

## Dark Mode

```css
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: oklch(15% 0.01 250);
    --color-surface: oklch(20% 0.01 250);
    --color-text: oklch(90% 0 0);
    --color-primary: oklch(70% 0.2 250);
    --color-accent: oklch(75% 0.25 30);
  }
}
```

Reduce chroma -- don't just invert. Use dark grays (`oklch(15% 0.01 250)` / `#1a1a2e`), never pure black. Raise accent lightness. Test both modes throughout.

## Spacing Scale

4px base: `--space-1: 0.25rem` (4) through `--space-24: 6rem` (96). Steps: 4, 8, 12, 16, 24, 32, 48, 64, 96.

- CSS Grid for page layout, Flexbox for components
- Container max: 1200-1440px, `margin-inline: auto`
- Fluid spacing: `padding: clamp(1rem, 3vw, 3rem)`

## Backgrounds as Atmosphere

**Gradient mesh**: layer `radial-gradient()` at different positions with `background-blend-mode: screen`.

**Noise overlay**: pseudo-element with inline SVG turbulence filter at low opacity (0.03-0.05):

```css
.grain::after {
  content: "";
  position: fixed;
  inset: 0;
  opacity: 0.04;
  pointer-events: none;
  background: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence baseFrequency='0.8'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}
```

**Custom cursors**: `cursor: url('/cursors/custom.svg') 16 16, crosshair` for interactive areas. Use `grab`/`grabbing` for draggables.
