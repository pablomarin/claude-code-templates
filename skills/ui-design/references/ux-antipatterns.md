# UX Anti-Patterns

> Design-time reasoning guide. Catch these BEFORE building, not during QA.
> For post-build verification, use `polish-checklist.md` instead.
>
> Last reviewed: 2026-03-12

---

## Navigation

| Issue                  | Do                                              | Don't                                        | Code Example                          |
| ---------------------- | ----------------------------------------------- | -------------------------------------------- | ------------------------------------- |
| **Smooth scroll**      | `html { scroll-behavior: smooth; }`             | Jump directly without transition             | `scroll-behavior: smooth` on `<html>` |
| **Sticky nav overlap** | Add `padding-top` equal to nav height           | Let nav overlap first section content        | `pt-20` if nav is `h-20`              |
| **Active state**       | Highlight current nav item with color/underline | No visual feedback on current location       | `text-primary border-b-2` on active   |
| **Back button**        | Preserve navigation history with `pushState`    | Break browser back with `location.replace()` | `history.pushState()`                 |
| **Breadcrumbs**        | Use for sites with 3+ depth levels              | Use for flat single-level sites              | `Home > Category > Product`           |
| **Deep linking**       | Update URL on state/view changes                | Static URLs for dynamic content              | Use query params or hash for state    |

## Animation & Motion

| Issue                    | Do                                         | Don't                                    | Why                                            |
| ------------------------ | ------------------------------------------ | ---------------------------------------- | ---------------------------------------------- |
| **Excessive motion**     | Animate 1-2 key elements per view max      | Animate everything on screen             | Causes distraction and motion sickness         |
| **Duration**             | 150-300ms for micro-interactions           | > 500ms for UI transitions               | Users perceive > 300ms as sluggish             |
| **Reduced motion**       | Check `prefers-reduced-motion` media query | Ignore accessibility motion settings     | Required for WCAG 2.1 AA                       |
| **Hover vs tap**         | Use click/tap for primary interactions     | Rely only on hover for important actions | Hover doesn't exist on touch devices           |
| **Continuous animation** | Only for loading indicators                | Decorative infinite animations           | `animate-bounce` on icons is distracting       |
| **GPU properties**       | Animate `transform` and `opacity` only     | Animate `width`, `height`, `top`, `left` | Non-GPU properties trigger expensive repaints  |
| **Easing**               | `ease-out` for enter, `ease-in` for exit   | `linear` for UI transitions              | Linear motion feels robotic                    |
| **Loading states**       | Skeleton screens or spinners               | Frozen UI with no feedback               | Users assume broken after 300ms of no response |

## Layout

| Issue                     | Do                                              | Don't                                    | Code Example                                 |
| ------------------------- | ----------------------------------------------- | ---------------------------------------- | -------------------------------------------- |
| **Z-index management**    | Define a scale system (10, 20, 30, 50)          | Use arbitrary large values               | `z-10 z-20 z-50` not `z-[9999]`              |
| **Content jumping (CLS)** | Reserve space for async content                 | Let images/content push layout around    | `aspect-ratio` or explicit `width`/`height`  |
| **Viewport units mobile** | Use `dvh` or account for browser chrome         | Use `100vh` for full-screen mobile       | `min-h-dvh` not `h-screen` on mobile         |
| **Reading width**         | Limit text to 65-75 characters                  | Let text span full viewport              | `max-w-prose` or `max-w-3xl`                 |
| **Overflow hidden**       | Test all content fits, use `overflow-auto`      | Blindly apply `overflow-hidden`          | `overflow-auto` with scrollbar, not clipping |
| **Fixed stacking**        | Account for safe areas and other fixed elements | Stack multiple fixed elements carelessly | Gap between fixed nav and fixed bottom bar   |

## Touch & Mobile

| Issue                 | Do                                     | Don't                             | Code Example                                             |
| --------------------- | -------------------------------------- | --------------------------------- | -------------------------------------------------------- |
| **Touch target size** | Minimum 44x44px (48px preferred)       | Tiny clickable areas              | `min-h-[44px] min-w-[44px]` not `w-6 h-6`                |
| **Touch spacing**     | Minimum 8px gap between targets        | Tightly packed clickable elements | `gap-2` between buttons, not `gap-0`                     |
| **Tap delay**         | Use `touch-action: manipulation`       | Default 300ms tap delay           | CSS `touch-action: manipulation` on interactive elements |
| **Pull to refresh**   | Disable where not needed               | Enable by default everywhere      | `overscroll-behavior: contain`                           |
| **Gesture conflicts** | Avoid horizontal swipe on main content | Override system gestures          | Vertical scroll as primary axis                          |
| **Safe areas**        | Respect `env(safe-area-inset-*)`       | Ignore notch/home indicator       | `padding-bottom: env(safe-area-inset-bottom)`            |

