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
# Contract 6: E2E verified gate — canonical marker vocabulary
#
# The Council (minority report from Contrarian + Maintainer) flagged that
# the "E2E verified" gate string is referenced in multiple places and will
# drift if not contracted. This asserts all references use the same stem.
# ---------------------------------------------------------------------------
start_test "E2E verified gate — canonical marker across files"

# The marker stem that the hook regex matches on — this is the single
# source of truth. Any other file that references the gate must use it.
CANONICAL_STEM="E2E verified"

# Both hook implementations must grep/match for the canonical stem
assert_contains "$REPO_ROOT/hooks/check-workflow-gates.sh" "$CANONICAL_STEM" \
    "check-workflow-gates.sh references '$CANONICAL_STEM'"
assert_contains "$REPO_ROOT/hooks/check-workflow-gates.ps1" "$CANONICAL_STEM" \
    "check-workflow-gates.ps1 references '$CANONICAL_STEM'"

# Workflow command checklists must use the canonical stem (checked or unchecked)
assert_contains "$REPO_ROOT/commands/new-feature.md" "$CANONICAL_STEM" \
    "new-feature.md checklist uses '$CANONICAL_STEM'"
assert_contains "$REPO_ROOT/commands/fix-bug.md" "$CANONICAL_STEM" \
    "fix-bug.md checklist uses '$CANONICAL_STEM'"

# The canonical N/A escape form must match exactly in both commands + rules
# Form: `- [x] E2E verified — N/A: <reason>` (em-dash "—", not double-hyphen)
CANONICAL_NA="E2E verified — N/A:"
assert_contains "$REPO_ROOT/commands/new-feature.md" "$CANONICAL_NA" \
    "new-feature.md uses canonical N/A form ('$CANONICAL_NA')"
assert_contains "$REPO_ROOT/commands/fix-bug.md" "$CANONICAL_NA" \
    "fix-bug.md uses canonical N/A form"
assert_contains "$REPO_ROOT/rules/testing.md" "$CANONICAL_NA" \
    "rules/testing.md uses canonical N/A form (was 'E2E use cases tested' before canonicalization)"

# rules/testing.md must be the canonical documentation — hook stderr
# points there, so the anchor must exist
assert_contains "$REPO_ROOT/rules/testing.md" "Canonical E2E gate vocabulary" \
    "rules/testing.md has the Canonical E2E gate vocabulary section"

# Regression: the old drifting string "E2E use cases tested" must NOT appear
# anywhere as a marker (it's been replaced with "E2E verified")
assert_not_contains "$REPO_ROOT/rules/testing.md" 'E2E use cases tested — N/A' \
    "rules/testing.md no longer uses the old 'E2E use cases tested' N/A form"

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
# Contract 7: Template-drift hint + upgrade-summary parity
#
# Both installers must ship the same drift hint helper AND the same four
# boolean-gated final-summary variants. Without this contract, setup.ps1 can
# silently diverge from setup.sh (bash tests don't execute PowerShell).
# ---------------------------------------------------------------------------
start_test "Template-drift hint + upgrade-summary parity"

SETUP_SH="$REPO_ROOT/setup.sh"
SETUP_PS1="$REPO_ROOT/setup.ps1"

# (i) User-facing drift-hint string
DRIFT_MSG="Template may have drifted"
assert_contains "$SETUP_SH"  "$DRIFT_MSG" "setup.sh contains drift-hint message"
assert_contains "$SETUP_PS1" "$DRIFT_MSG" "setup.ps1 contains drift-hint message"

# (ii) Template filenames referenced
assert_contains "$SETUP_SH"  "CLAUDE.template.md"      "setup.sh references CLAUDE.template.md"
assert_contains "$SETUP_SH"  "CONTINUITY.template.md"  "setup.sh references CONTINUITY.template.md"
assert_contains "$SETUP_PS1" "CLAUDE.template.md"      "setup.ps1 references CLAUDE.template.md"
assert_contains "$SETUP_PS1" "CONTINUITY.template.md"  "setup.ps1 references CONTINUITY.template.md"

# (iii) git diff --no-index suggested (cross-platform, works in Git Bash)
assert_contains "$SETUP_SH"  "git diff --no-index" "setup.sh suggests git diff --no-index"
assert_contains "$SETUP_PS1" "git diff --no-index" "setup.ps1 suggests git diff --no-index"

# (iv) Exact call-site fingerprints — prove helpers are invoked, not dead.
# setup.sh: Bash helper name + positional args
assert_contains "$SETUP_SH" 'print_template_drift_hint "CLAUDE.template.md" "CLAUDE.md"' \
    "setup.sh calls drift-hint helper for CLAUDE.md"
assert_contains "$SETUP_SH" 'print_template_drift_hint "CONTINUITY.template.md" "CONTINUITY.md"' \
    "setup.sh calls drift-hint helper for CONTINUITY.md"
# setup.ps1: PowerShell helper name + positional args
assert_contains "$SETUP_PS1" 'Write-TemplateDriftHint "CLAUDE.template.md" "CLAUDE.md"' \
    "setup.ps1 calls drift-hint helper for CLAUDE.md"
assert_contains "$SETUP_PS1" 'Write-TemplateDriftHint "CONTINUITY.template.md" "CONTINUITY.md"' \
    "setup.ps1 calls drift-hint helper for CONTINUITY.md"

