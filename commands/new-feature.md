# New Feature Workflow

> **This workflow is MANDATORY. Follow every step in order.**
> **If any required command/skill fails with "Unknown skill", STOP and alert the user.**

## Required Plugins

This workflow requires the following plugins to be **installed AND enabled**:

| Plugin                                      | Skills/Commands Used                                                                                                                                                                                           |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `superpowers@superpowers-marketplace`       | `/superpowers:brainstorming`, `/superpowers:writing-plans`, `/superpowers:subagent-driven-development` (default executor), `/superpowers:executing-plans` (headless mode), `/superpowers:systematic-debugging` |
| `pr-review-toolkit@claude-plugins-official` | `code-simplifier` agent, `code-reviewer` agent, `/pr-review-toolkit:review-pr`                                                                                                                                 |

**To enable plugins**, add to `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "pr-review-toolkit@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true
  }
}
```

---

## Pre-Flight Checks

### 1. Create Isolated Workspace (MANDATORY)

**Check if already in a worktree:**

```bash
if [[ "$(pwd)" == *".worktrees/"* ]]; then
  echo "STATE: ALREADY_IN_WORKTREE"
else
  echo "STATE: NEEDS_WORKTREE"
fi
```

**If ALREADY_IN_WORKTREE:**

- You're already isolated - continue with current workspace
- No action needed

**If NEEDS_WORKTREE → Create worktree and cd into it:**

> ⚠️ **ALWAYS create a worktree**, even if on a feature branch. Being on "a feature branch" doesn't mean it's the right branch for THIS feature. Worktrees ensure parallel sessions never mix work.

```bash
FEATURE_NAME="$ARGUMENTS"
WORKTREE_PATH=".worktrees/$FEATURE_NAME"

# Ensure .worktrees exists and is gitignored
mkdir -p .worktrees
grep -qxF '.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore

# Create worktree (handle existing branch/worktree cases)
if [ -d "$WORKTREE_PATH" ]; then
  echo "✓ Worktree exists - reusing $WORKTREE_PATH"
elif git show-ref --quiet "refs/heads/feat/$FEATURE_NAME" 2>/dev/null; then
  git worktree add "$WORKTREE_PATH" "feat/$FEATURE_NAME"
  echo "✓ Created worktree for existing branch at $WORKTREE_PATH"
else
  git worktree add "$WORKTREE_PATH" -b "feat/$FEATURE_NAME"
  echo "✓ Created new worktree at $WORKTREE_PATH"
fi

# Symlink environment files (not copy) so rotated secrets propagate and .env can't be accidentally committed
for f in .env .env.local .env.development .env.test; do
  [ -f "$f" ] && ln -sf "$(pwd)/$f" "$WORKTREE_PATH/$f"
done
```

**Then cd into the worktree:**

```bash
cd "$WORKTREE_PATH"
```

**Install dependencies (if needed):**

```bash
# Build the Node candidate list: read the marker file setup.sh wrote at
# scaffold time (honors --playwright-dir), falling back to a default set.
NODE_DIRS=". frontend apps/web web client"
[ -f .claude/playwright-dir ] && NODE_DIRS="$(cat .claude/playwright-dir) $NODE_DIRS"

# Node.js — dedupe and install in each dir that has package.json
seen=""
for d in $NODE_DIRS; do
  case " $seen " in *" $d "*) continue;; esac
  seen="$seen $d"
  if [ -f "$d/package.json" ] && [ ! -d "$d/node_modules" ]; then
    (cd "$d" && (pnpm install --silent 2>/dev/null || npm install --silent 2>/dev/null || yarn install --silent 2>/dev/null))
  fi
done

# Python — checks repo root AND common monorepo subdirectories
for d in . backend apps/api api server; do
  if [ -f "$d/pyproject.toml" ]; then
    (cd "$d" && (uv sync 2>/dev/null || pip install -e . 2>/dev/null || echo "Run 'uv sync' manually in $d"))
  fi
done
```

**⚠️ IMPORTANT: You are now working inside the worktree.**

- All file paths are relative to the worktree (e.g., `src/main.py`, not `.worktrees/auth/src/main.py`)
- All git commands operate on the worktree's branch
- Hooks will automatically check the correct files

### 2. Read project state

```bash
cat CONTINUITY.md
```

### 3. Initialize Workflow Tracking

