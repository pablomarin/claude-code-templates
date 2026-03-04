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

## Step 3: Visual Impact Requirements (MANDATORY)

Static pages are drafts. Every page needs **visible, impressive motion** — not subtle micro-animations that nobody notices.

### Minimum requirements for any page:

1. **Hero section MUST have high-impact motion** — canvas particle network, WebGL shader gradient, OR layered animated SVG waves. NOT just subtle blurs or tiny floating dots. The hero is the first thing users see — it must create a "wow" moment.
2. **Section dividers MUST be animated SVG waves** (2-3 layers at different speeds) — NOT flat lines or 1px borders. This is a default, not an option.
3. **At least one interactive element** that responds to mouse position or scroll — particle connections that light up on hover, parallax layers, cursor-following effects, or scroll-triggered reveals.
4. **Feature cards MUST have spring entrance animations** + hover transforms (scale, shadow, glow).
5. **Staggered page load** — elements reveal in sequence with `animation-delay`, not all at once.

### Default effects by section:

| Section                    | Default Implementation (not optional)                          |
| -------------------------- | -------------------------------------------------------------- |
| Hero / Above the fold      | Canvas particle network OR WebGL shader gradient (HIGH IMPACT) |
| Section dividers           | Animated SVG wave paths (2-3 layers, different speeds)         |
| Feature cards              | Spring entrance + hover scale/glow transforms                  |
| Icons & micro-interactions | Lottie animations or animated SVG transitions                  |
| Backgrounds                | Animated gradient, grid pattern overlay, or particle noise     |
| Loading / empty states     | Lottie or skeleton with shimmer animation                      |
| Page transitions           | Orchestrated staggered reveals (animation-delay)               |
| Data flows / connections   | Animated dashed strokes, pulsing glow dots, flowing paths      |

### "Too Subtle" anti-pattern (AVOID):

These technically count as "animation" but create ZERO visual impact:

- Tiny floating dots that blur away to nothing
- Barely-visible opacity pulses (0.9 → 1.0)
- Microscopic blur circles in the background
- Single-pixel animated borders
- Animations that only trigger on hover with no idle state

**If a user has to squint to notice the animation, it's too subtle. Redo it.**

**High-impact rule**: One well-orchestrated page load with staggered reveals + an interactive hero creates more delight than 20 subtle micro-animations. Focus on: canvas particles in hero, SVG wave dividers, scroll-triggered card entrances, and flowing data connections.

**Animation with purpose**: Every animation should either (a) create a "wow" first impression, (b) guide attention to important content, (c) provide interaction feedback, or (d) show data/state relationships. If it does none of these, remove it.

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

## Step 6: Real Media Assets (NOT Placeholders)

Never leave `<img>` tags with placeholder URLs or gray boxes. Use real images during development:

- **Stock photography** → Use Pexels/Unsplash MCP to search for contextual photos (team meetings, office environments, product shots). Pick images that match your aesthetic tone.
- **AI-generated imagery** → Use Nano Banana MCP or similar to generate custom hero images, illustrations, and visual assets that match your brand exactly.
- **Optimize everything** → WebP/AVIF format, explicit `width`/`height`, responsive `srcset`, lazy-load below fold.

See `references/media-assets.md` for prompting best practices, common image sizes, and workflow patterns.

## Step 7: Implementation References

For detailed implementation techniques, consult these references:

- **Animations & effects** → See `references/animation-techniques.md` for SVG waves, Lottie, WebGL, canvas particles, Framer Motion spring presets, GSAP, stagger patterns, form shake keyframes
- **Typography & color** → See `references/typography-and-color.md` for fluid clamp() scale, OKLCH color tokens, font pairing, dark mode, CSS custom properties
- **Media assets** → See `references/media-assets.md` for image generation prompting, stock photo selection, common sizes, and optimization
- **Post-build polish** → See `references/polish-checklist.md` for quality audit before delivery

## Step 8: Final Check

Before delivering ANY UI work, verify:

1. Does it look **intentionally designed** or generated? If it looks like AI output, redo it.
2. Does the **hero section have high-impact motion** (canvas particles, WebGL gradient, or layered SVG waves)? If it's static or has barely-visible effects, redo it.
3. Are **section dividers animated SVG waves** (not flat lines)?
4. Is there at least one **interactive element** (responds to mouse or scroll)?
5. Are fonts **distinctive** (not generic defaults)?
6. Does the color palette have **dominant colors with sharp accents** (not timid, evenly-distributed)?
7. Would a **non-technical person say "wow"** when the page loads? If not, add more visual impact.
8. Are images **real** (stock photos or AI-generated), not placeholder boxes or gray rectangles?
9. Does it **respect `prefers-reduced-motion`** and meet WCAG AA contrast?
10. Run through `references/polish-checklist.md`
