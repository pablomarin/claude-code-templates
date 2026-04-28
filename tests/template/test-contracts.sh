#!/usr/bin/env bash
# tests/template/test-contracts.sh — cross-file consistency checks.
#
# Catches stringly-typed contracts that span files: e.g., the verify-e2e
# agent's response header defines VERDICT values, and the callers in
# commands/new-feature.md and commands/fix-bug.md must branch on those
# same values. These are exactly the regressions that are easy to ship
# and costly to catch in code review — a contract test makes the link
# between cooperating files explicit and machine-verifiable.
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
# The "E2E verified" gate string is the single source of truth for the
# workflow-gates hook regex. It's referenced in command checklists, rules
# docs, and the hook itself — contract these together so they can't drift.
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
    "rules/testing.md uses canonical N/A form"

# rules/testing.md must be the canonical documentation — hook stderr
# points there, so the anchor must exist
assert_contains "$REPO_ROOT/rules/testing.md" "Canonical E2E gate vocabulary" \
    "rules/testing.md has the Canonical E2E gate vocabulary section"

# Negative assertion: only "E2E verified" is a valid gate marker — no other
# variant string should function as one anywhere in the project.
assert_not_contains "$REPO_ROOT/rules/testing.md" 'E2E use cases tested — N/A' \
    "rules/testing.md uses only the canonical 'E2E verified' marker"

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
# Contract: session-start drift-warning string parity — .sh ↔ .ps1
#
# The drift warning injected into additionalContext is independently composed
# in session-start.sh and session-start.ps1. If the canonical phrasing
# diverges, Windows users see a different warning than macOS/Linux users —
# a silent cross-platform inconsistency. This contract asserts both files
# share the same canonical substrings so the user experience is identical.
# ---------------------------------------------------------------------------
start_test "session-start drift-warning string parity — .sh ↔ .ps1"

SS_SH="$REPO_ROOT/hooks/session-start.sh"
SS_PS1="$REPO_ROOT/hooks/session-start.ps1"

for f in "$SS_SH" "$SS_PS1"; do
    assert_file_exists "$f" "file exists: $f"
done

# Both files must contain the trailing structural phrase that ends the warning.
PULL_PHRASE="pull before starting work"
assert_contains "$SS_SH"  "$PULL_PHRASE" \
    "session-start.sh contains '$PULL_PHRASE'"
assert_contains "$SS_PS1" "$PULL_PHRASE" \
    "session-start.ps1 contains '$PULL_PHRASE'"

# Both files must contain the em-dash + structural phrase that precedes the count.
BEHIND_PHRASE="commits behind origin —"
assert_contains "$SS_SH"  "$BEHIND_PHRASE" \
    "session-start.sh contains '$BEHIND_PHRASE'"
assert_contains "$SS_PS1" "$BEHIND_PHRASE" \
    "session-start.ps1 contains '$BEHIND_PHRASE'"

# ---------------------------------------------------------------------------
# CONTINUITY-split contracts (PR #2)
# ---------------------------------------------------------------------------

# Helper — find a usable PowerShell runtime; skip parity test if none.
detect_pwsh() {
    if command -v pwsh >/dev/null 2>&1; then echo "pwsh"; return 0; fi
    if command -v powershell >/dev/null 2>&1; then echo "powershell"; return 0; fi
    if command -v powershell.exe >/dev/null 2>&1; then echo "powershell.exe"; return 0; fi
    return 1
}

# Helper — count CONTINUITY.md hits in a path, with explicit allowlist for
# files where historical references are intentional (CHANGELOG, upgrading guide,
# troubleshooting migration section).
count_continuity_refs_excluding_allowlist() {
    local search_path="$1"
    grep -rln "CONTINUITY\.md" "$search_path" 2>/dev/null \
        | grep -vE '(docs/CHANGELOG\.md|docs/guides/upgrading\.md|docs/troubleshooting\.md)$' \
        | wc -l | tr -d ' '
}

start_test "no-CONTINUITY-in-hooks"
hits=$(count_continuity_refs_excluding_allowlist "$REPO_ROOT/hooks")
assert_equals "$hits" "0" "no CONTINUITY.md references in hooks/"

start_test "no-CONTINUITY-in-commands"
hits=$(count_continuity_refs_excluding_allowlist "$REPO_ROOT/commands")
assert_equals "$hits" "0" "no CONTINUITY.md references in commands/"

start_test "no-CONTINUITY-in-rules-agents-settings"
total=0
for d in rules agents settings; do
    h=$(count_continuity_refs_excluding_allowlist "$REPO_ROOT/$d")
    total=$((total + h))
done
assert_equals "$total" "0" "no CONTINUITY.md references in rules/, agents/, settings/"

# AC-3 broadened — also cover root templates (Codex P1 finding).
start_test "no-CONTINUITY-in-root-templates"
total=0
for f in CLAUDE.template.md GLOBAL-CLAUDE.template.md state.template.md; do
    [ -f "$REPO_ROOT/$f" ] || continue
    # `grep -c` always prints a count to stdout; rc=1 when 0 matches.
    # Don't chain with `|| echo 0` — that produces double-output and breaks arith.
    n=$(grep -c "CONTINUITY\.md" "$REPO_ROOT/$f" 2>/dev/null)
    [ -z "$n" ] && n=0
    total=$((total + n))
done
assert_equals "$total" "0" "no CONTINUITY.md in root templates (CLAUDE.template.md, GLOBAL-CLAUDE.template.md, state.template.md)"