Write the `## Workflow` section in CONTINUITY.md (create the file if it doesn't exist):

```markdown
## Workflow

| Field     | Value                   |
| --------- | ----------------------- |
| Command   | /new-feature $ARGUMENTS |
| Phase     | Pre-Flight              |
| Next step | Verify plugins          |

### Checklist

- [x] Worktree created
- [x] Project state read
- [ ] Plugins verified
- [ ] PRD created
- [ ] Research artifact produced (`docs/research/` — via research-first agent)
- [ ] Design guidance loaded (if UI)
- [ ] Brainstorming complete
- [ ] Approach comparison filled
- [ ] Contrarian gate passed (skip | spike | council)
- [ ] Council verdict (if triggered): [approach chosen]
- [ ] Plan written
- [ ] Plan review loop (0 iterations) — iterate until no P0/P1/P2
- [ ] TDD execution complete
- [ ] Code review loop (0 iterations) — iterate until no P0/P1/P2
- [ ] Simplified
- [ ] Verified (tests/lint/types)
- [ ] E2E use cases designed (Phase 3.2b)
- [ ] E2E verified via verify-e2e agent (Phase 5.4)
- [ ] E2E regression passed (Phase 5.4b)
- [ ] E2E use cases graduated to tests/e2e/use-cases/ (Phase 6.2b)
- [ ] E2E specs graduated to tests/e2e/specs/ (Phase 6.2c — if Playwright framework installed)
- [ ] Learnings documented (if any)
- [ ] State files updated
- [ ] Committed and pushed
- [ ] PR created
- [ ] PR reviews addressed
- [ ] Branch finished
```

### 4. Verify required plugins are available (test ONE skill)

```
/superpowers:brainstorming
```

**If "Unknown skill" error:**

- STOP immediately
- Tell user: "Required plugins not loaded. Please enable in ~/.claude/settings.json and restart Claude Code."
- Do NOT proceed with workarounds or skip mandatory steps

**Checkpoint:** Check off "Plugins verified" in CONTINUITY.md and set Next step to "PRD created".

### 5. Worktree Policy Reminder

**DO NOT create additional worktrees** during this workflow. If `/superpowers:brainstorming` or other skills attempt to create a worktree, **SKIP that step** - you're already isolated.

---

## Phase 1: Requirements

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `1 — Requirements`, Next step: `PRD discuss`.

Run the PRD workflow:

```
/prd:discuss
```

Then create the PRD:

```
/prd:create
```

---

## Phase 2: Research (MANDATORY — agent-enforced)

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `2 — Research`, check off "PRD created".

Before writing ANY design, research every external library and API this feature touches. This is enforced via the `research-first` agent — not optional guidance.

### 2.1 Dispatch research-first agent

```
Task tool → subagent_type: "research-first", prompt: "Feature: <feature-name>. PRD: <path-to-PRD-or-inline-description>. Manifests: package.json, pyproject.toml (check which exist). Research all external libraries and APIs this feature will touch."
```

The agent will:

1. Scan the PRD + manifests to identify research targets
2. Query Context7, WebFetch, and WebSearch for each (current docs, breaking changes, best practices)
3. Write a structured brief to `docs/research/YYYY-MM-DD-<feature>.md`
4. Return a summary with findings count and key discovery

### 2.2 Review the brief

Read `docs/research/YYYY-MM-DD-<feature>.md`. Verify:

- Every library/API the feature touches is listed
- Each has ≥ 2 sources with access dates
- "Design impact" and "Test implication" fields are filled (not blank or "N/A" for all)
- "Open Risks" section is present

If the brief is shallow or missing targets, re-dispatch the agent with more specific instructions.

### 2.3 Fallback: if agent dispatch or web tools fail

If the `research-first` agent cannot be dispatched (Task tool unavailable) or web tools are down (Context7/WebSearch/WebFetch all failing):

1. **You (the main agent) perform the research manually:**
   - Query Context7 for each library (if available)
   - Use WebSearch/WebFetch for changelogs and docs
   - If all web tools are down, check lockfile versions + `node_modules/<lib>/CHANGELOG.md` locally
2. **Fill out the research template yourself** and save to `docs/research/YYYY-MM-DD-<feature>.md`
3. **Note in the brief:** "Fallback: main agent performed research (agent dispatch unavailable)"

This is the degraded path, not the skip path. Research still happens — just without the dedicated agent.

### 2.4 Gate: cannot proceed without research artifact

**Phase 3 (Design) MUST NOT start until `docs/research/YYYY-MM-DD-<feature>.md` exists and passes the review above.**

**Gate criteria:**

- If libraries were researched → each researched library must have ≥ 2 sources, a "Design impact" field, and a "Test implication" field. Items explicitly triaged to "Not Researched" (with justification) are exempt.
- If no external libraries/APIs → the agent writes a minimal N/A brief and that counts as passing the gate
- If fallback path was used → the brief must still meet the same criteria

---

## Phase 3: Design + Review Loop (iterates until no P0/P1/P2 issues)

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `3 — Design`, check off "Research artifact produced".

### 3.0 Load Design Guidance (if UI work)

If this feature involves ANY user-facing interface (web pages, components, dashboards, forms, landing pages):

    /ui-design

This loads the full design skill — creative direction, animation techniques, typography and color systems, and the polish checklist. It ensures the **plan** includes visual design decisions, not just technical architecture.

**Skip this step if:** the feature is purely backend with no UI impact, or if `/ui-design` is not available (Python-only projects without the skill installed).

### 3.1 Brainstorm approaches

```
/superpowers:brainstorming
```

### 3.1b Approach Comparison (MANDATORY)

After brainstorming produces 2+ approaches, fill the comparison table in CONTINUITY.md (under the `## Workflow` section). This runs BEFORE the plan file exists — the plan (Phase 3.2) will incorporate the chosen approach.

```markdown
## Approach Comparison

### Chosen Default

[The approach you recommend]

### Best Credible Alternative

[The strongest competing approach — not a strawman]

### Scoring (fixed axes)

| Axis                  | Default | Alternative |
| --------------------- | ------- | ----------- |
| Complexity            | L/M/H   | L/M/H       |
| Blast Radius          | L/M/H   | L/M/H       |
| Reversibility         | L/M/H   | L/M/H       |
| Time to Validate      | L/M/H   | L/M/H       |
| User/Correctness Risk | L/M/H   | L/M/H       |

### Cheapest Falsifying Test

[How to resolve ambiguity with a spike or experiment. Estimate: < 30 min or > 30 min.]
```

If brainstorming produced only one viable approach, still run the Contrarian gate — it validates that no alternative was missed. Write "Single viable approach identified" in the Alternative column and let Codex confirm or challenge.

### 3.1c Contrarian Gate (MANDATORY)

The Contrarian/Codex validates the "default wins" claim. **Claude cannot self-certify the skip.**

```
/council [pass the approach comparison as context — auto-trigger mode]
```

The council skill handles the gate:

- **VALIDATE** → skip council, proceed to 3.2
- **SPIKE** → run the cheapest falsifying test first, then re-evaluate
- **COUNCIL** → full council runs, verdict picks the approach, proceed to 3.2

If Codex unavailable: present the approach comparison to the user and ask them to validate.

Check off in CONTINUITY.md: `- [x] Contrarian gate passed (skip | spike | council)`

### 3.2 Write the implementation plan

```
/superpowers:writing-plans
```

### 3.2b Design E2E Use Cases (if user-facing)

If this feature changes any user-facing behavior (UI, API, flows, forms, navigation, permissions), design E2E use cases NOW — before implementation, not after.

Write use cases in the plan file under a `#### E2E Use Cases` heading, using the template from `rules/testing.md`. Each use case declares its **Interface** (API / UI / CLI / API+UI) based on the project-type matrix in `rules/testing.md` — and includes **Setup** (sanctioned method per the ARRANGE/VERIFY boundary), **Steps**, **Verification**, and **Persistence**.

**Project type scope** (from `CLAUDE.md` `## E2E Configuration`):

- **fullstack:** API use cases + UI use cases (API-first ordering for execution)
- **api:** API use cases only
- **cli:** CLI use cases only
- **hybrid:** declare per use case

Think like a user, not a developer:

- What will the user try to do with this feature?
- What's the happy path? What are the error paths?
- What existing flows could this break?

**Minimum:** 1 happy-path use case + 1 error/edge case. Complex features need more.

**If purely internal (no user-facing impact):** Write "E2E: N/A — [reason]" in the plan.

### 3.3 Plan Review Loop (MANDATORY)

Go back to the implementation plan and check everything proposed against the actual code. All available reviewers run **in parallel**, iterating until clean.

**Per iteration:**

**Step A — Run both reviews in parallel:**

**a) Claude (you) reviews the plan against the codebase:**

