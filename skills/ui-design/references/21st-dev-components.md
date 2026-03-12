# 21st.dev Component Search

> Search [21st.dev](https://21st.dev) for high-quality, community-built React components before building from scratch.
> No API key required — uses Playwright MCP to browse, search, and copy component prompts.
>
> Last reviewed: 2026-03-12

## Why Use This

21st.dev is the largest marketplace of shadcn/ui-based React + Tailwind components. Components are:

- Community-reviewed with bookmark counts (quality signal)
- TypeScript-first with dark mode support
- Install via `npx shadcn@latest add` (source code lives in YOUR project)
- Each has a **"Copy prompt"** button — a pre-written spec you paste into Claude to recreate the component

**Rule: Before building any standard UI component from scratch, search 21st.dev first.** If a high-quality implementation exists (50+ bookmarks), use it or adapt it.

## Available Categories

### Marketing Blocks

Backgrounds (33) · Borders (12) · Calls to Action (34) · Clients (16) · Comparisons (6) · Docks (6) · Features (36) · Footers (14) · **Heroes (73)** · Hooks (31) · Images (26) · Navigation Menus (11) · **Pricing Sections (17)** · Scroll Areas (24) · Shaders (15) · **Testimonials (15)** · Texts (58) · Videos (9)

### UI Components

Accordions (40) · AI Chats (30) · Alerts (23) · Avatars (17) · Badges (25) · **Buttons (130)** · Calendars (34) · **Cards (79)** · Carousels (16) · Checkboxes (19) · Date Pickers (12) · Dialogs/Modals (37) · Dropdowns (25) · File Uploads (7) · **Forms (23)** · **Inputs (102)** · Menus (18) · Notifications (5) · Paginations (20) · Popovers (23) · Radio Groups (22) · **Selects (62)** · Sidebars (10) · Sign Ins (4) · **Sliders (45)** · Spinner Loaders (21) · **Tables (30)** · **Tabs (38)** · Tooltips (28)

## Playwright Workflow

Use this workflow in a subagent with Playwright MCP access:

### Step 1: Navigate and Search

```
1. browser_navigate → https://21st.dev
2. browser_click → Search textbox
3. browser_type → "{component type}" (e.g. "pricing card", "hero section", "data table")
   - Use slowly: true to trigger search suggestions
4. browser_snapshot → Read search results
```

### Step 2: Browse Results

The search results show component cards with:

- **Name** — component title
- **Author** — creator profile link
- **Bookmarks** — quality signal (higher = more popular)
- **Preview image** — visual thumbnail
- **URL pattern** — `/{author}/{component}/default`

**Pick the best match** by bookmark count and relevance.

### Step 3: Open Component Detail

```
1. browser_click → Component link
2. A dialog opens with:
   - Live preview (iframe)
   - "Copy prompt" button — THE KEY FEATURE
   - "Open" button — full page view
   - Install buttons
```

### Step 4: Get the Component (two options)

**Option A: Copy the prompt (RECOMMENDED)**

```
1. browser_click → "Copy prompt" button
2. The prompt is copied to clipboard — it contains a detailed implementation spec
3. Use this prompt to implement the component in the user's project
```

**Option B: Direct install via shadcn CLI**

```bash
npx shadcn@latest add "https://21st.dev/r/{author}/{component}/default"
```

This copies the component source code directly into the project.

### Step 5: Adapt to Project

Whether using the prompt or direct install:

- Match the project's color palette (use palette IDs from `typography-and-color.md`)
- Match the project's font pairing
- Adjust to project's design system tokens
- Ensure dark mode works with project's theme

## URL Patterns

| Action          | URL                                                                       |
| --------------- | ------------------------------------------------------------------------- |
| Homepage        | `https://21st.dev`                                                        |
| All components  | `https://21st.dev/community/components`                                   |
| Component page  | `https://21st.dev/{author}/{component}/default`                           |
| Author profile  | `https://21st.dev/community/{author}`                                     |
| Install command | `npx shadcn@latest add "https://21st.dev/r/{author}/{component}/default"` |

## When to Search vs Build From Scratch

| Scenario                                          | Action                                                 |
| ------------------------------------------------- | ------------------------------------------------------ |
| Standard UI component (button, card, table, form) | **Search first** — likely exists with 50+ bookmarks    |
| Hero section or landing page block                | **Search first** — 73 hero components available        |
| Pricing, testimonials, CTA sections               | **Search first** — dedicated categories                |
| Highly custom, brand-specific component           | Build from scratch using skill guidelines              |
| Animation/shader effects                          | **Search first** — 15 shader components, many animated |
| Simple utility (toggle, checkbox, radio)          | **Search first** — all exist with many variants        |
