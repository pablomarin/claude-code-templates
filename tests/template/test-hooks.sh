#!/usr/bin/env bash
# tests/template/test-hooks.sh — runtime fixture tests for check-workflow-gates.
#
# Feeds synthetic CONTINUITY.md fixtures + JSON stdin into the workflow-gate
# hooks (.sh and .ps1) and asserts exit codes match expectations. Catches the
# "marker text drifted silently, gate passes everything" class of regression
# that the Scalability Hawk flagged during Council.
#
# Run from repo root: bash tests/template/test-hooks.sh

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=lib.sh
source "$REPO_ROOT/tests/template/lib.sh"

init_counters

HOOK_SH="$REPO_ROOT/hooks/check-workflow-gates.sh"
HOOK_PS="$REPO_ROOT/hooks/check-workflow-gates.ps1"

# ---------------------------------------------------------------------------
# Fixture helper: write a CONTINUITY.md with a Workflow table + checklist in
# a scratch dir, run the hook there with a synthetic tool_input JSON, capture
# exit code + stderr.
#
# Usage:
#   run_hook_sh <scratch_dir> <ship_command> <continuity_checklist_body>
#
# `continuity_checklist_body` is everything between "### Checklist" and the
# next "## " heading — pass the checkbox lines only.
# ---------------------------------------------------------------------------
run_hook_sh() {
    local scratch="$1" command="$2" checklist="$3"
    cat > "$scratch/CONTINUITY.md" <<EOF
# CONTINUITY

## Workflow

| Field     | Value              |
| --------- | ------------------ |
| Command   | /new-feature test  |
| Phase     | 5 — Quality Gates  |
| Next step | ship               |

### Checklist

$checklist

## State

### Done

### Now

### Next
EOF
    printf '{"tool_input":{"command":"%s"}}' "$(printf '%s' "$command" | awk 'BEGIN{ORS=""} {gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); print}')" > "$scratch/.hook-input.json"
    # Hook expects to run in the dir that has CONTINUITY.md
    (cd "$scratch" && bash "$HOOK_SH" < "$scratch/.hook-input.json") > "$scratch/.hook-stdout" 2> "$scratch/.hook-stderr"
    echo "$?"
}

run_hook_ps() {
    local scratch="$1" command="$2" checklist="$3"
    if ! command -v pwsh >/dev/null 2>&1; then
        echo "SKIP"
        return
    fi
    cat > "$scratch/CONTINUITY.md" <<EOF
# CONTINUITY

## Workflow

| Field     | Value              |
| --------- | ------------------ |
| Command   | /new-feature test  |
| Phase     | 5 — Quality Gates  |
| Next step | ship               |

### Checklist

$checklist

## State

### Done

### Now

### Next
EOF
    printf '{"tool_input":{"command":"%s"}}' "$(printf '%s' "$command" | awk 'BEGIN{ORS=""} {gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); print}')" > "$scratch/.hook-input.json"
    (cd "$scratch" && pwsh -NoProfile -File "$HOOK_PS" < "$scratch/.hook-input.json") > "$scratch/.hook-stdout" 2> "$scratch/.hook-stderr"
    echo "$?"
}

# ===========================================================================
# Test 1: all gates checked → hook passes (exit 0)
# ===========================================================================
start_test "all gates checked [x] → exit 0"

CHECKLIST_ALL_CHECKED='- [x] Code review loop (2 iterations) — PASS
- [x] Simplified
- [x] Verified (tests/lint/types)
- [x] E2E verified via verify-e2e agent (Phase 5.4)'

S1=$(scratch_dir hooks-allchecked)
rc=$(run_hook_sh "$S1" 'git commit -m "ship it"' "$CHECKLIST_ALL_CHECKED")
assert_equals "$rc" "0" ".sh passes when all gates are [x]"

