# Bug Fix Workflow

> **This workflow is MANDATORY. Follow every step in order.**
> **If any required command/skill fails with "Unknown skill", STOP and alert the user.**

## Required Plugins

This workflow requires the following plugins to be **installed AND enabled**:

| Plugin                                      | Skills/Commands Used                                                                                                                                                                                           |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `superpowers@superpowers-marketplace`       | `/superpowers:systematic-debugging`, `/superpowers:brainstorming`, `/superpowers:writing-plans`, `/superpowers:subagent-driven-development` (default executor), `/superpowers:executing-plans` (headless mode) |
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

> ⚠️ **ALWAYS create a worktree**, even if on a feature branch. Being on "a feature branch" doesn't mean it's the right branch for THIS fix. Worktrees ensure parallel sessions never mix work.

```bash
FIX_NAME="$ARGUMENTS"
WORKTREE_PATH=".worktrees/$FIX_NAME"

# Ensure .worktrees exists and is gitignored
mkdir -p .worktrees
grep -qxF '.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore

# Create worktree (handle existing branch/worktree cases)
if [ -d "$WORKTREE_PATH" ]; then
  echo "✓ Worktree exists - reusing $WORKTREE_PATH"
elif git show-ref --quiet "refs/heads/fix/$FIX_NAME" 2>/dev/null; then
  git worktree add "$WORKTREE_PATH" "fix/$FIX_NAME"
  echo "✓ Created worktree for existing branch at $WORKTREE_PATH"
else
  git worktree add "$WORKTREE_PATH" -b "fix/$FIX_NAME"
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

- All file paths are relative to the worktree (e.g., `src/main.py`, not `.worktrees/fix-name/src/main.py`)
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

| Field     | Value               |
| --------- | ------------------- |
| Command   | /fix-bug $ARGUMENTS |
| Phase     | Pre-Flight          |
| Next step | Verify plugins      |

### Checklist

- [x] Worktree created
- [x] Project state read
- [ ] Plugins verified
- [ ] Searched existing solutions
- [ ] Systematic debugging complete
- [ ] Library research done (if external dep involved — via research-first agent)
- [ ] Design guidance loaded (if UI fix)
- [ ] Brainstorming complete (if complex)
- [ ] Approach comparison filled (if complex)
- [ ] Contrarian gate passed (skip | spike | council) (if complex)
- [ ] Council verdict (if triggered): [approach chosen] (if complex)
- [ ] Plan written (if complex)
- [ ] Plan review loop (0 iterations, if complex) — iterate until no P0/P1/P2
- [ ] TDD fix execution complete
- [ ] Code review loop (0 iterations) — iterate until no P0/P1/P2
- [ ] Simplified
- [ ] Verified (tests/lint/types)
- [ ] E2E use cases designed (Phase 3.2b plan file, or simple-fix staging at `docs/plans/<bug-name>-use-cases.md`)
- [ ] E2E verified via verify-e2e agent (Phase 5.4)
- [ ] E2E regression passed (Phase 5.4b)
- [ ] E2E use cases graduated to tests/e2e/use-cases/ (Phase 6.2b)
- [ ] E2E specs graduated to tests/e2e/specs/ (Phase 6.2c — if Playwright framework installed)
- [ ] Learning documented
- [ ] State files updated
- [ ] Committed and pushed
- [ ] PR created
- [ ] PR reviews addressed
- [ ] Branch finished
```

### 4. Verify required plugins are available (test ONE skill)

```
/superpowers:systematic-debugging
```

**If "Unknown skill" error:**

- STOP immediately
- Tell user: "Required plugins not loaded. Please enable in ~/.claude/settings.json and restart Claude Code."
- Do NOT proceed with workarounds or skip mandatory steps

**Checkpoint:** Check off "Plugins verified" in CONTINUITY.md and set Next step to "Search existing solutions".

### 5. Worktree Policy Reminder

**DO NOT create additional worktrees** during this workflow. If `/superpowers:systematic-debugging` or other skills attempt to create a worktree, **SKIP that step** - you're already isolated.

---

## Phase 1: Research Existing Solutions

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `1 — Research`, Next step: `Search existing solutions`.