Read every file the plan proposes to modify. For each change, ask:

- Does the plan account for what the code actually looks like today?
- Are there existing utilities, patterns, or abstractions the plan should use instead of creating new ones?
- Are there correctness issues, missing edge cases, or integration problems?
- Is the testing strategy adequate?

> **Note:** "Is there a simpler approach?" is no longer asked here — the Approach Comparison + Contrarian Gate (3.1b/3.1c) already settled the strategic choice. This review validates the HOW, not the WHAT.

Document your findings as a severity-tagged list (P0/P1/P2/P3).

**b) Codex reviews independently:**

Check if Codex CLI is available:

```bash
command -v codex &>/dev/null && echo "Codex available" || echo "Codex not installed"
```

If available:

```
/codex review the implementation plan and check everything we're proposing versus the code — is this the simplest, fastest, best way to do it? Flag any architectural concerns.
```

Note: The `/codex` command's Design Review Mode uses its own fixed prompt — it may not return P0/P1/P2/P3 tags directly. After receiving Codex's output, classify each finding into P0/P1/P2/P3 using the severity rubric before evaluating exit criteria.

If Codex is NOT available:

- Present your own review findings plus a summary of the plan to the user
- Ask: "Does this design approach look right before I start implementing?"
- User confirmation replaces Codex as the second reviewer

