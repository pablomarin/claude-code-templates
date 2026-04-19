#!/usr/bin/env bash
# tests/template/test-contracts.sh — cross-file consistency checks.
#
# Catches stringly-typed contracts that span files: e.g., the verify-e2e
# agent's response header defines VERDICT values, and the callers in
# commands/new-feature.md and commands/fix-bug.md must branch on those
# same values. Codex called deferring this "false economy" because the
# bug is exactly the kind of regression that's easy to ship and costly
# to catch.
#
# Run from repo root:  bash tests/template/test-contracts.sh

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=lib.sh
source "$REPO_ROOT/tests/template/lib.sh"

init_counters

# ---------------------------------------------------------------------------
# Contract 1: verify-e2e VERDICT values must match caller branches
# ---------------------------------------------------------------------------
start_test "verify-e2e VERDICT header ↔ caller branch labels"

VE2E="$REPO_ROOT/agents/verify-e2e.md"
NF="$REPO_ROOT/commands/new-feature.md"
FB="$REPO_ROOT/commands/fix-bug.md"

for f in "$VE2E" "$NF" "$FB"; do
    assert_file_exists "$f" "file exists: $f"
done

# Pull the set of VERDICT values defined in verify-e2e.md.
# Looks for lines like: VERDICT: PASS | FAIL | PARTIAL
VERDICT_LINE=$(grep -E "^VERDICT:\s*(PASS|FAIL|PARTIAL)" "$VE2E" | head -1)
if [[ -z "$VERDICT_LINE" ]]; then
    fail "could not find VERDICT: header definition in verify-e2e.md"
else
    pass "found VERDICT header in verify-e2e.md"
fi

# Extract the named values (PASS, FAIL, PARTIAL) from the header line.
# Treat this as the authoritative vocabulary.
VERDICT_VALUES=$(echo "$VERDICT_LINE" | grep -oE "(PASS|FAIL|PARTIAL)" | sort -u)

# For each value in the authoritative set, the callers should have
# branching logic that references it (we look for 'VERDICT: <VAL>' which
# is how the caller docs reference each branch).
for val in $VERDICT_VALUES; do
    if grep -qF "VERDICT: $val" "$NF"; then
        pass "commands/new-feature.md branches on VERDICT: $val"
    else
        fail "commands/new-feature.md missing branch for VERDICT: $val"
    fi
    if grep -qF "VERDICT: $val" "$FB"; then
        pass "commands/fix-bug.md branches on VERDICT: $val"
    else
        fail "commands/fix-bug.md missing branch for VERDICT: $val"
    fi
done

# Reverse check: the callers must NOT branch on values that aren't in the
# agent's vocabulary (catches the bug Codex found where callers still
# branched on FAIL_BUG/FAIL_STALE/FAIL_INFRA after the header was reduced
# to PASS/FAIL/PARTIAL).
# FAIL_BUG etc. are legitimate per-UC classification labels that appear
# IN THE BODY. They just shouldn't be used as VERDICT: branch names.
#
# macOS sed -E does NOT support \s; use [[:space:]] for portability.
# Also: `grep -o` across multiple files prefixes output with `file:`, so
# the sed pattern strips everything up through `VERDICT: ` literally.
UNKNOWN_BRANCHES=$(grep -oE 'VERDICT: [A-Z_]+' "$NF" "$FB" \
    | sed -E 's/.*VERDICT:[[:space:]]+//' \
    | sort -u \
    | grep -vE '^(PASS|FAIL|PARTIAL)$' || true)

if [[ -z "$UNKNOWN_BRANCHES" ]]; then
    pass "callers reference only valid VERDICT values (PASS/FAIL/PARTIAL)"
else
    while read -r bad; do
        fail "caller references unknown VERDICT: '$bad' (not in agent header)"
    done <<< "$UNKNOWN_BRANCHES"
fi

# ---------------------------------------------------------------------------
# Contract 2: SUGGESTED_PATH header must be consumed by callers
# ---------------------------------------------------------------------------
start_test "SUGGESTED_PATH header ↔ caller persistence instructions"

# Agent defines SUGGESTED_PATH in its response header.
assert_contains "$VE2E" "SUGGESTED_PATH:" \
    "agent response defines SUGGESTED_PATH"

# Callers must reference it to know where to persist the report.
assert_contains "$NF" "SUGGESTED_PATH" \
    "commands/new-feature.md references SUGGESTED_PATH"
assert_contains "$FB" "SUGGESTED_PATH" \
    "commands/fix-bug.md references SUGGESTED_PATH"

# And both callers must mkdir the reports dir (otherwise Write fails on
# first run).
assert_contains "$NF" "mkdir -p tests/e2e/reports" \
    "commands/new-feature.md creates reports dir"
assert_contains "$FB" "mkdir -p tests/e2e/reports" \
    "commands/fix-bug.md creates reports dir"

# ---------------------------------------------------------------------------
# Contract 3: --playwright-dir marker file ↔ command consumers
# setup.sh writes .claude/playwright-dir. Commands must read it.
# ---------------------------------------------------------------------------
start_test ".claude/playwright-dir marker ↔ command consumers"

assert_contains "$REPO_ROOT/setup.sh" ".claude/playwright-dir" \
    "setup.sh writes marker file"
assert_contains "$REPO_ROOT/setup.ps1" "playwright-dir" \
    "setup.ps1 writes marker file (Windows parity)"
assert_contains "$NF" ".claude/playwright-dir" \
    "commands/new-feature.md reads marker file"
assert_contains "$FB" ".claude/playwright-dir" \
    "commands/fix-bug.md reads marker file"

# ---------------------------------------------------------------------------
# Contract 5: runtime preflight parity — both installers check the same files
# and document the same canonical guide. Prevents one platform from silently
# diverging.
# ---------------------------------------------------------------------------
start_test "Runtime preflight parity — setup.sh ↔ setup.ps1"

for file in ".python-version" ".nvmrc" "package.json" "multi-project-isolation.md"; do
    assert_contains "$REPO_ROOT/setup.sh" "$file" \
        "setup.sh references $file"
    assert_contains "$REPO_ROOT/setup.ps1" "$file" \
        "setup.ps1 references $file"
done

# The guide itself must exist (warnings point to it)
assert_file_exists "$REPO_ROOT/docs/guides/multi-project-isolation.md" \
    "canonical isolation guide exists"

# ---------------------------------------------------------------------------
# Contract 4: CI template placeholder ↔ setup.sh substitution
# ---------------------------------------------------------------------------
start_test "__PLAYWRIGHT_DIR__ placeholder ↔ setup.sh substitution"

CI_TEMPLATE="$REPO_ROOT/templates/ci-workflows/e2e.yml"
assert_contains "$CI_TEMPLATE" "__PLAYWRIGHT_DIR__" \
    "CI template contains placeholder"
assert_contains "$REPO_ROOT/setup.sh" "__PLAYWRIGHT_DIR__" \
    "setup.sh references placeholder"
assert_contains "$REPO_ROOT/setup.ps1" "__PLAYWRIGHT_DIR__" \
    "setup.ps1 references placeholder"

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
report "test-contracts.sh"