Before attempting ANY fix, check if this was solved before:

```bash
grep -r "error message or symptom" docs/solutions/
grep -r "related module name" docs/solutions/
ls docs/solutions/
```

If found, review the solution and apply it.

---

## Phase 2: Systematic Debugging (MANDATORY)

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `2 — Debugging`, check off "Searched existing solutions".

**DO NOT guess at fixes.** Run the 4-phase root cause analysis:

```
/superpowers:systematic-debugging
```

This will guide you through:

1. **Reproduce** - Confirm the bug exists
2. **Isolate** - Narrow down the cause
3. **Identify** - Find the root cause
4. **Verify** - Confirm understanding before fixing

> **⚠️ CRITICAL:** If this skill is unavailable, you MUST still follow the 4-phase process manually:
>
> 1. Reproduce the bug consistently
> 2. Isolate by adding logging/tracing at component boundaries
> 3. Identify root cause (not just symptoms)
> 4. Verify your understanding before proposing ANY fix
>
> **NEVER skip this phase. NEVER guess at fixes.**

### 2.5 Targeted Library Research (if external dependency involved)

If the root cause involves an external library, API, or framework (not purely internal logic):

```
Task tool → subagent_type: "research-first", prompt: "Bug fix research. Library: <library-name>. Our version: <version from manifest>. Bug symptom: <what's happening>. Research: current best practices, known issues with our version, breaking changes, recommended migration path if relevant."
```

The agent writes to `docs/research/YYYY-MM-DD-<bug-name>.md` — a lighter brief focused on the specific library involved.

**Skip this step if:** the root cause is purely internal logic (wrong conditional, missing null check, etc.) with no external dependency involvement.

---

## Phase 3: Plan the Fix

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `3 — Plan`, check off "Systematic debugging complete" (and "Library research done" if Phase 2.5 was performed).

### For simple fixes (1-2 files):

Proceed directly to Phase 4 **UNLESS** the fix touches a high-impact surface:

- Schema/database migrations
- Public API contracts
- Authentication or permissions
- Payment or billing logic
- Configuration defaults affecting all users
- Rollout/deployment strategy
- Architecture boundaries (service boundaries, shared libraries, database ownership)

**If high-impact:** Treat as complex — enter Phase 3 below.

### For complex fixes (3+ files or architectural):

#### 3.0 Load Design Guidance (if UI fix)

If this bug fix involves ANY user-facing interface changes:

    /ui-design

This ensures UI fixes maintain visual quality — don't regress the design while fixing functionality.

**Skip this step if:** the fix is purely backend/logic with no UI impact, or if `/ui-design` is not available.

#### 3.1 Brainstorm approaches

```
/superpowers:brainstorming
```

#### 3.1b Approach Comparison (MANDATORY)

Same as `/new-feature` 3.1b — fill the approach comparison table in CONTINUITY.md (runs before the plan file exists). If only one viable fix, still run the Contrarian gate (validates no alternative was missed).

#### 3.1c Contrarian Gate (MANDATORY)

Same as `/new-feature` 3.1c — Codex validates the "default wins" claim via the council skill.

#### 3.2 Write the fix plan

```
/superpowers:writing-plans
```

#### 3.2b Design E2E Use Cases (if user-facing)

If this fix changes any user-facing behavior (UI, API, flows, forms, navigation, permissions), design E2E use cases NOW — before implementation, not after.

Write use cases in the plan file under a `#### E2E Use Cases` heading, using the template from `rules/testing.md`. Each use case declares its **Interface** (API / UI / CLI / API+UI) based on the project-type matrix in `rules/testing.md` — and includes **Setup** (sanctioned method per the ARRANGE/VERIFY boundary), **Steps**, **Verification**, and **Persistence**.

**Project type scope** (from `CLAUDE.md` `## E2E Configuration`):

- **fullstack:** API use cases + UI use cases (API-first ordering for execution)
- **api:** API use cases only
- **cli:** CLI use cases only
- **hybrid:** declare per use case

For bug fixes, think about:

- What was the user doing when the bug occurred? Reproduce that as a use case.
- After the fix, does the happy path still work?
- Could the fix break any adjacent user flow?

**Minimum:** 1 use case that reproduces the original bug through the user's interface and verifies the fix.

**If purely internal (no user-facing impact):** Write "E2E: N/A — [reason]" in the plan.

#### 3.3 Plan Review Loop (MANDATORY)

Go back to the fix plan and check everything proposed against the actual code. All available reviewers run **in parallel**, iterating until clean.

**Per iteration:**

**Step A — Run both reviews in parallel:**

**a) Claude (you) reviews the plan against the codebase:**

Read every file the plan proposes to modify. For each change, ask:

- Does the plan account for what the code actually looks like today?
- Are there existing utilities, patterns, or abstractions the plan should use instead of creating new ones?
- Are there correctness issues, missing edge cases, or integration problems?
- Is the testing strategy adequate?

> **Note:** "Is there a simpler approach?" is no longer asked here — the Approach Comparison + Contrarian Gate (3.1b/3.1c) already settled the strategic choice.

Document your findings as a severity-tagged list (P0/P1/P2/P3).

**b) Codex reviews independently:**

Check if Codex CLI is available:

```bash
command -v codex &>/dev/null && echo "Codex available" || echo "Codex not installed"
```

If available:

```
/codex review the fix plan and check everything we're proposing versus the code — is this the simplest, fastest, best way to do it? Flag any concerns.
```

Note: The `/codex` command's Design Review Mode uses its own fixed prompt — it may not return P0/P1/P2/P3 tags directly. After receiving Codex's output, classify each finding into P0/P1/P2/P3 using the severity rubric before evaluating exit criteria.

If Codex is NOT available:

- Present your own review findings plus a summary of the plan to the user
- Ask: "Does this fix approach look right before I start implementing?"
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

> **Why mandatory?** A wrong fix plan leads to wasted effort and potentially new bugs. Two independent reviewers checking the plan against the actual code catches things a single pass misses.

---

## Phase 4: Execute the Fix

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `4 — Execute`, check off planning items.

### Simple fixes (1-2 files, Phase 3 skipped)

Write a failing test first, then fix. Single-threaded — no dispatch plan needed.

### Complex fixes (3+ files, Phase 3 complete)

> **Optional before starting:** Run `/compact` if the session is heavy with debugging + plan-review discussion.

#### 4.0 Dispatch Plan (MANDATORY before dispatching any subagent)

Append a `## Dispatch Plan` heading to the plan file with one row per task. Format, scheduling rules, and failure semantics are identical to `/new-feature` — see `new-feature.md` in this same `.claude/commands/` directory, Phase 4.0, for the full spec. Key points restated:

- `Writes` lists **concrete file paths**, not directories or globs
- Default concurrency cap: 3 concurrent subagents (max 5 for small, genuinely independent tasks)
- Serial is the default; parallel requires proven independence (all `Depends on` resolved AND disjoint `Writes`)
- **No append-only fast-path** — tasks modifying the same existing file always serialize via `Depends on`
- Shared types/imports → encode as explicit `Depends on`
- Sequential override for tightly-coupled fixes is legitimate (Cognition's counter-position)

#### 4.1 Execute via subagent-driven-development

Use `superpowers:subagent-driven-development`. Per cycle: pick next eligible task → dispatch fresh subagent with TDD discipline → review diff on return → re-evaluate ready set → dispatch next.

**Handling failures:**

- Subagent failure OR diff-review reject → mark the task failed, cancel any in-flight dependents, surface to the user
- Rate limit or timeout → retry once with a fresh subagent; second failure is a real failure
- After each task completes, verify in-flight dependents' assumptions still hold; cancel and re-dispatch if a breaking change landed upstream

**If you encounter bugs during implementation:**

```
/superpowers:systematic-debugging
```

#### 4.2 Headless / Walk-Away Mode (OPT-IN)

Say **"walk-away mode"** or **"headless"** to switch to `/superpowers:executing-plans` in a separate session. Default is in-session subagent-driven.

---

## Phase 5: Quality Gates (ALL REQUIRED)

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `5 — Quality Gates`, check off "TDD fix execution complete".
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

The verify-e2e agent tests as a real user: no database access, no internal endpoints, no source code reading. It executes user journey use cases through the product's actual user-facing interfaces and returns a markdown report in its response. **The agent is read-only — YOU persist the report to disk.**

**⚠ ARRANGE boundary (main agent, read before invoking verify-e2e):** Even when setting up test data for verify-e2e yourself, you are bound by the same ARRANGE rule. **Never** run raw DB writes (`psql -c "INSERT"`, `docker exec … psql -c "INSERT"`, `mysql -e "UPDATE"`, `mongosh --eval db.x.insertOne(…)`), internal/undocumented endpoints, or on-disk file-injection to seed state. Setup must go through the app's public API, signup/login flows, app CLI, UI, or documented seed commands (`make seed-dev`, `manage.py loaddata`). **If the sanctioned setup path is broken** (e.g., the app's seed CLI has a bug), **FIX the bug first** — do not route around it via direct DB writes. This is NO BUGS LEFT BEHIND applied at the E2E boundary.

