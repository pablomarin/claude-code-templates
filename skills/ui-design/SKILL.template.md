---
name: ui-design
description: >
  Design and build visually stunning, production-grade frontend interfaces.
  Use when building web pages, UI components, landing pages, dashboards,
  or any user-facing interface. Ensures every page has visual impact with
  animations, immersive effects, and intentional design — not generic AI output.
---

# UI Design

> Build interfaces that make people say "Wow, this is the best I've seen."

## Step 1: Design Thinking (BEFORE writing code)

Before touching any code, commit to a BOLD aesthetic direction:

1. **Purpose**: What problem does this interface solve? Who uses it?
2. **Tone**: Pick a specific aesthetic — don't settle for "modern and clean":
   - Brutally minimal | Maximalist chaos | Retro-futuristic | Organic/natural
   - Luxury/refined | Playful/toy-like | Editorial/magazine | Brutalist/raw
   - Art deco/geometric | Soft/pastel | Industrial/utilitarian | Cyberpunk
   - Dark OLED luxury | SaaS minimal | Bento grid | Spatial UI
3. **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?
4. **Constraints**: Framework, performance budget, accessibility requirements

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work — the key is intentionality, not intensity.

## Step 2: Anti-AI-Slop Rules (MANDATORY)

**Font defaults to AVOID** — Do not reach for: Inter, Roboto, Arial, Space Grotesk, system-ui defaults.
Choose distinctive, characterful fonts instead. Pair a display font with a refined body font.
(Exception: if the project has an established brand/design system that requires specific fonts, use those.)

**Patterns to AVOID** — Do not produce:

- Purple gradients on white backgrounds
- Evenly-padded card grids with identical rounded corners
- Generic hero sections with centered text and a gradient button
- Cookie-cutter component library defaults (unstyled Bootstrap, default shadcn)

**Anti-convergence** — No two designs should look the same. Vary between light and dark themes, different fonts, different aesthetics. NEVER converge on common choices across generations.

## Step 3: Animation Priorities (MANDATORY)

Every page MUST include at least one dynamic visual element. Static rectangles are drafts.

| Section                    | Recommended Effect                                          |
| -------------------------- | ----------------------------------------------------------- |
| Hero / Above the fold      | WebGL shader gradient OR animated SVG waves + Lottie accent |
| Section dividers           | Animated SVG wave paths (2-3 layers)                        |
| Feature cards              | Spring entrance animations + hover transforms               |
| Icons & micro-interactions | Lottie animations or CSS transitions                        |
| Backgrounds                | Canvas particle noise OR subtle CSS gradient animation      |
| Loading / empty states     | Lottie with branded animation                               |
| Page transitions           | Orchestrated staggered reveals (animation-delay)            |

**High-impact rule**: One well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions. Focus on scroll-triggering and surprising hover states.

**Animation with purpose**: If you can't explain why an animation exists, remove it. Motion should guide attention, provide feedback, or create delight — never just decorate.

## Step 4: Spatial Composition

Don't default to symmetric grids:

- **Asymmetry** — intentional visual weight imbalance
- **Overlap** — elements breaking out of their containers
- **Diagonal flow** — guide the eye with angled elements
- **Grid-breaking** — key elements that escape the grid for emphasis
- **Negative space** — generous whitespace OR controlled density (commit to one)

## Step 5: Backgrounds & Atmosphere

Avoid plain solid-color backgrounds when possible. Create depth:

- Gradient meshes and CSS gradient animations
- Noise textures and grain overlays
- Geometric patterns and layered transparencies
- Dramatic shadows and decorative borders
- Custom cursors for interactive sections

## Step 6: Implementation

For detailed implementation techniques, consult these references:

- **Animations & effects** → See `references/animation-techniques.md` for SVG waves, Lottie, WebGL, canvas particles, Framer Motion spring presets, GSAP, stagger patterns, form shake keyframes
- **Typography & color** → See `references/typography-and-color.md` for fluid clamp() scale, OKLCH color tokens, font pairing, dark mode, CSS custom properties
- **Post-build polish** → See `references/polish-checklist.md` for quality audit before delivery

## Step 7: Final Check

Before delivering ANY UI work, verify:

1. Does it look **intentionally designed** or generated? If it looks like AI output, redo it.
2. Is there at least one **dynamic visual element** (animation, gradient, particles, motion)?
3. Are fonts **distinctive** (not generic defaults)?
4. Does the color palette have **dominant colors with sharp accents** (not timid, evenly-distributed)?
5. Does it **respect `prefers-reduced-motion`** and meet WCAG AA contrast?
6. Run through `references/polish-checklist.md`