# ===========================================================================
# Test 2: E2E verified unchecked → hook blocks (exit 2)
# This is the msai-v2 root cause — the whole reason this suite exists.
# ===========================================================================
start_test "E2E verified [ ] unchecked → exit 2 (blocks ship)"

CHECKLIST_E2E_UNCHECKED='- [x] Code review loop (2 iterations) — PASS
- [x] Simplified
- [x] Verified (tests/lint/types)
- [ ] E2E verified via verify-e2e agent (Phase 5.4)'

S2=$(scratch_dir hooks-e2e-unchecked)
rc=$(run_hook_sh "$S2" 'git commit -m "ship it"' "$CHECKLIST_E2E_UNCHECKED")
assert_equals "$rc" "2" ".sh blocks when E2E verified is unchecked"
assert_contains "$S2/.hook-stderr" "E2E verified" \
    "stderr names the missing gate"
assert_contains "$S2/.hook-stderr" "rules/testing.md" \
    "stderr points to canonical doc"
assert_contains "$S2/.hook-stderr" "verify-e2e agent" \
    "stderr tells user how to clear the gate"

# ===========================================================================
# Test 3: E2E verified checked with N/A reason → hook passes (exit 0)
# Verifies the escape valve works as documented.
# ===========================================================================
start_test "E2E verified [x] — N/A: <reason> → exit 0"

CHECKLIST_E2E_NA='- [x] Code review loop (1 iterations) — PASS
- [x] Simplified
- [x] Verified (tests/lint/types)
- [x] E2E verified — N/A: internal migration, no user-facing changes'

S3=$(scratch_dir hooks-e2e-na)
rc=$(run_hook_sh "$S3" 'git commit -m "shipit"' "$CHECKLIST_E2E_NA")
assert_equals "$rc" "0" ".sh passes when E2E verified is [x] with N/A"

# ===========================================================================
# Test 4: multiple gates unchecked → stderr enumerates all of them
# ===========================================================================
start_test "multiple gates unchecked → all listed in stderr"

CHECKLIST_MULTI='- [ ] Code review loop
- [x] Simplified
- [ ] Verified (tests/lint/types)
- [ ] E2E verified via verify-e2e agent (Phase 5.4)'

S4=$(scratch_dir hooks-multi)
rc=$(run_hook_sh "$S4" 'gh pr create' "$CHECKLIST_MULTI")
assert_equals "$rc" "2" ".sh blocks when 3 gates unchecked"
assert_contains "$S4/.hook-stderr" "Code review loop" \
    "stderr lists 'Code review loop'"
assert_contains "$S4/.hook-stderr" "Verified" \
    "stderr lists 'Verified'"
assert_contains "$S4/.hook-stderr" "E2E verified" \
    "stderr lists 'E2E verified'"

# ===========================================================================
# Test 5: non-ship command (e.g., 'ls -la') → hook allows immediately
# (regression guard: adding the E2E gate didn't widen the ship-detection)
# ===========================================================================
start_test "non-ship command → exit 0 regardless of checklist"

S5=$(scratch_dir hooks-nonship)
rc=$(run_hook_sh "$S5" 'ls -la' "$CHECKLIST_E2E_UNCHECKED")
assert_equals "$rc" "0" ".sh allows 'ls -la' even with gates unchecked"

# ===========================================================================
# Test 6: no active workflow (Command=none) → hook allows
# ===========================================================================
start_test "Command=none → hook passes even with unchecked gates"

S6=$(scratch_dir hooks-noworkflow)
cat > "$S6/CONTINUITY.md" <<EOF
# CONTINUITY

## Workflow

| Field     | Value |
| --------- | ----- |
| Command   | none  |

### Checklist

- [ ] E2E verified via verify-e2e agent (Phase 5.4)

## State
EOF
printf '{"tool_input":{"command":"git commit -m test"}}' > "$S6/.hook-input.json"
(cd "$S6" && bash "$HOOK_SH" < "$S6/.hook-input.json") > "$S6/.hook-stdout" 2> "$S6/.hook-stderr"
assert_equals "$?" "0" ".sh passes when workflow is inactive (Command=none)"

