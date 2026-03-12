# Landing Page Conversion Patterns

> Section sequencing, CTA hierarchy, and conversion structure for landing pages.
> Use this during Step 1 (Design Thinking) when building any landing page or marketing site.
>
> Last reviewed: 2026-03-12

---

## Pattern Selection

Choose based on your primary conversion goal:

| Goal                   | Recommended Pattern        | Why                               |
| ---------------------- | -------------------------- | --------------------------------- |
| SaaS signups           | Hero + Features + CTA      | Clear value prop → proof → action |
| Lead generation        | Lead Magnet + Form         | Offer value in exchange for email |
| Product launch         | Waitlist / Coming Soon     | Scarcity + anticipation           |
| E-commerce             | Product Showcase + Reviews | Visual proof + social proof       |
| B2B / Enterprise       | Trust & Authority + Demo   | Credentials before ask            |
| Event registration     | Event Landing + Countdown  | Urgency drives registration       |
| Content / Newsletter   | Content-First + Subscribe  | Show value before asking          |
| App download           | App Store Landing          | Device mockups + ratings          |
| Comparison / Switching | Before-After + Comparison  | Visual proof of difference        |

---

## Core Patterns

### 1. Hero + Features + CTA (Most common)

```
┌─────────────────────────────────┐
│  Hero: Headline + Visual + CTA  │  ← Primary CTA above fold
├─────────────────────────────────┤
│  Value proposition strip        │
├─────────────────────────────────┤
│  Feature cards (3-5 max)        │  ← Hover lift + scroll reveal
├─────────────────────────────────┤
│  Social proof / logos           │
├─────────────────────────────────┤
│  Final CTA section              │  ← Repeat primary CTA
└─────────────────────────────────┘
```

**CTA placement:** Hero (sticky nav) + bottom. Repeat CTA at least twice.
**Color:** Brand primary hero, card bg `#FAFAFA`, CTA contrasting accent (7:1+ contrast).
**Best for:** SaaS, tools, platforms.

### 2. Hero + Social Proof + CTA

```
┌─────────────────────────────────┐
│  Hero: Problem headline + CTA   │
├─────────────────────────────────┤
│  Problem statement              │
├─────────────────────────────────┤
│  Solution overview              │
├─────────────────────────────────┤
│  Testimonials carousel (3-5)    │  ← Photo + name + role required
├─────────────────────────────────┤
│  CTA (post-testimonials)        │  ← Social proof BEFORE final CTA
└─────────────────────────────────┘
```

**Key insight:** Place social proof BEFORE the final CTA — never after.
**Testimonials:** Always include photo, full name, and role/company. Anonymous quotes have near-zero impact.

### 3. Pricing-Focused Landing

```
┌─────────────────────────────────┐
│  Hero: Value prop headline      │
├─────────────────────────────────┤
│  Pricing cards (3 tiers)        │  ← Highlight "most popular" mid-tier
├─────────────────────────────────┤
│  Feature comparison table       │
├─────────────────────────────────┤
│  FAQ accordion                  │  ← Address objections here
├─────────────────────────────────┤
│  Final CTA                      │
└─────────────────────────────────┘
```

**Pricing rules:**

- Pre-select/highlight the recommended plan ("Most Popular" badge)
- Show annual discount (20-30%) with toggle animation
- Use FAQ to address pricing objections
- Free tier: grey. Starter: blue. Pro: green/gold. Enterprise: dark

### 4. Waitlist / Coming Soon

```
┌─────────────────────────────────┐
│  Hero: Countdown + Email form   │  ← Email capture above fold
├─────────────────────────────────┤
│  Product teaser / preview       │
├─────────────────────────────────┤
│  Social proof (waitlist count)  │  ← "Join 12,847 others"
├─────────────────────────────────┤
│  Early access benefits          │
└─────────────────────────────────┘
```

**Conversion drivers:** Scarcity ("limited spots"), social proof (waitlist count), exclusivity ("early access benefits"), referral program.

### 5. Trust & Authority (B2B / Enterprise)

```
┌─────────────────────────────────┐
│  Hero: Mission/video + CTA      │
├─────────────────────────────────┤
│  Client logos strip             │  ← "Trusted by" social proof
├─────────────────────────────────┤
│  Solutions by industry/role     │  ← Path selection: "I am a..."
├─────────────────────────────────┤
│  Case study highlights          │
├─────────────────────────────────┤
│  Contact Sales CTA              │
└─────────────────────────────────┘
```

