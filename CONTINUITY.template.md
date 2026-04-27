# CONTINUITY

## Goal

[PROJECT GOAL - One sentence describing what we're building]

## Key Decisions

| Decision | Choice | Why |
| -------- | ------ | --- |
|          |        |     |

---

## State

### Done (recent 2-3 only)

- Initial project setup (YYYY-MM-DD)

### Now

Ready for first task

### Next

- [Priority 1]
- [Priority 2]
- [Priority 3]

---

## Workflow

> Updated automatically by `/new-feature` and `/fix-bug` commands.
> The Stop hook reminds you of the current phase on every response.
> The PreToolUse hook blocks commit/push/PR if quality gates are incomplete.
> Delete this section when no workflow is active (or set Command to `none`).

| Field     | Value |
| --------- | ----- |
| Command   | none  |
| Phase     | —     |
| Next step | —     |

### Checklist

<!-- Populated when /new-feature or /fix-bug starts. Example shape:

- [ ] Code review loop (0 iterations) — iterate until no P0/P1/P2
- [ ] Simplified
- [ ] Verified (tests/lint/types)
- [ ] E2E use cases designed (Phase 3.2b)
- [ ] E2E verified via verify-e2e agent (Phase 5.4)
- [ ] E2E regression passed (Phase 5.4b)
- [ ] E2E use cases graduated to tests/e2e/use-cases/ (Phase 6.2b)
- [ ] E2E specs graduated to tests/e2e/specs/ (Phase 6.2c — if Playwright framework installed)
-->

---

## Open Questions

- [Question needing resolution]

## Blockers

- [None currently]

---

## Update Rules

> **IMPORTANT:** You (Claude) are responsible for updating this file. The Stop hook will remind you, but YOU must make the edits.

**On task completion:**

1. Add to Done (keep only 2-3 recent items)
2. Move top of Next → Now
3. Add to CHANGELOG.md if significant

**On new feature start (`/new-feature` or `/fix-bug` Pre-Flight step 3):**

1. **REPLACE** the `## Workflow` section entirely — do not append, do not preserve old checklist items.
2. **Delete any stale `## Approach Comparison` blocks** in the file — these are leftover from the pre-PR-#537 workflow (which used to write design content into CONTINUITY.md). The new workflow keeps the Approach Comparison in conversation context only, then persists it into the plan file at Phase 3.2; nothing should remain in CONTINUITY.md.
3. **Delete orphaned `[x]` / `[ ]` checkbox lines** that drifted outside any user-authored section. Includes: lines floating between sections, AND lines inside stale `## Approach Comparison` blocks you just deleted. Do NOT touch checkbox items inside user sections like `## Blockers` / `## Open Questions` — those are user content.

**On new feature:** Clear Done section, start fresh.

**Where detailed progress lives:**

- Feature subtasks → `docs/plans/[feature].md`
- Historical record → `docs/CHANGELOG.md`
- Learnings → `docs/solutions/`

---

## Session Start

Claude should say:

> "Loaded project state. Current focus: [Now]. Ready to continue or start something new?"
