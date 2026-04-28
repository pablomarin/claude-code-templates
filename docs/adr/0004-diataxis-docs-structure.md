# 0004 — Forge documentation follows the Diátaxis framework

## Status

Accepted (2026-04-28)

## Context

Forge ships substantial documentation: a getting-started guide, reference pages, conceptual explanations, and task-oriented walkthroughs. Without an organizing framework, docs sprawl into a flat list of markdown files where users can't predict what's where.

[Diátaxis](https://diataxis.fr/) classifies technical documentation into four modes by audience need: tutorials (learning), how-to guides (task), reference (information), and explanation (understanding). The framework has been adopted by Django, Cloudflare, NumPy, and others.

## Considered Options

- **Option A (chosen):** Diátaxis four-quadrant layout under `docs/`: `getting-started.md` (tutorial), `guides/` (how-to), `reference/` (reference), `explanation/` (understanding). Plus `troubleshooting.md` and `CHANGELOG.md` at top level.
- **Option B:** Flat `docs/` with no organizing principle. Rejected: documentation discovery is harder; new contributors don't know where to add things.
- **Option C:** README-driven with one big `docs/` README. Rejected: doesn't scale past ~5 pages.

## Decision

Forge organizes `docs/` per Diátaxis: `docs/getting-started.md`, `docs/guides/*.md`, `docs/reference/*.md`, `docs/explanation/*.md`. ADRs (`docs/adr/`) are NOT Diátaxis content — they're decision records, a different audience (future maintainers).

## Consequences

- ✅ Predictable navigation: contributors know where to add new content.
- ✅ Aligns with widely-recognized convention; reduces onboarding cost.
- ⚠️ Some content sits ambiguously between modes (e.g., `harness-philosophy.md` straddles explanation and reference). Resolved case-by-case with a bias toward explanation for "why we did it this way."
- 🔮 If Forge grows a domain that doesn't fit cleanly into the four quadrants, an extension may be needed.