**Step B — Collect findings and evaluate:**

Gather severity-tagged findings from all available reviewers. Use this rubric:

| Level | Meaning                                                                | Action                     |
| ----- | ---------------------------------------------------------------------- | -------------------------- |
| P0    | Broken — will crash, lose data, or create security vulnerability       | Must fix before proceeding |
| P1    | Wrong — incorrect behavior, logic error, missing edge case             | Must fix before proceeding |
| P2    | Poor — code smell, maintainability issue, unclear intent, missing test | Must fix before proceeding |
| P3    | Nit — style, naming, minor suggestion                                  | May fix, does not block    |

**Step C — Exit criteria:**

- **P0/P1/P2 found by any reviewer →** Fix the plan, increment iteration counter in CONTINUITY checklist (`Plan review loop (N iterations)`), go back to Step A.
- **Only P3 or clean from all available reviewers on the same pass →** Check the box in CONTINUITY with final count: `- [x] Plan review loop (3 iterations) — PASS`. Proceed to Phase 4.

**Rules:**

- Do NOT check the box until all available reviewers report no P0/P1/P2 on the same pass
- "Available reviewers" = Claude always + Codex if installed, or user if Codex unavailable
- Typically 2-3 iterations
- Do NOT proceed to Phase 4 until the plan is approved

> **Why mandatory?** Fixing a design flaw after implementation is 10x more expensive than catching it here. Two independent reviewers checking the plan against the actual code catches things a single pass misses.

---

## Phase 4: Execute

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `4 — Execute`, check off design items (brainstorming, plan, review).
>
> **Optional before starting:** Run `/compact` if the session is heavy with brainstorm + plan-review discussion. Consolidates prior phases into a structured summary and frees budget for execution. Reminder, not a gate.

### Trivial plans (≤3 tasks)

No dispatch plan needed. Use `superpowers:subagent-driven-development` and execute the plan's tasks sequentially in order. Proceed to Phase 5 when done.

### Full plans (4+ tasks)

#### 4.0 Dispatch Plan (MANDATORY before dispatching any subagent)

Append a `## Dispatch Plan` heading to the plan file with one row per task:

| Task ID | Depends on | Writes (concrete file paths)                           |
| ------- | ---------- | ------------------------------------------------------ |
| B1      | —          | `alembic/versions/2026_04_22_add_series.py`            |
| B2      | B1         | `schemas/backtest.py`                                  |
| B3      | —          | `analytics_math/deduplicate.py`, `tests/test_dedup.py` |

**`Writes` must list concrete file paths** — not directories, not globs. New files use their final intended path. Conflict detection is per physical file.

**Scheduling — serial is the default; parallel requires proven independence:**

