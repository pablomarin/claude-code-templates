# Animation Techniques Reference

## Organic Shapes

Break out of rectangles with organic, fluid forms:

- **SVG paths** with cubic bezier curves (`C` commands) for smooth, flowing outlines
- **CSS clip-path**: `clip-path: polygon()` for geometric cuts, `clip-path: url(#svg-id)` for complex organic masks
- **Blob shapes**: randomize bezier control points for unique, non-repeating forms
- **Asymmetric border-radius**: `border-radius: 30% 70% 70% 30% / 30% 30% 70% 70%` for organic card shapes
- **Layered depth**: stack shapes with z-index and negative margins for dimensional composition

## Animated SVG Waves

Use layered `<path>` elements with sinusoidal shapes at different amplitudes:

- Animate the `d` attribute via Framer Motion or CSS `@keyframes` for morphing wave shapes
- 2-3 wave layers at different speeds and opacities create parallax depth
- Use as section dividers instead of straight lines
- SVG path morphing works for state transitions (hamburger to close icon, play to pause)

## Lottie Animations

| Library                            | Size   | Best for                                |
| ---------------------------------- | ------ | --------------------------------------- |
| `lottie-react`                     | ~8KB   | Simple integrations                     |
| `@lottiefiles/react-lottie-player` | ~15KB  | Full control, events                    |
| `DotLottieWorker`                  | varies | Heavy animations (Web Worker rendering) |

- Use for: icon transitions, loading states, hero accents, onboarding flows
- Always set `autoplay`, control `speed`, handle `onComplete` callback
- Render as `<canvas>` when displaying multiple Lotties on one page
- Prefer **dotLottie format** — 90% smaller than JSON Lottie files
- Lazy load with `IntersectionObserver` — don't load animations below the fold

## WebGL Shader Gradients

- `@shadergradient/react` for quick gradient meshes (Stripe/Linear-style effects)
- `react-three-fiber` + custom GLSL for full creative control
- **ALWAYS** provide a CSS gradient fallback for unsupported browsers/devices
- Wrap in `<Suspense>` with a static gradient fallback while Three.js loads (~150KB)

```jsx
<Suspense fallback={<div className="gradient-fallback" />}>
  <ShaderGradient />
</Suspense>
```

## Canvas Particles

- `tsparticles` for ready-made configs, or custom Canvas API + `requestAnimationFrame`
- **Perlin noise** fields create organic, flowing motion (not random jitter)
- Interactive: respond to mouse position with attract/repel forces
- Count limits for 60fps: **under 200 on mobile**, **500 max on desktop**
- Always `cancelAnimationFrame` and remove event listeners on unmount

## Framer Motion Patterns

### Spring Presets (use exact values)

| Preset | stiffness | damping | Use case                      |
| ------ | --------- | ------- | ----------------------------- |
| Gentle | 120       | 14      | Page entrances, modals        |
| Wobbly | 180       | 12      | Playful UI, notifications     |
| Stiff  | 300       | 20      | Snappy interactions, toggles  |
| Slow   | 50        | 15      | Background elements, parallax |

### Key Patterns

- **Orchestrated lists**: `staggerChildren` on parent variant + `variants` on children for cascading reveals
- **Shared transitions**: `layoutId` on source and target for seamless element morphing (tab underline, thumbnail to modal)
- **Scroll-triggered**: `whileInView` with `viewport={{ once: true, amount: 0.8 }}` — fires once when 80% visible
- **Form error shake**: `animate={{ x: [0, -10, 10, -10, 10, 0] }}` with `transition={{ duration: 0.4 }}`
- **Accessibility**: `useReducedMotion()` hook — skip or simplify animations when user prefers reduced motion

## GSAP Patterns

- **ScrollTrigger toggleActions**: four-state matrix (`onEnter onLeave onEnterBack onLeaveBack`) — e.g., `"play pause resume reset"`
- **ScrollTrigger.batch**: animate groups of DOM elements together as they enter the viewport
- **will-change lifecycle**: set via GSAP `onStart` callback, remove via `onComplete` — **NEVER leave permanently** (causes layer promotion and memory waste)
- **Scrub animations**: use `ease: "none"` for linear scroll-linked motion (easing fights the scroll)
- **Prevent flash**: `immediateRender: false` on `fromTo` tweens so initial state doesn't render before scroll position is calculated

## Device Capability Detection

```javascript
const isLowEnd = navigator.hardwareConcurrency < 4;
const prefersReduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
```

**Degradation tiers:**

| Tier    | Condition                   | Animation level                    |
| ------- | --------------------------- | ---------------------------------- |
| Full    | High-end + no preference    | WebGL, particles, springs          |
| Reduced | Low-end OR prefers-reduced  | CSS transitions only, no particles |
| None    | Low-end AND prefers-reduced | No animation, static fallbacks     |

## Performance & Accessibility Guards

1. **prefers-reduced-motion**: ALL effects MUST respect it — disable animation, show static fallback
2. **Off-screen pause**: WebGL/Canvas use `IntersectionObserver` to stop rendering when not visible
3. **Lazy-load heavy libs**: `import()` for Three.js, tsparticles — never in the critical bundle
4. **CPU test**: throttle CPU 4x in DevTools, verify 30fps minimum on animated pages
5. **Decorative elements**: `aria-hidden="true"` on all animated elements that convey no meaning
6. **GPU-only properties**: animate ONLY `transform` and `opacity` — never `width`, `height`, `margin`, `top`, `left`
