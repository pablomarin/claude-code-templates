# Project State (per-developer, gitignored)

> This file holds your active workflow state. It is NOT shared with the team.
> Hooks read this file on demand. Claude reads it when the workflow rule says to.
>
> If you started a workflow with `/new-feature` or `/fix-bug`, the Workflow section below tracks your progress.
> The Done / Now / Next sections capture your current focus across sessions.

## Workflow

| Field     | Value |
| --------- | ----- |
| Command   | none  |
| Phase     |       |
| Next step |       |

### Checklist

(populated by `/new-feature` or `/fix-bug` Pre-Flight)

---

## State

### Done (recent 2-3 only)

- (your most recent completed work)

### Now

- (what you're actively working on)

### Next

- (what's queued)

### Deferred

- (parked items with reason)

---

## Open Questions

- (questions needing resolution)

## Blockers

- (anything blocking forward progress)

---

## Update Rules

You (Claude) are responsible for updating this file. The Stop hook reminds you of the active workflow; the PreToolUse hook gates commit/push/PR on the checklist.

**On task completion:**

1. Add to Done (keep last 2-3; older history goes to `docs/CHANGELOG.md`)
2. Move top of Next → Now
3. Add to CHANGELOG.md if significant

**On new feature start (`/new-feature` or `/fix-bug` Pre-Flight step 3):**

1. REPLACE the `## Workflow` section entirely
2. Delete any orphaned checkbox lines outside `### Checklist`