start_test "hooks-parity-missing-state"
ps_runner=$(detect_pwsh)
if [ -z "$ps_runner" ]; then
    pass "ℹ no PowerShell runtime found (pwsh / powershell / powershell.exe); skipping bash/PS parity test"
else
    scratch=$(mktemp -d)
    ( cd "$scratch" && git init -q )
    sh_out=$(cd "$scratch" && echo '{"tool_input":{"command":"git commit -m x"}}' | bash "$REPO_ROOT/hooks/check-workflow-gates.sh" 2>&1)
    ps_out=$(cd "$scratch" && echo '{"tool_input":{"command":"git commit -m x"}}' | "$ps_runner" -NoProfile -File "$REPO_ROOT/hooks/check-workflow-gates.ps1" 2>&1)
    assert_equals "$sh_out" "$ps_out" "bash and PS check-workflow-gates emit byte-equivalent missing-state breadcrumb"
    rm -rf "$scratch"

    # AC-4 broadened — also cover check-state-updated parity.
    scratch=$(mktemp -d)
    ( cd "$scratch" && git init -q )
    sh_out=$(cd "$scratch" && bash "$REPO_ROOT/hooks/check-state-updated.sh" < /dev/null 2>&1)
    ps_out=$(cd "$scratch" && "$ps_runner" -NoProfile -File "$REPO_ROOT/hooks/check-state-updated.ps1" < /dev/null 2>&1)
    assert_equals "$sh_out" "$ps_out" "bash and PS check-state-updated emit byte-equivalent missing-state breadcrumb"
    rm -rf "$scratch"

    # AC-4 malformed-file parity (state.md exists but missing Command field).
    scratch=$(mktemp -d)
    (
        cd "$scratch" && git init -q && mkdir -p .claude/local && cat > .claude/local/state.md <<'EOF'
# state without Command field
## Workflow
| Field | Value |
| Phase | 3 |
EOF
    )
    sh_out=$(cd "$scratch" && bash "$REPO_ROOT/hooks/check-state-updated.sh" < /dev/null 2>&1)
    ps_out=$(cd "$scratch" && "$ps_runner" -NoProfile -File "$REPO_ROOT/hooks/check-state-updated.ps1" < /dev/null 2>&1)
    assert_equals "$sh_out" "$ps_out" "bash and PS check-state-updated handle malformed state.md identically"
    rm -rf "$scratch"
fi

start_test "adr-template-canonical-5-sections"
headers=$(grep -E "^## " "$REPO_ROOT/docs/adr/template.md" | sort -u)
# Note: sort puts 'Consequences' before 'Considered' (e < i at position 5).
expected="## Consequences
## Considered Options
## Context
## Decision
## Status"
if [ "$headers" = "$expected" ]; then
    pass "ADR template has the canonical 5 sections"
else
    fail "ADR template headers don't match canonical 5: got '$headers'"
fi

start_test "adr-seed-files-canonical-5-sections"
all_ok=true
for f in "$REPO_ROOT"/docs/adr/[0-9][0-9][0-9][0-9]-*.md; do
    [ -f "$f" ] || continue
    for h in "## Status" "## Context" "## Considered Options" "## Decision" "## Consequences"; do
        if ! grep -qF "$h" "$f"; then
            fail "$(basename "$f") missing $h"
            all_ok=false
        fi
    done
done
$all_ok && pass "all docs/adr/NNNN-*.md have the canonical 5 sections"

# AC-2 verification: state.template.md has the canonical schema headers.
start_test "state-template-canonical-schema"
required_headers=(
    "## Workflow"
    "### Checklist"
    "## State"
    "### Done"
    "### Now"
    "### Next"
    "### Deferred"
    "## Open Questions"
    "## Blockers"
    "## Update Rules"
)
all_ok=true
for h in "${required_headers[@]}"; do
    if ! grep -qF "$h" "$REPO_ROOT/state.template.md"; then
        fail "state.template.md missing canonical header: '$h'"
        all_ok=false
    fi
done
# Default Command value must be 'none'.
if grep -qE '\|\s*Command\s*\|\s*none\s*\|' "$REPO_ROOT/state.template.md"; then
    pass "state.template.md default Command is 'none'"
else
    fail "state.template.md default Command is not 'none' (AC-2 violation)"
fi
$all_ok && pass "state.template.md has all canonical schema headers (AC-2)"

# AC-2 byte-identical STATE-INIT contract: the bash block in commands/new-feature.md
# and commands/fix-bug.md between # STATE-INIT-BEGIN and # STATE-INIT-END markers
# must be byte-identical (mirrors the existing DRIFT-PREFLIGHT-NEW contract from PR #1).
start_test "state-init-block-byte-identical-across-commands"
extract_state_init() {
    awk '/^# STATE-INIT-BEGIN/{flag=1} flag{print} /^# STATE-INIT-END/{flag=0}' "$1"
}
nf_block=$(extract_state_init "$REPO_ROOT/commands/new-feature.md")
fb_block=$(extract_state_init "$REPO_ROOT/commands/fix-bug.md")
if [ -z "$nf_block" ]; then fail "STATE-INIT-BEGIN/END markers not found in commands/new-feature.md"
elif [ -z "$fb_block" ]; then fail "STATE-INIT-BEGIN/END markers not found in commands/fix-bug.md"
elif ! echo "$nf_block" | grep -q "state.md"; then fail "STATE-INIT block in new-feature.md doesn't reference state.md (sanity check)"
elif [ "$nf_block" = "$fb_block" ]; then pass "STATE-INIT block byte-identical across new-feature.md and fix-bug.md"
else fail "STATE-INIT block diverges between new-feature.md and fix-bug.md"
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
report "test-contracts.sh"