## Interaction States

Every interactive element needs ALL of these:

| State        | Implementation                               | Anti-pattern                                      |
| ------------ | -------------------------------------------- | ------------------------------------------------- |
| **Hover**    | Subtle transform or color shift              | No hover feedback on clickable elements           |
| **Focus**    | Visible ring via `:focus-visible`            | Removing `outline: none` without replacement      |
| **Active**   | Pressed feedback (`active:scale-95`)         | No feedback during interaction                    |
| **Disabled** | `opacity-50 cursor-not-allowed`              | Same style as enabled state                       |
| **Loading**  | Disable button + show spinner                | Button clickable while processing (double-submit) |
| **Error**    | Red border + descriptive message below input | Silent failure with no feedback                   |
| **Success**  | Toast notification or checkmark              | Action completes silently                         |
| **Empty**    | Helpful guidance message                     | Blank screen with no explanation                  |

## Forms

| Issue                    | Do                                           | Don't                                      | Why                                               |
| ------------------------ | -------------------------------------------- | ------------------------------------------ | ------------------------------------------------- |
| **Labels**               | Always show visible label above/beside input | Placeholder as only label                  | Placeholder disappears on focus, breaking context |
| **Error placement**      | Show error below the related input           | Single error message at top of form        | Users can't connect error to field                |
| **Inline validation**    | Validate on blur for most fields             | Validate only on submit                    | Faster feedback loop reduces frustration          |
| **Input types**          | Use `email`, `tel`, `number`, `url`          | `type="text"` for everything               | Correct types trigger right mobile keyboards      |
| **Required indicators**  | `*` asterisk or "(required)" text            | No indication of which fields are required | Users guess wrong, get frustrated                 |
| **Autofill**             | Use `autocomplete` attribute properly        | `autocomplete="off"` everywhere            | Blocks browser autofill, slows users down         |
| **Confirmation dialogs** | Confirm before destructive actions (delete)  | Direct delete on single click              | Accidental data loss is irreversible              |

## Accessibility

| Issue                   | Do                                             | Don't                                        | Severity |
| ----------------------- | ---------------------------------------------- | -------------------------------------------- | -------- |
| **Color contrast**      | 4.5:1 normal text, 3:1 large text/UI           | Low contrast text (#999 on white = 2.8:1)    | High     |
| **Color-only info**     | Icons + text in addition to color              | Red/green only for error/success             | High     |
| **Alt text**            | Descriptive alt for meaningful images          | Empty or missing alt on content images       | High     |
| **Heading hierarchy**   | Sequential h1 → h2 → h3                        | Skip levels (h1 → h4) or use for styling     | Medium   |
| **ARIA labels**         | `aria-label` on all icon-only buttons          | `<button><Icon/></button>` with no label     | High     |
| **Keyboard nav**        | All interactive elements focusable via Tab     | Keyboard traps or illogical tab order        | High     |
| **Screen reader**       | Semantic HTML (`<nav>`, `<main>`, `<article>`) | Div soup with no semantics                   | Medium   |
| **Skip links**          | "Skip to main content" link                    | 100+ tabs to reach content                   | Medium   |
| **Decorative elements** | `aria-hidden="true"` on animations/particles   | Screen reader announces decorative SVG waves | Medium   |

## Performance

| Issue                     | Do                                        | Don't                                       | Impact                             |
| ------------------------- | ----------------------------------------- | ------------------------------------------- | ---------------------------------- |
| **Image optimization**    | Appropriate size + WebP/AVIF format       | Unoptimized 4000px images for 400px display | High — largest cause of slow pages |
| **Lazy loading**          | `loading="lazy"` on below-fold images     | Load everything upfront                     | Medium — saves initial bandwidth   |
| **Font loading**          | `font-display: swap` or `optional`        | Invisible text during font load (FOIT)      | Medium — blocks first paint        |
| **Third-party scripts**   | Load non-critical scripts `async`/`defer` | Synchronous third-party in `<head>`         | Medium — blocks rendering          |
| **Bundle size**           | Monitor with bundle analyzer              | Ignore growth over time                     | Medium — affects TTI               |
| **`will-change`**         | Set before animation, remove after        | Leave `will-change` permanently on elements | Low — wastes GPU memory            |
| **Off-screen animations** | Pause with `IntersectionObserver`         | Canvas/WebGL running when not visible       | Medium — drains battery            |