# ===========================================================================
# Test 7: non-gate items that contain similar words → NOT gated
# "PR reviews addressed", "Plugins verified", "Plan review loop",
# "E2E use cases designed", "E2E regression passed"
# ===========================================================================
start_test "non-gate items with similar words are NOT gated"

CHECKLIST_NEAR_MISS='- [x] Code review loop (1 iterations) — PASS
- [x] Simplified
- [x] Verified (tests/lint/types)
- [x] E2E verified — N/A: pure refactor
- [ ] E2E use cases designed (Phase 3.2b)
- [ ] E2E regression passed (Phase 5.4b)
- [ ] PR reviews addressed
- [ ] Plugins verified
- [ ] Plan review loop (0 iterations)'

S7=$(scratch_dir hooks-near-miss)
rc=$(run_hook_sh "$S7" 'git push' "$CHECKLIST_NEAR_MISS")
assert_equals "$rc" "0" "non-gate items don't trigger the gate"

# ===========================================================================
# Test 8: PowerShell parity — same fixtures, same expected exit codes
# (skipped if pwsh not installed, so this doesn't break macOS/Linux CI
# boxes without PowerShell)
# ===========================================================================
start_test "PowerShell parity (.ps1 matches .sh on the same fixtures)"

if command -v pwsh >/dev/null 2>&1; then
    S8a=$(scratch_dir hooks-ps-allchecked)
    rc=$(run_hook_ps "$S8a" 'git commit -m x' "$CHECKLIST_ALL_CHECKED")
    assert_equals "$rc" "0" ".ps1 passes when all gates [x]"

    S8b=$(scratch_dir hooks-ps-e2e-unchecked)
    rc=$(run_hook_ps "$S8b" 'git commit -m x' "$CHECKLIST_E2E_UNCHECKED")
    assert_equals "$rc" "2" ".ps1 blocks when E2E verified unchecked"
    assert_contains "$S8b/.hook-stderr" "E2E verified" \
        ".ps1 stderr names the missing gate"

    S8c=$(scratch_dir hooks-ps-e2e-na)
    rc=$(run_hook_ps "$S8c" 'git commit -m x' "$CHECKLIST_E2E_NA")
    assert_equals "$rc" "0" ".ps1 passes when E2E verified [x] — N/A"
else
    printf "  %s·%s skipped: pwsh not installed\n" "$C_DIM" "$C_RESET"
fi

# ===========================================================================
# Evidence-gate scenarios (Phase 2 — closes the paperwork-not-evidence loophole)
# These require a real git repo with a branch-off point, so each test sets up
# a scratch repo with main + feature branch before invoking the hook.
# ===========================================================================

# Helper: build a scratch git repo with main + feature branch.
# Feature branch's HEAD is where we're "at"; main's last commit is the
# branch-off point whose timestamp the hook compares against.
# Echoes the scratch dir path.
setup_git_scratch() {
    local dir
    dir=$(scratch_dir e2e-evidence)
    (
        cd "$dir" || exit 1
        git init -q --initial-branch=main
        git -c user.email=test@test -c user.name=test commit -q --allow-empty -m "initial-on-main"
        # Wait a second so branch-off timestamp is strictly less than
        # any files we create post-checkout (avoids flaky == comparisons
        # on fast CPUs).
        sleep 1
        git checkout -q -b feature/test
        # Real feature branches have at least one commit beyond the
        # branch-off point. Without this, HEAD == merge-base and the
        # evidence check would (correctly) skip as "on main directly"
        # — making the feature-branch tests no-ops.
        git -c user.email=test@test -c user.name=test commit -q --allow-empty -m "feature work"
    )
    echo "$dir"
}

