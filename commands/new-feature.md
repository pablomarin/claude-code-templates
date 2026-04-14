# New Feature Workflow

> **This workflow is MANDATORY. Follow every step in order.**
> **If any required command/skill fails with "Unknown skill", STOP and alert the user.**

## Required Plugins

This workflow requires the following plugins to be **installed AND enabled**:

| Plugin                                      | Skills/Commands Used                                                                                                            |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `superpowers@superpowers-marketplace`       | `/superpowers:brainstorming`, `/superpowers:writing-plans`, `/superpowers:executing-plans`, `/superpowers:systematic-debugging` |
| `pr-review-toolkit@claude-plugins-official` | `code-simplifier` agent, `code-reviewer` agent, `/pr-review-toolkit:review-pr`                                                  |

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
# Node.js
if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
  pnpm install --silent 2>/dev/null || npm install --silent 2>/dev/null || yarn install --silent 2>/dev/null
fi

# Python
if [ -f "pyproject.toml" ]; then
  uv sync 2>/dev/null || pip install -e . 2>/dev/null || echo "Run 'uv sync' manually"
fi
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
- [ ] Research done
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

## Phase 2: Research (DO NOT SKIP)

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `2 — Research`, check off "PRD created".

Before writing ANY code, research the problem space:

1. **Search existing solutions**:

   ```bash
   grep -r "relevant keywords" docs/solutions/
   ```

2. **Research current best practices**:
   - Use `WebSearch` for current documentation
   - Use `WebFetch` for specific library docs
   - Use `Context7` MCP for framework-specific guidance

3. **Study competitors**: How do established products solve this problem?

---

## Phase 3: Design + Review Loop (iterates until no P0/P1/P2 issues)

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `3 — Design`, check off "Research done".

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

Implement using TDD (Red-Green-Refactor):

```
/superpowers:executing-plans
```

**If you encounter bugs during implementation:**

```
/superpowers:systematic-debugging
```

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

The verify-e2e agent tests as a real user: no database access, no internal endpoints, no source code reading. It executes the use cases from your Phase 3.2b plan through the product's actual user-facing interfaces and produces a markdown report at `tests/e2e/reports/`.

**Step 1: Ensure servers are running from this worktree**

If you're in a worktree, dev servers may still be running from the main directory serving OLD code. Restart them from the worktree before invoking verify-e2e.

**Step 2: Invoke verify-e2e**

```
Task tool → subagent_type: "verify-e2e", prompt: "Mode: feature. Plan file: [path to your plan file]. Project type: [fullstack|api|cli|hybrid from CLAUDE.md]. Execute all E2E use cases and produce a verification report."
```

**Step 3: Act on the verdict**

- **PASS:** Proceed to Phase 5.4b
- **FAIL_BUG:** Fix the issue in code, re-run verify-e2e. Do NOT check the box until PASS.
- **FAIL_STALE:** Update the stale use case file, re-run
- **FAIL_INFRA:** Retry once manually; if still infra, report to user for decision

**If purely internal (no user-facing impact):** Check the box with justification:
`- [x] E2E verified — N/A: internal migration, no user-facing changes`

**Non-browser projects** (API-only, CLI): the verify-e2e agent handles these via HTTP/subprocess. The use case template applies; no Playwright needed.

### 5.4b E2E Regression (MANDATORY if tests/e2e/use-cases/ exists)

Run the full regression suite to catch regressions in previously shipped flows. This is what prevents your new feature from breaking the features that came before it.

**Invoke verify-e2e in regression mode:**

```
Task tool → subagent_type: "verify-e2e", prompt: "Mode: regression. Execute all use cases from tests/e2e/use-cases/. Project type: [fullstack|api|cli|hybrid]."
```

**If tests/e2e/use-cases/ doesn't exist yet** (no features graduated): check the box with `- [x] E2E regression — N/A: no accumulated use cases yet`.

**If any regression FAIL_BUG:** This feature broke something that previously worked. Fix it, then re-run both 5.4 and 5.4b.

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
