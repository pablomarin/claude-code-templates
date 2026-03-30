# Bug Fix Workflow

> **This workflow is MANDATORY. Follow every step in order.**
> **If any required command/skill fails with "Unknown skill", STOP and alert the user.**

## Required Plugins

This workflow requires the following plugins to be **installed AND enabled**:

| Plugin                                      | Skills/Commands Used                                                                                                            |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `superpowers@superpowers-marketplace`       | `/superpowers:systematic-debugging`, `/superpowers:brainstorming`, `/superpowers:writing-plans`, `/superpowers:executing-plans` |
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
- [ ] Design guidance loaded (if UI fix)
- [ ] Brainstorming complete (if complex)
- [ ] Plan written (if complex)
- [ ] Plan review loop (0 iterations, if complex) — iterate until no P0/P1/P2
- [ ] TDD fix execution complete
- [ ] Code review loop (0 iterations) — iterate until no P0/P1/P2
- [ ] Simplified
- [ ] Verified (tests/lint/types)
- [ ] E2E use cases tested (if user-facing)
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

---

## Phase 3: Plan the Fix

> **Checkpoint:** Update `## Workflow` in CONTINUITY.md — Phase: `3 — Plan`, check off "Systematic debugging complete".

### For simple fixes (1-2 files):

Proceed directly to Phase 4.

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

#### 3.2 Write the fix plan

```
/superpowers:writing-plans
```

#### 3.2b Design E2E Use Cases (if user-facing)

If this fix changes any user-facing behavior (UI, API, flows, forms, navigation, permissions), design E2E use cases NOW — before implementation, not after.

Write use cases in the plan file using the template from `rules/testing.md`. Each use case needs: **Intent, Steps, Verification, Persistence**.

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

- Is this the simplest way to achieve the goal?
- Does the plan account for what the code actually looks like today?
- Are there existing utilities, patterns, or abstractions the plan should use instead of creating new ones?
- Is anything proposed that's unnecessary or over-engineered?

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

Implement using TDD (Red-Green-Refactor):

```
/superpowers:executing-plans
```

Or for simple fixes, write a failing test first, then fix.

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

**If this fix changes ANY user-facing behavior, execute E2E tests.**

User-facing means: API changes, UI changes, new pages, flow changes, form changes, navigation changes, permission changes — anything a user would notice.

**If purely internal (no user-facing impact):** Check the box with justification:
`- [x] E2E use cases tested — N/A: internal migration, no user-facing changes`

**Step 1: Review or design use cases**

If Phase 3 was used (complex fix): open the plan file and review the E2E use cases designed earlier. Refine if implementation revealed new scenarios.

If Phase 3 was skipped (simple fix): design use cases now using the template from `rules/testing.md`. At minimum: 1 use case that reproduces the original bug through the user's interface and verifies the fix.

Add the use cases to CONTINUITY.md for tracking:

```markdown
#### E2E Use Cases

- [ ] UC1: [Intent] — [one-line summary]
- [ ] UC2: [Intent] — [one-line summary]
```

**Step 2: Restart servers from worktree (CRITICAL if in worktree)**

> ⚠️ **If you're in a worktree**, the development servers are likely still running from the main directory, serving OLD code. You MUST restart them from the worktree to test your changes.

Stop the current development servers and start them from this worktree directory. Use the project's start/stop commands from CLAUDE.md.

Wait for servers to be ready before proceeding.

**Step 3: Execute each use case with Playwright MCP**

For each use case, execute the Steps through the browser:

- Navigate to the starting page
- Perform each user action (click, fill, select, submit)
- Verify the expected outcome is visible
- **Reload the page and confirm persistence**

Check off each use case in CONTINUITY.md as it passes.

**Step 4: Test error paths**

For each error use case:

- Trigger the error condition through the UI
- Verify the user sees an appropriate error message
- Verify no data was corrupted (check the happy path still works)

**DO NOT skip by saying:**

- ❌ "Unit tests cover it" → Unit tests don't test user workflows
- ❌ "It's a small change" → Small changes break real user flows
- ❌ "I'll test it later" → E2E happens now, not after merge

**Only skip if:** Purely internal with zero user-facing impact (must justify in checklist).

**Non-browser projects** (API-only services, CLIs, mobile backends): If there's no web UI to drive, execute use cases via API calls (curl/httpie), CLI commands, or document the manual verification steps. The use case template (Intent, Steps, Verification, Persistence) still applies — just replace "UI interactions" with the appropriate interface.

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
