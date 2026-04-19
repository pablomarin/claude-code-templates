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
# Report
# ===========================================================================
report "test-hooks.sh"