# Helper: inject an E2E verified [x] entry into the checklist template.
CHECKLIST_E2E_CHECKED_NO_NA='- [x] Code review loop (1 iterations) — PASS
- [x] Simplified
- [x] Verified (tests/lint/types)
- [x] E2E verified via verify-e2e agent (Phase 5.4)'

CHECKLIST_E2E_CHECKED_NA='- [x] Code review loop (1 iterations) — PASS
- [x] Simplified
- [x] Verified (tests/lint/types)
- [x] E2E verified — N/A: internal migration, no user-facing changes'

# ===========================================================================
# Test 9: [x] E2E verified without N/A + fresh report → exit 0
# ===========================================================================
start_test "[x] E2E verified + fresh report → exit 0 (evidence satisfied)"

S9=$(setup_git_scratch)
mkdir -p "$S9/tests/e2e/reports"
# Create a report file AFTER branch-off (its mtime is > branch-off-ts)
echo "# E2E report" > "$S9/tests/e2e/reports/2026-04-19-10-00-feature.md"
rc=$(run_hook_sh "$S9" 'git commit -m x' "$CHECKLIST_E2E_CHECKED_NO_NA")
assert_equals "$rc" "0" "fresh report present → hook passes"

# ===========================================================================
# Test 10: [x] E2E verified without N/A + no report → exit 2
# ===========================================================================
start_test "[x] E2E verified + no report → exit 2 (evidence missing)"

S10=$(setup_git_scratch)
# No tests/e2e/reports/ directory at all
rc=$(run_hook_sh "$S10" 'git commit -m x' "$CHECKLIST_E2E_CHECKED_NO_NA")
assert_equals "$rc" "2" "no reports dir → hook blocks"
assert_contains "$S10/.hook-stderr" "no fresh report was found" \
    "stderr explains the evidence gap"
assert_contains "$S10/.hook-stderr" "verify-e2e agent was never actually run" \
    "stderr explains the likely cause"
assert_contains "$S10/.hook-stderr" "E2E verified — N/A:" \
    "stderr shows the N/A escape syntax"

# ===========================================================================
# Test 11: [x] E2E verified without N/A + STALE report (pre-branch-off) → exit 2
# ===========================================================================
start_test "[x] E2E verified + only stale reports → exit 2"

S11=$(setup_git_scratch)
mkdir -p "$S11/tests/e2e/reports"
echo "# old report" > "$S11/tests/e2e/reports/2024-01-01-old.md"
# Force mtime to 2024-01-01 — definitely before any branch-off we just made
touch -t 202401010000.00 "$S11/tests/e2e/reports/2024-01-01-old.md"
rc=$(run_hook_sh "$S11" 'git commit -m x' "$CHECKLIST_E2E_CHECKED_NO_NA")
assert_equals "$rc" "2" "only stale reports → hook blocks"

# ===========================================================================
# Test 12: [x] E2E verified — N/A: reason → exit 0 (no evidence needed)
# ===========================================================================
start_test "[x] E2E verified — N/A: reason → exit 0 (N/A bypasses evidence check)"

S12=$(setup_git_scratch)
# No reports directory — N/A should bypass the evidence check entirely
rc=$(run_hook_sh "$S12" 'git commit -m x' "$CHECKLIST_E2E_CHECKED_NA")
assert_equals "$rc" "0" "N/A form skips evidence check even without a report"

# ===========================================================================
# Test 13: No merge-base (repo without main) → skip evidence check gracefully
# ===========================================================================
start_test "no merge-base available → skip evidence check (degraded env)"

S13=$(scratch_dir e2e-nomaster)
(
    cd "$S13" || exit 1
    git init -q --initial-branch=weird
    git -c user.email=test@test -c user.name=test commit -q --allow-empty -m "initial"
)
# No main, no master. Hook can't compute merge-base; should skip evidence
# rather than fail. User gets no protection here — documented as a
# degraded env, not a policy violation.
rc=$(run_hook_sh "$S13" 'git commit -m x' "$CHECKLIST_E2E_CHECKED_NO_NA")
assert_equals "$rc" "0" "degraded env (no main/master) → hook passes with warning"

