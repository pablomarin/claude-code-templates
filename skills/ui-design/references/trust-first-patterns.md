# Trust-First UI Patterns

> Design guidance for healthcare, finance, legal, government, and any interface where user safety, accuracy, and confidence matter more than spectacle.
> Use when the mode is **Trust-First** — where a mistake can cost money, health, or legal standing.
>
> Last reviewed: 2026-03-12

---

## Trust Signals

Users on high-stakes surfaces need constant reassurance. Make trust visible:

### Required Trust Elements

- [ ] **Credentials/certifications** visible (HIPAA badge, SOC2, PCI, bar association, medical license)
- [ ] **Security indicators** — HTTPS lock, encryption mention, "Your data is encrypted" near sensitive inputs
- [ ] **Contact information** prominent — phone, email, chat. Users need to know a human is reachable
- [ ] **Privacy policy** linked near data collection points (not just in the footer)
- [ ] **Data ownership** — tell users what happens to their data, how long it's stored, how to delete it
- [ ] **Professional imagery** — credentials, buildings, abstract trust patterns. Avoid generic stock smiling people
- [ ] **Consistent branding** — no design inconsistencies that make the site feel unreliable or phishy

---

## High-Stakes Forms

Forms where mistakes have real consequences need extra friction and clarity.

### Multi-Step with Review

```
┌─ Personal Info ── Account ── Verify ── Review ── Confirm ─┐
│  ●────────────────●────────────○──────────○──────────○      │
│                                                              │
│  Step 2: Account Details                                     │
│                                                              │
│  Account Type *              [Checking ▾]                    │
│  Routing Number *            [●●●●●●●89]  [Show]            │  ← Masked by default
│  Account Number *            [●●●●●●4829] [Show]            │
│                                                              │
│  ⓘ Your bank details are encrypted and never stored          │  ← Trust signal inline
│    on our servers. Learn more →                              │
│                                                              │
│  [← Back]                              [Continue →]          │
└──────────────────────────────────────────────────────────────┘
```

### Review Step (MANDATORY for Trust-First)

Before any irreversible action, show a review screen summarizing ALL submitted data:

```
┌─────────────────────────────────────────┐
│  Review Your Information                 │
│                                          │
│  Personal Info              [Edit]       │
│  Name: Jane Smith                        │
│  Email: jane@example.com                 │
│                                          │
│  Account Details            [Edit]       │
│  Type: Checking                          │
│  Routing: ●●●●●89                        │
│  Account: ●●●●4829                       │
│                                          │
│  ⚠ By submitting, you authorize a        │  ← Explicit consequences
│  one-time transfer of $1,500.00.         │
│  This cannot be undone.                  │
│                                          │
│  [← Back]       [Confirm & Submit]       │  ← Distinct confirm button
└─────────────────────────────────────────┘
```

### Form Rules for Trust-First

- **Every required field** marked with `*` and "(required)" label
- **Inline validation on blur** with specific, helpful error messages
- **Sensitive fields masked by default** with a "Show" toggle
- **Trust signals inline** near sensitive inputs (encryption, privacy, non-storage)
- **Review step before submission** — show all data, allow editing each section
- **Explicit consequences** stated before confirm button
- **Confirmation distinct from navigation** — "Confirm & Submit" not just "Continue"
- **Success state** — clear confirmation page with reference number, next steps, and contact info

---

## Sensitive Data Handling

### Display Rules

| Data Type       | Default Display             | Reveal Control                           | Example                       |
| --------------- | --------------------------- | ---------------------------------------- | ----------------------------- |
| SSN / Tax ID    | `●●●-●●-4829`               | Click "Show" (re-authenticate if needed) | Last 4 digits visible         |
| Bank account    | `●●●●●●4829`                | Click "Show"                             | Last 4 digits visible         |
| Phone number    | `(●●●) ●●●-8901`            | Always visible or toggleable             | Depends on context            |
| Email           | `j●●●@example.com`          | Click "Show"                             | First letter + domain visible |
| Password        | `••••••••`                  | Click eye icon                           | Never show existing password  |
| Medical records | Visible to authorized users | Role-based access                        | Audit trail required          |

### Rules

- **Mask by default** — never show sensitive data without user intent
- **Reveal controls** — "Show/Hide" toggle, not a separate page
- **Session timeout warning** — "Your session expires in 2 minutes" with option to extend
- **Copy protection** — disable autocomplete on sensitive fields, warn before copy
- **Audit trail** — log who viewed/modified sensitive data and when
- **Export controls** — explicit consent before downloading/exporting sensitive data

---

## Status Clarity

### Status Communication Rules

**NEVER use color alone.** Always combine:

1. **Color** (green/amber/red/blue/gray)
2. **Icon** (checkmark/triangle/X/info/clock)
3. **Text label** ("Approved" / "Pending Review" / "Rejected")

### Status Patterns