**Step 0: Ensure use cases exist (simple-fix path only)**

Simple fixes (1-2 files, non-high-impact) skip Phase 3 entirely — so no plan file exists. If you took the simple-fix path AND the change is user-facing:

- Write a lightweight use case set inline (1 happy-path + 1 error case minimum) using the UC template from `rules/testing.md`
- Save to **`docs/plans/<bug-name>-use-cases.md`** as a staging file. **Start the file with a `#### E2E Use Cases` heading** so verify-e2e can extract the UCs correctly.
- **Why a staging file, not tests/e2e/use-cases/ directly?** Writing directly to `tests/e2e/use-cases/` would cause Phase 5.4b regression mode to pick up the new unverified use case alongside accumulated ones. Staging in `docs/plans/` keeps the separation clean. Phase 6.2b then graduates the staged file after PASS.
- Then proceed to Step 1

If you took the complex-fix path (Phase 3), use cases are already in the plan file — skip this step.

**Step 1: Ensure servers are running from this worktree**

If you're in a worktree, dev servers may still be running from the main directory serving OLD code. Restart them from the worktree before invoking verify-e2e.

**Step 2: Invoke verify-e2e**

```
Task tool → subagent_type: "verify-e2e", prompt: "Mode: feature. Plan file: [path to plan file OR docs/plans/<bug-name>-use-cases.md for simple fixes]. Project type: [fullstack|api|cli|hybrid from CLAUDE.md]. Execute all E2E use cases and return a verification report."
```

**Step 3: Persist the report (MANDATORY)**

The agent's response starts with a two-line header:

```
VERDICT: PASS | FAIL | PARTIAL
SUGGESTED_PATH: tests/e2e/reports/YYYY-MM-DD-HH-MM-<feature-or-mode>.md
---
<full markdown report body>
```

Parse the header, then `Write` the report body (everything after `---`) to the suggested path. Create the `tests/e2e/reports/` directory if needed:

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
`- [x] E2E verified — N/A: internal fix, no user-facing changes`

**Non-browser projects** (API-only, CLI): the verify-e2e agent handles these via HTTP/subprocess. The use case template applies; no Playwright needed.

### 5.4b E2E Regression (MANDATORY if tests/e2e/use-cases/ has files)

Run the full regression suite to catch regressions in previously shipped flows.

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
- **FAIL_BUG (framework: spec failure; agent: FAIL_BUG verdict):** This fix broke something that previously worked. Fix it, then re-run 5.4b (and 5.4 if this fix has its own user-facing E2E scope).
- **FAIL_STALE (agent only):** Update stale use case file and re-run.
- **FAIL_INFRA / flake (both paths):** Retry once. If still failing, report to user for decision.

**Note:** `pnpm exec playwright test` runs the binary directly — no `package.json` script is required. setup.sh does not modify `package.json`; use the binary invocation above.

---

## Phase 6: Finish

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `6 — Finish`, check off quality gate items.

### 6.1 Compound the learning (MANDATORY for bug fixes)

Every bug fix teaches something. Capture it:

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

