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

## Visual Design & Immersive UI

**Core philosophy:** Interfaces should feel alive. Static rectangles are drafts, not designs. Every landing page, hero section, and key visual moment should include at least one dynamic element.

### Organic Shapes Over Rectangles
- Use SVG `<path>` elements with cubic bezier curves for section dividers, backgrounds, and decorative shapes
- Use CSS `clip-path: polygon()` or `clip-path: url(#svg-id)` for non-rectangular sections
- Blob shapes: generate organic blobs with randomized bezier control points, not perfect circles
- Border radius: use asymmetric values (`border-radius: 30% 70% 70% 30% / 30% 30% 70% 70%`) for organic feel
- Layered depth: overlap sections with `z-index` and negative margins for visual flow

### Animated SVG Waves & Morphing (Framer Motion / CSS)
- Create layered SVG `<path>` elements with sinusoidal wave shapes at different amplitudes
- Animate the `d` attribute between wave forms using Framer Motion's `animate` or CSS `@keyframes`
- Use 2-3 wave layers at different speeds and opacities for parallax depth
- Wave dividers between sections instead of straight horizontal lines
- SVG path morphing for state transitions (e.g., menu icon → close icon)

### Lottie Animations
- Library: `lottie-react` (~8KB) or `@lottiefiles/react-lottie-player`
- Use for: icon transitions, loading states, hero background accents, onboarding illustrations
- Source animations from [LottieFiles](https://lottiefiles.com) or create custom in After Effects
- Always set `autoplay`, control `speed`, and handle `onComplete` for sequenced animations
- Render as `<canvas>` (not SVG) for performance when multiple Lotties are on screen

### WebGL Shader Gradients (Hero/Marketing Sections)
- Library: `@shadergradient/react` for quick gradient meshes, or `react-three-fiber` + custom GLSL for full control
- Use for: hero backgrounds, pricing section accents, feature showcases
- Implement flowing color blobs that morph in real time (like Stripe.com, Linear.app)
- Always provide a CSS gradient fallback for browsers without WebGL support
- Wrap in `<Suspense>` with a static gradient fallback while Three.js loads (~150KB)

### Canvas Particles & Noise
- Library: `tsparticles` for ready-made configs, or custom Canvas API with `requestAnimationFrame`
- Perlin noise fields for organic, flowing particle motion
- Interactive: respond to mouse position (attract/repel particles on hover)
- Keep particle count under 200 on mobile, 500 on desktop for 60fps
- Always `cancelAnimationFrame` and remove event listeners on component unmount

### Animation Priorities by Section
| Section | Recommended Effect |
|---|---|
| Hero / Above the fold | WebGL shader gradient OR animated SVG waves + Lottie accent |
| Section dividers | Animated SVG wave paths (2-3 layers) |
| Feature cards | Framer Motion spring entrance + hover transforms |
| Icons & micro-interactions | Lottie animations |
| Backgrounds | Canvas particle noise OR subtle CSS gradient animation |
| Loading / empty states | Lottie with branded animation |

### Performance & Accessibility Guards
- All visual effects MUST respect `prefers-reduced-motion`: disable animation, show static fallback
- WebGL/Canvas effects: use `IntersectionObserver` to pause when off-screen
- Lazy-load heavy libraries (Three.js, tsparticles) with dynamic `import()` — never in the critical bundle
- Test on low-end devices: throttle CPU 4x in DevTools, ensure 30fps minimum
- Provide `aria-hidden="true"` on all decorative animated elements

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