# (v) Final-summary parity: all three positive variants + negative legacy guard
BOTH_VARIANT="Your CLAUDE.md and CONTINUITY.md were preserved (user content)"
CLAUDE_VARIANT="Your CLAUDE.md was preserved (user content)"
CONTINUITY_VARIANT="Your CONTINUITY.md was preserved (user content)"
LEGACY_STRING="were not modified"

assert_contains "$SETUP_SH"  "$BOTH_VARIANT"       "setup.sh has both-preserved final variant"
assert_contains "$SETUP_SH"  "$CLAUDE_VARIANT"     "setup.sh has only-CLAUDE final variant"
assert_contains "$SETUP_SH"  "$CONTINUITY_VARIANT" "setup.sh has only-CONTINUITY final variant"
assert_not_contains "$SETUP_SH" "$LEGACY_STRING"   "setup.sh removed legacy 'were not modified'"

assert_contains "$SETUP_PS1" "$BOTH_VARIANT"       "setup.ps1 has both-preserved final variant"
assert_contains "$SETUP_PS1" "$CLAUDE_VARIANT"     "setup.ps1 has only-CLAUDE final variant"
assert_contains "$SETUP_PS1" "$CONTINUITY_VARIANT" "setup.ps1 has only-CONTINUITY final variant"
assert_not_contains "$SETUP_PS1" "$LEGACY_STRING"  "setup.ps1 removed legacy 'were not modified'"

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
# Contract: no migrated-pattern 'main' references in hooks/* outside the lib helper
#
# SCOPE: this catches ONLY the specific patterns drift-hygiene PR #1 migrated:
#   - `git merge-base main HEAD` (the original hardcoded form in check-state-updated)
#   - `origin/main` referenced as a literal default
#
# It intentionally does NOT catch every possible 'main' reference — e.g., the
# `git merge-base HEAD main` ordering used elsewhere in hooks/* is OUT OF SCOPE
# for PR #1 (different reverse-merge-base computation, different consumer). If a
# future PR migrates more hooks to the helper, tighten this regex (or split into
# per-pattern contracts) at that time.
# ---------------------------------------------------------------------------
start_test "no migrated-pattern 'main' references in hooks/* (outside hooks/lib/)"

HARDCODED=$(grep -rE "merge-base[[:space:]]+main[[:space:]]+HEAD|origin/main[^A-Za-z_]" \
    "$REPO_ROOT/hooks/" 2>/dev/null \
    | grep -v "^$REPO_ROOT/hooks/lib/" || true)

if [[ -z "$HARDCODED" ]]; then
    pass "no migrated-pattern 'main' references in hooks/* (outside lib/)"
else
    while IFS= read -r line; do
        fail "migrated-pattern 'main' detected (should use default-branch helper): $line"
    done <<< "$HARDCODED"
fi

# ---------------------------------------------------------------------------
# Contract: DRIFT-PREFLIGHT-NEW blocks in new-feature.md and fix-bug.md byte-identical
# ---------------------------------------------------------------------------
start_test "DRIFT-PREFLIGHT-NEW blocks byte-identical across new-feature.md and fix-bug.md"

NF="$REPO_ROOT/commands/new-feature.md"
FB="$REPO_ROOT/commands/fix-bug.md"

for f in "$NF" "$FB"; do
    [ -f "$f" ] || { fail "missing command file: $f"; }
done

NF_NEW=$(sed -n '/^# DRIFT-PREFLIGHT-NEW-BEGIN/,/^# DRIFT-PREFLIGHT-NEW-END/p' "$NF")
FB_NEW=$(sed -n '/^# DRIFT-PREFLIGHT-NEW-BEGIN/,/^# DRIFT-PREFLIGHT-NEW-END/p' "$FB")

if [[ -z "$NF_NEW" ]] || [[ -z "$FB_NEW" ]]; then
    fail "DRIFT-PREFLIGHT-NEW markers missing from one or both command files"
elif [[ "$NF_NEW" == "$FB_NEW" ]]; then
    pass "DRIFT-PREFLIGHT-NEW blocks byte-identical"
else
    fail "DRIFT-PREFLIGHT-NEW blocks differ between new-feature.md and fix-bug.md"
    diff <(printf '%s' "$NF_NEW") <(printf '%s' "$FB_NEW") | head -10
fi

# ---------------------------------------------------------------------------
# Contract: DRIFT-PREFLIGHT-ALREADY blocks in new-feature.md and fix-bug.md byte-identical
# ---------------------------------------------------------------------------
start_test "DRIFT-PREFLIGHT-ALREADY blocks byte-identical across new-feature.md and fix-bug.md"

NF_AL=$(sed -n '/^# DRIFT-PREFLIGHT-ALREADY-BEGIN/,/^# DRIFT-PREFLIGHT-ALREADY-END/p' "$NF")
FB_AL=$(sed -n '/^# DRIFT-PREFLIGHT-ALREADY-BEGIN/,/^# DRIFT-PREFLIGHT-ALREADY-END/p' "$FB")

if [[ -z "$NF_AL" ]] || [[ -z "$FB_AL" ]]; then
    fail "DRIFT-PREFLIGHT-ALREADY markers missing from one or both command files"
elif [[ "$NF_AL" == "$FB_AL" ]]; then
    pass "DRIFT-PREFLIGHT-ALREADY blocks byte-identical"
else
    fail "DRIFT-PREFLIGHT-ALREADY blocks differ between new-feature.md and fix-bug.md"
    diff <(printf '%s' "$NF_AL") <(printf '%s' "$FB_AL") | head -10
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
report "test-contracts.sh"