This creates a searchable solution so the same bug is never debugged twice.

### 6.2 Update state files

1. **CONTINUITY.md**: Update Done (keep 2-3 recent), Now, Next
2. **docs/CHANGELOG.md**: If 3+ files changed on branch

### 6.2b Graduate E2E Use Cases (MANDATORY if use cases were created)

Move passing use cases to `tests/e2e/use-cases/<bug-name>.md` as permanent regression tests.

**Complex-fix path:** Extract the E2E Use Cases section from the plan file and write as `tests/e2e/use-cases/<bug-name>.md`.

**Simple-fix path:** Move the staging file:

```bash
mkdir -p tests/e2e/use-cases
mv docs/plans/<bug-name>-use-cases.md tests/e2e/use-cases/<bug-name>.md
```

Both paths:

- Keep the same UC format (Interface, Setup, Steps, Verify, Persist)
- Optionally tag critical paths with `@smoke` for fast regression checks

**Skip this step if:** No user-facing changes (Phase 5.4 was N/A).

### 6.2c Graduate to Playwright Specs (OPTIONAL — if framework installed)

If this project has opted into the Playwright framework (`playwright.config.ts` exists at project root), also graduate each passing use case to a deterministic `.spec.ts` file. The graduated spec lives alongside the moved use case file (complex-fix: from the plan; simple-fix: from the staging file moved in 6.2b).

**Check if framework is installed:**

```bash
[ -f playwright.config.ts ] && echo FRAMEWORK || echo SKIP
```

**If SKIP (no framework):** Skip this step entirely. Proceed to 6.3.

**If FRAMEWORK is installed, YOU (the main implementation agent) write the spec file.** The verify-e2e agent does NOT have Write tools and cannot do this. Here's how:

1. **Read the source inputs:**
   - The markdown use case file: `tests/e2e/use-cases/<bug-name>.md` (intent of truth — just moved in 6.2b)
   - The verify-e2e report from Phase 5.4: `tests/e2e/reports/<latest>.md` (contains observed selectors, outcomes per UC)

2. **Reference the example template:** `templates/playwright/example.spec.template.ts` in the claude-codex-forge checkout — this is a skeleton for spec file structure.

3. **Write `tests/e2e/specs/<bug-name>.spec.ts`:**
   - One `test.describe('Fix: <bug-name>', () => {...})` block
   - One `test(...)` per UC that passed verification (at minimum: the regression reproducer)
   - Use selectors from the verify-e2e report's "Observed selectors" section
   - Prefer `getByRole`, `getByLabel`, `getByTestId` over CSS class selectors
   - Tag the reproducer as `@smoke` in the test name so it runs in fast regression checks
   - Do NOT inline auth — use the fixture pattern (see `tests/e2e/fixtures/auth.ts`)
   - Do NOT generate specs for UCs that were FAIL_BUG or FAIL_STALE — skip them

4. **Skip UCs where the verify-e2e report flagged "Selector ambiguity":** Note this in CONTINUITY.md for follow-up; the user can add `data-testid` attributes and regenerate.

5. **Run the spec once locally to verify it's green:**

   ```bash
   pnpm exec playwright test tests/e2e/specs/<bug-name>.spec.ts
   ```

   If it fails, fix the selector ambiguity rather than committing a broken spec.

**Commit the generated spec:** It becomes part of the regression suite and runs in CI for every future PR — locking in the fix so this bug cannot recur.

**Skip this step entirely if:**

- Project doesn't have Playwright framework installed (no `playwright.config.ts`)
- No user-facing changes (Phase 5.4 was N/A)
- All UCs had selector ambiguity (note this and defer until testids are added)

### 6.3 Commit and push

```bash
git add -A
git commit -m "fix: [descriptive message based on changes]"
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

The hooks exist to enforce quality. Bypassing them defeats their purpose.

---

## Checklist

**The live checklist is in `## Workflow` in CONTINUITY.md** — initialized in Pre-Flight step 3.

The Stop hook reminds you of the current phase on every response. The PreToolUse hook blocks commit/push/PR until review, simplify, and verify are checked off. Update the checklist after each step.