- **Ready set:** tasks whose `Depends on` entries are all completed
- **Dispatch rule:** start any ready task whose `Writes` paths are disjoint from every currently-running task's `Writes`
- **Concurrency cap:** default 3 concurrent subagents; raise to 5 only for small, genuinely independent tasks. (3 is practitioner guidance from Anthropic's [multi-agent research post](https://www.anthropic.com/engineering/multi-agent-research-system), not a hard protocol limit.)
- **Continuous dispatch:** when a subagent returns, re-evaluate the ready set and dispatch immediately. Do not batch into waves.
- **In doubt, serialize.** File-disjointness is necessary but not sufficient — if two tasks share types, schemas, or imports, encode as `Depends on` and serialize.

**No append-only fast-path.** Tasks that both modify the same existing file — barrel exports (`index.ts`, `__init__.py`), migration manifests, shared schemas, `pyproject.toml`, etc. — **must be serialized via `Depends on`**. Same-second timestamp migrations collide on filename and on `alembic_version` head; do not parallelize migration generation. The only case where two tasks may concurrently "add" to a shared space is when each creates a **distinct new file at a different path**, in which case the `Writes` column already lists disjoint paths and the standard dispatch rule applies.

**Sequential override:** if the plan is tightly coupled (most tasks share files or types, or the feature reads as one logical change), note `"sequential mode"` in the dispatch plan and dispatch one subagent at a time. This is Cognition's documented counter-position on multi-agent orchestration and a legitimate choice for high-coupling work — parallelism is not always a win.

#### 4.1 Execute via subagent-driven-development

Use `superpowers:subagent-driven-development`. Per dispatch cycle:

1. Pick next eligible task per 4.0 rules
2. Dispatch fresh subagent with TDD discipline (Red-Green-Refactor)
3. Review diff on return before marking the task done
4. Re-evaluate ready set, dispatch next

**Handling failures:**

- Subagent returns failure, OR diff-review rejects the result → mark the task failed in the dispatch plan, cancel any in-flight dependents, surface to the user before continuing
- Rate limit or timeout → retry once with a fresh subagent; if it fails again, treat as a failure
- After each task completes, verify in-flight dependents' assumptions still hold. If a completed task introduced a breaking change to shared code, cancel the dependent and re-dispatch with updated context

**If you encounter bugs during implementation:**

```
/superpowers:systematic-debugging
```

#### 4.2 Headless / Walk-Away Mode (OPT-IN)

Say **"walk-away mode"** or **"headless"** to switch to `/superpowers:executing-plans` in a separate session. Headless loses the live parallelism of 4.1 but gains context independence — useful for long plans (15+ tasks) or when you want to step away. Default is in-session subagent-driven.

---

## Phase 5: Quality Gates (ALL REQUIRED)

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `5 — Quality Gates`, check off "TDD execution complete".
> **Note:** The PreToolUse hook will block commit/push/PR until review, simplify, and verify are checked off.

> **If any command below fails with "Unknown skill":**
>
> - Alert the user about missing plugins
> - Perform equivalent checks manually (see fallbacks below)
> - Do NOT skip quality gates

### 5.1 Code Review Loop (MANDATORY)

Run all available reviews **in parallel**, iterating until clean.

**Per iteration:**

**Step A — Run both reviews in parallel:**

**a) Second Opinion (Codex CLI):**

Check if Codex CLI is available:

```bash
command -v codex &>/dev/null && echo "Codex available" || echo "Codex not installed"
```

If available:

```
/codex review
```

Note: `/codex review` uses the codex.md command which has its own prompt format. After receiving Codex's output, classify each finding into P0/P1/P2/P3 using the severity rubric before evaluating exit criteria.

**b) Deep Review (PR Review Toolkit):**

```
/pr-review-toolkit:review-pr
```

This runs 6 specialized agents: code-reviewer, silent-failure-hunter, pr-test-analyzer, comment-analyzer, type-design-analyzer, and code-simplifier.

**Tool availability:**

- **Both available (normal):** Run Codex + PR Toolkit in parallel
- **Codex unavailable:** PR Toolkit alone is sufficient
- **PR Toolkit unavailable:** Codex alone is sufficient
- **Neither available:** Alert user, perform manual review, get user sign-off

**Step B — Collect findings and evaluate:**

Gather severity-tagged findings from all available reviewers. Use the same P0–P3 rubric from the plan review loop.

**Step C — Exit criteria:**

- **P0/P1/P2 found by any reviewer →** Fix the issues. If fixes are substantial (3+ files changed), re-run verify-app before next review iteration to catch regressions early. Increment counter in CONTINUITY checklist (`Code review loop (N iterations)`), go back to Step A.
- **Only P3 or clean from all available reviewers on the same pass →** Check the box in CONTINUITY with final count: `- [x] Code review loop (3 iterations) — PASS`. Proceed to 5.2.

**Rules:**

- Do NOT check the box until all available reviewers report no P0/P1/P2 on the same pass
- Typically 2-3 iterations
- P3s are acceptable — do not iterate for P3-only findings

### 5.2 Simplify

Run the built-in `/simplify` command on modified code:

```
/simplify
```

**Fallback (older Claude Code versions):** Use the `code-simplifier` agent on modified files.

### 5.3 Verify (USE SUBAGENT - saves context window)

**MUST use the verify-app subagent** - Do NOT run tests yourself.

Using a subagent keeps test output out of your context window, preserving tokens for actual work.