**Enterprise rules:** Contact Sales (primary) + Login (secondary). Mega menu navigation. Trust signals prominent. Conservative palette (navy/grey). Security badges visible.

### 6. Scroll-Triggered Storytelling

```
┌─────────────────────────────────┐
│  Intro hook                     │
├─────────────────────────────────┤
│  Chapter 1: The problem         │  ← Distinct color per chapter
├─────────────────────────────────┤
│  Chapter 2: The journey         │  ← Mini-CTA at each chapter end
├─────────────────────────────────┤
│  Chapter 3: The solution        │
├─────────────────────────────────┤
│  Climax CTA                     │  ← Strongest CTA after full story
└─────────────────────────────────┘
```

**Key insight:** Narrative increases time-on-page 3x. Use progress indicator. Provide skip option for impatient users. Simplify animations on mobile.

### 7. App Store Landing

```
┌─────────────────────────────────┐
│  Hero: Device mockup + rating   │
├─────────────────────────────────┤
│  Screenshot carousel            │  ← Real screenshots in device frames
├─────────────────────────────────┤
│  Features with icons            │
├─────────────────────────────────┤
│  Reviews/ratings (4.5+ stars)   │
├─────────────────────────────────┤
│  Download CTAs (App Store + GP) │  ← QR code for mobile
└─────────────────────────────────┘
```

### 8. Before-After Transformation

```
┌─────────────────────────────────┐
│  Hero: Problem state            │
├─────────────────────────────────┤
│  Transformation slider/compare  │  ← Interactive slider comparison
├─────────────────────────────────┤
│  How it works (3 steps)         │
├─────────────────────────────────┤
│  Results + metrics              │  ← Specific numbers, not vague claims
├─────────────────────────────────┤
│  CTA with guarantee             │
└─────────────────────────────────┘
```

**Key insight:** Visual proof of value. 45% higher conversion than text-only claims. Use real results with specific metrics. Include money-back guarantee.

---

## CTA Hierarchy Rules

1. **One primary CTA per page** — don't split attention between "Sign Up" and "Learn More" equally
2. **Repeat the primary CTA** at least twice: hero + end of page (sticky nav optional)
3. **CTA contrast ratio** must be 7:1+ against its background — it should be the most visible element
4. **CTA copy** should state the benefit, not the action: "Start Free Trial" > "Submit" > "Click Here"
5. **Secondary CTAs** (Learn More, Watch Demo) use ghost/outline style — clearly subordinate
6. **Sticky CTA** in nav for long pages — but only after the hero CTA has scrolled out of view
7. **Bottom-right** placement for floating CTAs — matches natural reading flow (F-pattern)

## Conversion Optimization Checklist

- [ ] Primary CTA visible above the fold without scrolling
- [ ] Social proof (testimonials, logos, metrics) placed BEFORE the final CTA
- [ ] Form fields ≤ 3 for lead gen (email only if possible)
- [ ] Loading states on all async actions (form submit, payment)
- [ ] Success confirmation visible after conversion (not just a flash)
- [ ] Mobile CTA is full-width and thumb-reachable (bottom of viewport)
- [ ] Page loads in < 3 seconds (LCP metric)
- [ ] No distracting navigation away from conversion path
- [ ] Objection handling via FAQ or inline copy near CTA
- [ ] Urgency/scarcity signals if genuine (countdown, limited spots, stock count)

## Section Effectiveness Rules

| Section Type                | Typical Impact (approximate) | Placement                         |
| --------------------------- | ---------------------------- | --------------------------------- |
| Video hero (autoplay muted) | High engagement lift         | Above fold                        |
| Interactive demo            | High engagement lift         | Above or just below fold          |
| Social proof (logos)        | Moderate trust improvement   | Immediately after hero            |
| Testimonials with photos    | Significant conversion lift  | Before final CTA                  |
| Pricing with toggle         | More annual plan selection   | Mid-page with FAQ below           |
| FAQ accordion               | Reduces support tickets      | After pricing or before final CTA |
| Countdown timer             | Increases urgency/action     | Hero or sticky bar                |