```
✅ Approved — Your application was approved on Mar 12, 2026          ← Success
⚠️ Action Required — Please upload your ID by Mar 15, 2026          ← Warning with deadline
❌ Rejected — Your claim was denied. Contact support for details.    ← Error with next step
ℹ️ In Review — We're reviewing your submission (typically 2-3 days)  ← Info with expectation
⏳ Pending — Waiting for bank verification (usually 1 business day)  ← Neutral with timeline
```

### Rules

- **Timestamps on everything** — "Submitted Mar 12, 2026 at 2:34 PM" not just "Submitted"
- **Data freshness** — "Last updated 2 min ago" or "As of Mar 12, 2026"
- **Who did what** — "Approved by Dr. Johnson on Mar 12" not just "Approved"
- **What happens next** — every status should tell the user what to expect
- **Plain language** — "We couldn't process your payment" not "Error code 4023"

---

## Confirmation & Destructive Actions

### Confirmation Dialog Pattern

```
┌──────────────────────────────────────┐
│  ⚠ Cancel Subscription?              │
│                                       │
│  Your Pro plan will end on Mar 31.    │  ← What happens
│  You'll lose access to:               │  ← What you lose
│  • Advanced analytics                 │
│  • Priority support                   │
│  • Custom domains                     │
│                                       │
│  You can resubscribe anytime, but     │  ← Recovery path
│  your data will be retained for 30    │
│  days.                                │
│                                       │
│  [Keep Subscription]  [Cancel Plan]   │  ← Safe action is primary
└──────────────────────────────────────┘
```

### Rules

- **Safe action is visually primary** (solid button) — destructive action is secondary (outline/ghost)
- **Explicit consequences** — what will happen, what will be lost, whether it's reversible
- **Recovery path** — tell the user how to undo or what happens to their data
- **No "Are you sure?" alone** — always include WHAT will happen, not just a yes/no
- **Type-to-confirm** for highly destructive actions (delete account, remove all data)

---

## Domain-Specific Patterns

### Healthcare

- **Appointments**: Show provider name, specialty, location, date/time, preparation instructions
- **Lab results**: Normal range context, trend over time, "Talk to your doctor about these results"
- **Medications**: Name, dosage, frequency, side effects, interactions, refill status
- **Critical alerts**: Prominent banner (not just a toast), cannot be dismissed without acknowledgment
- **Caregiver access**: Clearly show who has access, how to revoke, audit log
- **Urgency escalation**: Visual distinction between routine, urgent, and emergency

### Finance

- **Balances**: Distinguish available vs pending vs total. Show "as of" timestamp
- **Transactions**: Pending vs posted status, merchant name, category, date, amount
- **Fees**: Always visible BEFORE action, never hidden in confirmation
- **Transfer confirmation**: Amount, from/to accounts, expected arrival date, cancel window
- **Fraud alerts**: Prominent, actionable ("Was this you? [Yes] [No, freeze card]")
- **Identity verification**: Clear progress, document requirements, processing time estimate

### Legal

- **Deadlines**: Prominent countdown/calendar, notification settings, "X days remaining"
- **Document versions**: Version history, compare changes, who edited, when
- **Signatures**: Clear indication of what's being signed, by whom, legal implications
- **Case status**: Timeline view, current stage highlighted, next expected action
- **Not-legal-advice disclaimers**: Visible where generated content could be mistaken for legal counsel
- **Privilege indicators**: Clearly mark attorney-client privileged communications

---

## Accessibility (Stricter Than Standard)

Trust-First interfaces must exceed standard AA:

| Requirement      | Standard   | Trust-First                                                          |
| ---------------- | ---------- | -------------------------------------------------------------------- |
| Text contrast    | 4.5:1 (AA) | **7:1 (AAA)** on critical text (balances, status, alerts)            |
| Touch targets    | 44x44px    | **48x48px** minimum, **56px** for primary actions                    |
| Font size        | 16px body  | **18px+ body** on critical flows                                     |
| Error messages   | Visible    | Visible + `role="alert"` + specific remediation steps                |
| Form labels      | Present    | Present + persistent (never placeholder-only) + associated via `for` |
| Focus indicators | Visible    | **3-4px ring**, high contrast, never removed                         |
| Skip navigation  | Present    | Present + "Skip to main action" on critical forms                    |

---

## Motion Budget: Trust-First

| Allowed                             | Not Allowed                      |
| ----------------------------------- | -------------------------------- |
| Smooth transitions (200-300ms)      | Canvas particles, WebGL effects  |
| Subtle hover state changes          | Animated SVG wave dividers       |
| Accordion open/close                | Spring entrance animations       |
| Progress bar animation              | Scroll-triggered reveals         |
| Toast slide-in (300ms)              | Parallax effects                 |
| Loading spinner/skeleton            | Custom cursor effects            |
| Focus ring transitions              | Staggered page load animations   |
| Number transitions for data updates | Decorative background animations |

**Principle:** Every animation should communicate state change or provide feedback. If it's decorative, remove it.