**Invoke the subagent:**

Launch the `verify-app` agent to run all tests, linting, and type checks. Report only the pass/fail verdict back.

```
Task tool → subagent_type: "verify-app", prompt: "Run verification and report pass/fail verdict."
```

**Only use fallback if Task tool fails:**

```bash
pytest && ruff check . && mypy .  # Python
npm test && npm run lint && npm run typecheck  # Node
```

### 5.4 E2E Use Case Tests (MANDATORY if user-facing)

**MUST use the `verify-e2e` subagent** — Do NOT test user flows yourself.

The verify-e2e agent tests as a real user: no database access, no internal endpoints, no source code reading. It executes the use cases from your Phase 3.2b plan through the product's actual user-facing interfaces and returns a markdown report in its response. **The agent is read-only — YOU persist the report to disk.**

**⚠ ARRANGE boundary (main agent, read before invoking verify-e2e):** Even when setting up test data for verify-e2e yourself, you are bound by the same ARRANGE rule. **Never** run raw DB writes (`psql -c "INSERT"`, `docker exec … psql -c "INSERT"`, `mysql -e "UPDATE"`, `mongosh --eval db.x.insertOne(…)`), internal/undocumented endpoints, or on-disk file-injection to seed state. Setup must go through the app's public API, signup/login flows, app CLI, UI, or documented seed commands (`make seed-dev`, `manage.py loaddata`). **If the sanctioned setup path is broken** (e.g., the app's seed CLI has a bug), **FIX the bug first** — do not route around it via direct DB writes. This is NO BUGS LEFT BEHIND applied at the E2E boundary. Routing around a broken sanctioned path is itself a bug to fix.

**Step 1: Ensure servers are running from this worktree**

If you're in a worktree, dev servers may still be running from the main directory serving OLD code. Restart them from the worktree before invoking verify-e2e.

**Step 2: Invoke verify-e2e**

```
Task tool → subagent_type: "verify-e2e", prompt: "Mode: feature. Plan file: [path to your plan file]. Project type: [fullstack|api|cli|hybrid from CLAUDE.md]. Execute all E2E use cases and return a verification report."
```

**Step 3: Persist the report (MANDATORY)**

The agent's response starts with a two-line header:

```
VERDICT: PASS | FAIL | PARTIAL
SUGGESTED_PATH: tests/e2e/reports/YYYY-MM-DD-HH-MM-<feature-or-mode>.md
---
<full markdown report body>
```

Parse the header, then `Write` the report body (everything after `---`) to the suggested path. Create the `tests/e2e/reports/` directory if it doesn't exist:

```bash
mkdir -p tests/e2e/reports
```

**Step 4: Act on the verdict**

The header's `VERDICT:` line is the top-level outcome. For `FAIL` and `PARTIAL`, inspect the per-UC classifications in the report body (`FAIL_BUG` / `FAIL_STALE` / `FAIL_INFRA`) to decide next action:

- **VERDICT: PASS** — Proceed to Phase 5.4b.
- **VERDICT: FAIL** — At least one UC was classified `FAIL_BUG` in the body. Fix the issue in code, re-run verify-e2e. Do NOT check the box until PASS. (If the body has mixed `FAIL_BUG` + `FAIL_STALE`, fix the bugs first; stale UCs are addressed separately.)
- **VERDICT: PARTIAL** — No `FAIL_BUG` in the body, but at least one `FAIL_STALE` or `FAIL_INFRA`. Look at each failed UC:
  - `FAIL_STALE`: update the stale use case file (interface or selector changed), re-run.
  - `FAIL_INFRA`: retry once manually; if still infra, report to user for decision.

**If purely internal (no user-facing impact):** Check the box with justification:
`- [x] E2E verified — N/A: internal migration, no user-facing changes`

**Non-browser projects** (API-only, CLI): the verify-e2e agent handles these via HTTP/subprocess. The use case template applies; no Playwright needed.

### 5.4b E2E Regression (MANDATORY if tests/e2e/use-cases/ has files)

Run the full regression suite to catch regressions in previously shipped flows. This is what prevents your new feature from breaking the features that came before it.

**Check first:**

```bash
ls tests/e2e/use-cases/*.md 2>/dev/null | head -1
```

If no files (empty directory, or directory missing): check the box with `- [x] E2E regression — N/A: no accumulated use cases yet`.

**Detect which regression path to use.** The framework path is only safe when every markdown UC has a matching spec — otherwise un-spec'd UCs would silently drop out of regression coverage during partial Playwright adoption.