# ===========================================================================
# Test 14: On main itself → skip evidence check (trunk-based workflow)
# Regression guard for Codex's P1: git merge-base HEAD main returns HEAD
# when on main, which is NOT empty. Without special-case handling, the
# hook would require reports newer than HEAD — which is usually impossible
# because reports are produced AFTER HEAD, not before.
# ===========================================================================
start_test "user on main → skip evidence check (trunk-based)"

S14=$(scratch_dir e2e-on-main)
(
    cd "$S14" || exit 1
    git init -q --initial-branch=main
    git -c user.email=test@test -c user.name=test commit -q --allow-empty -m "initial"
    # STAY on main — no feature branch checkout.
)
# [x] E2E verified without N/A + no reports. Without the HEAD==branch-off
# fix, this would block. With the fix, it should pass (skip evidence).
rc=$(run_hook_sh "$S14" 'git commit -m x' "$CHECKLIST_E2E_CHECKED_NO_NA")
assert_equals "$rc" "0" "on main directly → evidence check skipped (trunk-based workflow supported)"

# ===========================================================================
# Test 15: check-state-updated.sh master-default repo — CHANGELOG gate fires
# correctly when default branch is "master" (not "main").
#
# Regression guard for the pre-migration hook (hardcoded `main`):
#   - Pre-migration: `git merge-base main HEAD` → empty (no main branch)
#     → BRANCH_BASE falls back to HEAD~10 → wrong baseline → count wrong
#   - Post-migration: default-branch.sh detects "master" → correct
#     merge-base → BRANCH_CHANGED >= 4 → CHANGELOG gate fires (exit 2)
# ===========================================================================
start_test "check-state-updated.sh: master-default repo → CHANGELOG gate fires (exit 2)"

HOOK_STATE="$REPO_ROOT/hooks/check-state-updated.sh"

# Build a scratch repo with master as the default branch, no main branch.
# Feature branch has 4 committed files in subdirs → BRANCH_CHANGED = 4 > 3.
# No CHANGELOG entry anywhere → gate fires.
S15=$(scratch_dir state-master-default)
(
    cd "$S15" || exit 1
    git init -q
    git -c user.email=test@test -c user.name=test checkout -q -b master
    git -c user.email=test@test -c user.name=test commit -q --allow-empty -m "initial on master"
    git -c user.email=test@test -c user.name=test checkout -q -b feature/x
    # Add 4 files in subdirs (not gitignored) as tracked+committed on the feature branch.
    # git status --porcelain on these committed files shows nothing (already clean),
    # but git diff --name-only master..HEAD counts all 4 for BRANCH_CHANGED.
    mkdir -p src/a src/b
    printf 'x' > src/a/file1.txt
    printf 'x' > src/a/file2.txt
    printf 'x' > src/b/file3.txt
    printf 'x' > src/b/file4.txt
    git add src/
    git -c user.email=test@test -c user.name=test commit -q -m "feature work: 4 files"
)

# Write a minimal CONTINUITY.md (no active workflow, no CHANGELOG entry).
cat > "$S15/CONTINUITY.md" <<'CONT'
# CONTINUITY

## State

### Done
- Some work done

### Now
Working on feature/x

### Next
Nothing
CONT

# Run check-state-updated.sh from the scratch repo.
# stdin: '{"stop_hook_active":false}' (mirrors real Stop hook input).
rc15=$(printf '{"stop_hook_active":false}' | (cd "$S15" && bash "$HOOK_STATE") 2>"$S15/.state-stderr"; echo "$?")
assert_equals "$rc15" "2" "CHANGELOG gate fires on master-default repo (exit 2)"
assert_contains "$S15/.state-stderr" "CHANGELOG" \
    "stderr mentions CHANGELOG threshold"

# ===========================================================================
# Report
# ===========================================================================
report "test-hooks.sh"