1. **Locate Playwright framework + count unspecced use cases:**

   ```bash
   # Find playwright.config.ts. Prefer the marker file setup.sh wrote at
   # scaffold time (honors --playwright-dir custom paths like apps/dashboard).
   # Fall back to scanning common frontend subdirectories for users who never
   # ran setup.sh or whose marker is missing.
   PW_DIR=""
   if [ -f .claude/playwright-dir ]; then
     candidate=$(cat .claude/playwright-dir)
     [ -f "$candidate/playwright.config.ts" ] && PW_DIR="$candidate"
   fi
   if [ -z "$PW_DIR" ]; then
     for d in . frontend apps/web web client; do
       if [ -f "$d/playwright.config.ts" ]; then
         PW_DIR="$d"
         break
       fi
     done
   fi

   unspecced=0
   if [ -n "$PW_DIR" ]; then
     for md in "$PW_DIR"/tests/e2e/use-cases/*.md tests/e2e/use-cases/*.md; do
       [ -f "$md" ] || continue
       name=$(basename "$md" .md)
       [ -f "$PW_DIR/tests/e2e/specs/$name.spec.ts" ] || unspecced=$((unspecced+1))
     done
   fi

   if [ -n "$PW_DIR" ] && [ "$unspecced" -eq 0 ] && ls "$PW_DIR"/tests/e2e/specs/*.spec.ts >/dev/null 2>&1; then
     echo "FRAMEWORK (playwright at: $PW_DIR)"
   else
     echo AGENT
   fi
   ```

2. **If FRAMEWORK path** (framework installed AND every UC has a matching spec):
   - Run specs directly from the detected Playwright directory (no package.json script needed):
     ```bash
     cd "$PW_DIR" && pnpm exec playwright test
     ```
     For monorepo layouts where Playwright was scaffolded into `frontend/`, `apps/web/`, etc., `$PW_DIR` is set by the detection block above. For flat layouts `$PW_DIR` is `.` and the `cd` is a no-op.
     If pnpm is not the project's package manager, use `npm exec playwright test` or `yarn playwright test`.
   - Exit code 0 = all pass. Non-zero = failures.
   - Review the HTML report: `cd "$PW_DIR" && pnpm exec playwright show-report`
   - Trace viewer for failures: `cd "$PW_DIR" && pnpm exec playwright show-trace <trace.zip>`

3. **If AGENT path** (no framework, no specs yet, OR partial spec coverage):
   Invoke the verify-e2e agent in regression mode — it runs every markdown UC, guaranteeing no un-spec'd UC is missed during migration:
   ```
   Task tool → subagent_type: "verify-e2e", prompt: "Mode: regression. Execute all use cases from tests/e2e/use-cases/. Project type: [fullstack|api|cli|hybrid from CLAUDE.md]."
   ```

**Verdict handling (both paths):**

- **Regression passes:** Check off the box. Proceed to Phase 6.
- **FAIL_BUG (framework: spec failure; agent: FAIL_BUG verdict):** This feature broke something that previously worked. Fix it, then re-run 5.4b (and 5.4 if this feature has its own user-facing E2E scope).
- **FAIL_STALE (agent only):** Update stale use case file and re-run.
- **FAIL_INFRA / flake (both paths):** Retry once. If still failing, report to user for decision.

**Note:** `pnpm exec playwright test` runs the binary directly — no `package.json` script is required. setup.sh does not modify `package.json`; use the binary invocation above.

---

## Phase 6: Finish

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `6 — Finish`, check off quality gate items.

### 6.1 Compound learnings (if any)

If you fixed bugs or discovered patterns, document them:

1. **Create solution doc** in `docs/solutions/[category]/`:

   ```bash
   mkdir -p docs/solutions/[category]
   # Create docs/solutions/[category]/[descriptive-name].md with:
   # - Problem: What was the symptom
   # - Root Cause: What actually caused it
   # - Solution: How to fix it
   # - Prevention: How to avoid in future
   ```

2. **Save to auto memory** — write key learnings to your MEMORY.md or topic files

### 6.2 Update state files

1. **CONTINUITY.md**: Update Done (keep 2-3 recent), Now, Next
2. **docs/CHANGELOG.md**: If 3+ files changed on branch

### 6.2b Graduate E2E Use Cases (MANDATORY if use cases were created)

Move passing use cases from the plan file to `tests/e2e/use-cases/<feature-name>.md` as permanent regression tests.

```bash
mkdir -p tests/e2e/use-cases
# Extract the E2E Use Cases section from the plan and write as the feature file.
# Keep the same UC format (Interface, Setup, Steps, Verify, Persist).
```

Optionally tag critical paths with `@smoke` for fast regression checks.

**If no user-facing changes:** Skip this step.

### 6.2c Graduate to Playwright Specs (OPTIONAL — if framework installed)

If this project has opted into the Playwright framework (`playwright.config.ts` exists at project root), also graduate each passing use case to a deterministic `.spec.ts` file.

**Check if framework is installed:**

```bash
[ -f playwright.config.ts ] && echo FRAMEWORK || echo SKIP
```

**If SKIP (no framework):** Skip this step entirely. Proceed to 6.3.

**If FRAMEWORK is installed, YOU (the main implementation agent) write the spec file.** The verify-e2e agent does NOT have Write tools and cannot do this. Here's how:

1. **Read the source inputs:**
   - The markdown use case file: `tests/e2e/use-cases/<feature-name>.md` (intent of truth)
   - The verify-e2e report from Phase 5.4: `tests/e2e/reports/<latest>.md` (contains observed selectors, outcomes per UC)

2. **Reference the example template:** `templates/playwright/example.spec.template.ts` in the claude-codex-forge checkout — this is a skeleton for spec file structure.

3. **Write `tests/e2e/specs/<feature-name>.spec.ts`:**
   - One `test.describe('Feature: <feature-name>', () => {...})` block
   - One `test(...)` per UC that passed verification
   - Use selectors from the verify-e2e report's "Observed selectors" section
   - Prefer `getByRole`, `getByLabel`, `getByTestId` over CSS class selectors
   - Tag critical happy-paths with `@smoke` in the test name (e.g., `test('UC1: User creates a todo @smoke', ...)`)
   - Do NOT inline auth — use the fixture pattern (see `tests/e2e/fixtures/auth.ts`)
   - Do NOT generate specs for UCs that were FAIL_BUG or FAIL_STALE — skip them

4. **Skip UCs where the verify-e2e report flagged "Selector ambiguity":** Note this in CONTINUITY.md for follow-up; the user can add `data-testid` attributes and regenerate.

5. **Run the spec once locally to verify it's green:**

   ```bash
   pnpm exec playwright test tests/e2e/specs/<feature-name>.spec.ts
   ```

   If it fails, fix the selector ambiguity rather than committing a broken spec.

**Commit the generated spec:** It becomes part of the regression suite and runs in CI for every future PR.

**Skip this step entirely if:**

- Project doesn't have Playwright framework installed (no `playwright.config.ts`)
- No user-facing changes (Phase 5.4 was N/A)
- All UCs had selector ambiguity (note this and defer until testids are added)

### 6.3 Commit and push

```bash
git add -A
git commit -m "feat: [descriptive message based on changes]"
git push -u origin HEAD
```

### 6.4 Create Pull Request

**Ask the user for confirmation before creating the PR:**

> "Branch pushed. Would you like me to create a PR to main?"

**Wait for explicit user confirmation before proceeding.**

```bash
gh pr create --base main --title "[PR title]" --body "[PR description]"
```

**Show the user the PR URL.**

### 6.5 Wait for PR reviews

Wait for automated reviewers (GitHub Copilot, Claude, Codex) and peer developer reviews to arrive on the PR.

### 6.6 Process PR review comments

```
/review-pr-comments
```

Address all review comments, fix issues, and push fixes.

**After fixing review comments, re-run quality gates** (5.1 Code Review Loop, 5.2 Simplify, 5.3 Verify) on the new changes to ensure no regressions were introduced. Repeat until the PR is approved.

### 6.7 Finish the branch (Merge + Cleanup)

Once the PR is approved:

```
/finish-branch
```

This command will:

1. Merge the PR to main (if not already merged)
2. Delete the remote branch
3. Delete the local branch and remove the worktree
4. Restart development servers from main

---

## ⚠️ IMPORTANT: Never Bypass Mandatory Steps

If any MANDATORY step cannot be completed:

1. **STOP** - Do not continue with workarounds
2. **ALERT** - Tell the user which step failed and why
3. **WAIT** - Get user guidance before proceeding
4. **NEVER** use bash/python scripts to bypass Edit hooks or skip workflow validation

---

## Checklist

**The live checklist is in `## Workflow` in CONTINUITY.md** — initialized in Pre-Flight step 3.

The Stop hook reminds you of the current phase on every response. The PreToolUse hook blocks commit/push/PR until review, simplify, and verify are checked off. Update the checklist after each step.
