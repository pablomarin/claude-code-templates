#!/usr/bin/env bash
# tests/template/test-setup.sh — behavior tests for setup.sh --with-playwright.
#
# Exercises the real setup.sh against scratch project layouts to confirm
# monorepo detection, stamping, idempotency, force-refresh, metachar
# handling, and --upgrade merge behavior.
#
# Run from repo root:  bash tests/template/test-setup.sh

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=lib.sh
source "$REPO_ROOT/tests/template/lib.sh"

init_counters

# ---------------------------------------------------------------------------
# Helper: set up a minimal scratch project. Layout can be:
#   flat        — package.json at root
#   frontend    — frontend/package.json
#   multi       — frontend/ AND apps/web/ both have package.json
#   custom      — apps/dashboard/package.json
#   metachar    — apps/r&d/package.json (for literal-substitution test)
# ---------------------------------------------------------------------------
make_project() {
    local dir="$1" layout="$2"
    mkdir -p "$dir"
    (cd "$dir" && git init -q)

    case "$layout" in
        flat)
            echo '{"name":"flat-test"}' > "$dir/package.json"
            ;;
        frontend)
            mkdir -p "$dir/frontend"
            echo '{"name":"fe-test"}' > "$dir/frontend/package.json"
            ;;
        multi)
            mkdir -p "$dir/frontend" "$dir/apps/web"
            echo '{"name":"fe"}' > "$dir/frontend/package.json"
            echo '{"name":"web"}' > "$dir/apps/web/package.json"
            ;;
        custom)
            mkdir -p "$dir/apps/dashboard"
            echo '{"name":"dashboard"}' > "$dir/apps/dashboard/package.json"
            ;;
        metachar)
            mkdir -p "$dir/apps/r&d"
            echo '{"name":"rnd"}' > "$dir/apps/r&d/package.json"
            ;;
    esac
}

# ===========================================================================
# Test 1: flat layout — scaffolds at repo root
# ===========================================================================
start_test "Test 1: flat layout → playwright at root"

S1=$(scratch_dir flat)
make_project "$S1" flat
LOG1="$S1/.setup.log"

run_setup "$S1" "$LOG1" -p "FlatTest" -t fullstack --with-playwright
assert_equals "$?" "0" "setup exits 0 on flat layout"

assert_file_exists "$S1/playwright.config.ts" \
    "playwright.config.ts scaffolded at root"
assert_file_exists "$S1/tests/e2e/fixtures/auth.ts" \
    "auth fixture scaffolded at root"
assert_dir_exists "$S1/tests/e2e/specs" \
    "specs dir scaffolded at root"
assert_file_exists "$S1/.claude/playwright-dir" \
    "playwright-dir marker exists"
assert_equals "$(cat "$S1/.claude/playwright-dir")" "." \
    "marker records '.' for flat layout"
assert_file_exists "$S1/docs/ci-templates/e2e.yml" \
    "CI template scaffolded"
assert_contains "$S1/docs/ci-templates/e2e.yml" "working-directory: ." \
    "CI template stamped with '.'"
assert_not_contains "$S1/docs/ci-templates/e2e.yml" "__PLAYWRIGHT_DIR__" \
    "no placeholder leak in CI template"

# ===========================================================================
# Test 2: frontend/ auto-detect
# ===========================================================================
start_test "Test 2: frontend/ subdir → auto-detect"

S2=$(scratch_dir frontend)
make_project "$S2" frontend
LOG2="$S2/.setup.log"

run_setup "$S2" "$LOG2" -p "FeTest" -t fullstack --with-playwright
assert_equals "$?" "0" "setup exits 0 on frontend/ layout"

assert_file_exists "$S2/frontend/playwright.config.ts" \
    "playwright.config.ts scaffolded to frontend/"
assert_file_missing "$S2/playwright.config.ts" \
    "no playwright.config.ts at root"
assert_equals "$(cat "$S2/.claude/playwright-dir")" "frontend" \
    "marker records 'frontend'"
assert_contains "$S2/docs/ci-templates/e2e.yml" "working-directory: frontend" \
    "CI template stamped with 'frontend'"

# ===========================================================================
# Test 3: multiple candidates → fall back to root with warning
# ===========================================================================
start_test "Test 3: multi-candidate → root fallback with warning"

S3=$(scratch_dir multi)
make_project "$S3" multi
LOG3="$S3/.setup.log"

run_setup "$S3" "$LOG3" -p "MultiTest" -t fullstack --with-playwright
assert_equals "$?" "0" "setup exits 0 on multi-candidate layout"

assert_matches "$LOG3" "Multiple frontend candidates" \
    "warning printed for ambiguous layout"
assert_file_exists "$S3/playwright.config.ts" \
    "playwright.config.ts fallback to root"
assert_equals "$(cat "$S3/.claude/playwright-dir")" "." \
    "marker records '.' on fallback"

# ===========================================================================
# Test 4: --playwright-dir override
# ===========================================================================
start_test "Test 4: --playwright-dir apps/dashboard override"

S4=$(scratch_dir custom)
make_project "$S4" custom
LOG4="$S4/.setup.log"

run_setup "$S4" "$LOG4" -p "CustomTest" -t fullstack \
    --with-playwright --playwright-dir apps/dashboard
assert_equals "$?" "0" "setup exits 0 on --playwright-dir override"

assert_file_exists "$S4/apps/dashboard/playwright.config.ts" \
    "playwright.config.ts scaffolded to apps/dashboard/"
assert_equals "$(cat "$S4/.claude/playwright-dir")" "apps/dashboard" \
    "marker records 'apps/dashboard'"
assert_contains "$S4/docs/ci-templates/e2e.yml" "working-directory: apps/dashboard" \
    "CI template stamped with 'apps/dashboard'"

# ===========================================================================
# Test 5: metachar path (apps/r&d) — literal substitution
# This is the bug Codex reproduced: awk's gsub (and sed) interpret '&' as
# the matched text, so path becomes 'apps/r__PLAYWRIGHT_DIR__d'. Confirm
# the bash-param-expansion fix handles this correctly.
# ===========================================================================
start_test "Test 5: --playwright-dir 'apps/r&d' → literal substitution"

S5=$(scratch_dir metachar)
make_project "$S5" metachar
LOG5="$S5/.setup.log"

run_setup "$S5" "$LOG5" -p "MetaTest" -t fullstack \
    --with-playwright --playwright-dir 'apps/r&d'
assert_equals "$?" "0" "setup exits 0 with metachar path"

assert_equals "$(cat "$S5/.claude/playwright-dir")" "apps/r&d" \
    "marker records literal 'apps/r&d'"
assert_contains "$S5/docs/ci-templates/e2e.yml" "working-directory: apps/r&d" \
    "CI template contains literal 'apps/r&d'"
assert_not_contains "$S5/docs/ci-templates/e2e.yml" "__PLAYWRIGHT_DIR__" \
    "& did not expand to matched placeholder"

# ===========================================================================
# Test 6: idempotency — rerun without -f must not clobber CI templates
# (hash specific files, not the whole tree, to avoid flake from .claude/
# playwright-dir rewrites, CLAUDE.md in-place seds, etc.)
# ===========================================================================
start_test "Test 6: idempotent rerun preserves CI template"

S6=$(scratch_dir idem)
make_project "$S6" frontend
LOG6a="$S6/.setup.1.log"
LOG6b="$S6/.setup.2.log"

run_setup "$S6" "$LOG6a" -p "IdemTest" -t fullstack --with-playwright
assert_equals "$?" "0" "initial setup exits 0"

# Capture hashes of the stamped files
HASH_YML_BEFORE=$(hash_file "$S6/docs/ci-templates/e2e.yml")
HASH_MD_BEFORE=$(hash_file "$S6/docs/ci-templates/README.md")
HASH_PWCFG_BEFORE=$(hash_file "$S6/frontend/playwright.config.ts")

# Simulate a user edit to the CI template to ensure it isn't clobbered
echo "# USER EDIT SENTINEL" >> "$S6/docs/ci-templates/e2e.yml"
HASH_YML_EDITED=$(hash_file "$S6/docs/ci-templates/e2e.yml")

# Rerun without -f
run_setup "$S6" "$LOG6b" -p "IdemTest" -t fullstack --with-playwright
assert_equals "$?" "0" "rerun exits 0"

assert_hash_equals "$S6/docs/ci-templates/e2e.yml" "$HASH_YML_EDITED" \
    "CI template preserves user edit on rerun (no -f)"
assert_hash_equals "$S6/docs/ci-templates/README.md" "$HASH_MD_BEFORE" \
    "CI template README unchanged on rerun"
assert_hash_equals "$S6/frontend/playwright.config.ts" "$HASH_PWCFG_BEFORE" \
    "playwright.config.ts unchanged on rerun"

# ===========================================================================
# Test 7: -f force refresh overwrites user edits
# ===========================================================================
start_test "Test 7: -f forces CI template refresh"

LOG6c="$S6/.setup.3.log"
run_setup "$S6" "$LOG6c" -p "IdemTest" -t fullstack --with-playwright -f
assert_equals "$?" "0" "setup with -f exits 0"

# After -f, user sentinel should be gone (template refreshed from source)
assert_not_contains "$S6/docs/ci-templates/e2e.yml" "USER EDIT SENTINEL" \
    "-f refreshes CI template (user edit overwritten)"
assert_hash_equals "$S6/docs/ci-templates/e2e.yml" "$HASH_YML_BEFORE" \
    "CI template hash matches original after -f"

# ===========================================================================
# Test 8: --upgrade smoke — the actual downstream pain path
# Also exercises the "user content is never clobbered" invariant: CLAUDE.md,
# CONTINUITY.md, AND docs/CHANGELOG.md must survive -f and --upgrade intact.
# ===========================================================================
start_test "Test 8: --upgrade smoke on existing install"

S8=$(scratch_dir upgrade)
make_project "$S8" frontend
LOG8a="$S8/.setup.install.log"
LOG8b="$S8/.setup.upgrade.log"
LOG8c="$S8/.setup.force.log"

# Initial install
run_setup "$S8" "$LOG8a" -p "UpgradeTest" -t fullstack --with-playwright
assert_equals "$?" "0" "initial install exits 0"
assert_file_exists "$S8/.claude/commands/new-feature.md" \
    "initial install populated .claude/commands"
assert_file_exists "$S8/docs/CHANGELOG.md" \
    "initial install created docs/CHANGELOG.md"

# Simulate the user actually using CHANGELOG and CLAUDE.md — they add their
# own release entries and project notes. This is the content that MUST NOT
# be wiped on later upgrade/force.
CHANGELOG_SENTINEL="## 1.2.3 — USER RELEASE ENTRY SENTINEL"
echo "$CHANGELOG_SENTINEL" >> "$S8/docs/CHANGELOG.md"
CLAUDE_SENTINEL="## USER-OWNED PROJECT NOTE SENTINEL"
echo "$CLAUDE_SENTINEL" >> "$S8/CLAUDE.md"
HASH_CHANGELOG=$(hash_file "$S8/docs/CHANGELOG.md")
HASH_CLAUDE=$(hash_file "$S8/CLAUDE.md")

# Run --upgrade — the downstream pain path
run_setup "$S8" "$LOG8b" --upgrade
assert_equals "$?" "0" "--upgrade exits 0"
assert_file_exists "$S8/.claude/commands/new-feature.md" \
    ".claude/commands still present after --upgrade"
assert_file_exists "$S8/CLAUDE.md" \
    "CLAUDE.md preserved by --upgrade"
assert_contains "$S8/CLAUDE.md" "USER-OWNED PROJECT NOTE SENTINEL" \
    "--upgrade preserves user content in CLAUDE.md"
assert_contains "$S8/docs/CHANGELOG.md" "USER RELEASE ENTRY SENTINEL" \
    "--upgrade preserves user entries in docs/CHANGELOG.md"
assert_hash_equals "$S8/docs/CHANGELOG.md" "$HASH_CHANGELOG" \
    "--upgrade does not touch CHANGELOG at all"
assert_hash_equals "$S8/CLAUDE.md" "$HASH_CLAUDE" \
    "--upgrade does not touch CLAUDE.md at all"

# Also verify -f (force) preserves user content. -f is the big hammer that
# SHOULD refresh .claude/* and CI templates, but MUST still leave CLAUDE.md,
# CONTINUITY.md, and docs/CHANGELOG.md alone — they are user content.
run_setup "$S8" "$LOG8c" -p "UpgradeTest" -t fullstack --with-playwright -f
assert_equals "$?" "0" "-f exits 0"
assert_hash_equals "$S8/docs/CHANGELOG.md" "$HASH_CHANGELOG" \
    "-f does not touch CHANGELOG"
assert_hash_equals "$S8/CLAUDE.md" "$HASH_CLAUDE" \
    "-f does not touch CLAUDE.md"

# ===========================================================================
# Test 9: runtime preflight — warns but never blocks
# ===========================================================================
start_test "Test 9: runtime preflight is warn-only"

# Case A: .python-version pinned to an impossible version → warning + exit 0
S9a=$(scratch_dir preflight-py)
make_project "$S9a" flat
echo "99.99.99" > "$S9a/.python-version"
LOG9a="$S9a/.setup.log"

run_setup "$S9a" "$LOG9a" -p "PreflightA" -t python
assert_equals "$?" "0" "impossible .python-version → setup still exits 0"
assert_matches "$LOG9a" ".python-version requires.*99\.99\.99" \
    "preflight warns about missing Python version"
assert_contains "$LOG9a" "uv python install 99.99.99" \
    "warning includes install guidance"
assert_contains "$LOG9a" "multi-project-isolation.md" \
    "warning points to the canonical doc"
assert_contains "$LOG9a" "Prerequisites OK" \
    "setup proceeds past preflight to Prerequisites OK"

# Case B: .nvmrc pinned to an impossible version → warning + exit 0
S9b=$(scratch_dir preflight-node)
make_project "$S9b" flat
echo "999" > "$S9b/.nvmrc"
LOG9b="$S9b/.setup.log"

run_setup "$S9b" "$LOG9b" -p "PreflightB" -t typescript
assert_equals "$?" "0" "impossible .nvmrc → setup still exits 0"
assert_matches "$LOG9b" ".nvmrc requires Node.*999" \
    "preflight warns about missing Node version"
assert_contains "$LOG9b" "fnm install 999" \
    "warning includes fnm install guidance"

# Case C: no version pins at all → preflight silent (no warnings emitted)
S9c=$(scratch_dir preflight-none)
make_project "$S9c" flat
LOG9c="$S9c/.setup.log"

run_setup "$S9c" "$LOG9c" -p "PreflightC" -t fullstack
assert_equals "$?" "0" "no pins → setup exits 0"
assert_not_contains "$LOG9c" ".python-version requires" \
    "no Python warning when no .python-version"
assert_not_contains "$LOG9c" ".nvmrc requires" \
    "no Node warning when no .nvmrc"
assert_not_contains "$LOG9c" "multi-project-isolation.md" \
    "no canonical-doc reference when no warnings fired"

# Case D: .python-version matching the system interpreter → green check, no warning
# Use the actual running python3 version so this is deterministic across CI machines.
S9d=$(scratch_dir preflight-match)
make_project "$S9d" flat
if command -v python3 >/dev/null 2>&1; then
    PY_CURRENT=$(python3 --version 2>&1 | awk '{print $2}')
    if [[ -n "$PY_CURRENT" ]]; then
        echo "$PY_CURRENT" > "$S9d/.python-version"
        LOG9d="$S9d/.setup.log"
        run_setup "$S9d" "$LOG9d" -p "PreflightD" -t python
        assert_equals "$?" "0" "matching .python-version → setup exits 0"
        assert_contains "$LOG9d" "Python $PY_CURRENT available" \
            "preflight reports Python version as available"
        assert_not_contains "$LOG9d" ".python-version requires" \
            "no warning when version is available"
    fi
else
    printf "  %s·%s skipped (python3 not installed): Case D\n" "$C_DIM" "$C_RESET"
fi

# Case E: .nvmrc with an EXACT version that can't possibly exist → warning
# Regression guard for Codex's P2 finding: an exact version pin like
# "20.11.0" must NOT be satisfied by ANY 20.x — check exact-match semantics.
# Use "20.99999.0" which is guaranteed absent from any reasonable system.
S9e=$(scratch_dir preflight-nvmrc-exact)
make_project "$S9e" flat
echo "20.99999.0" > "$S9e/.nvmrc"
LOG9e="$S9e/.setup.log"

run_setup "$S9e" "$LOG9e" -p "PreflightE" -t typescript
assert_equals "$?" "0" "exact .nvmrc mismatch → setup exits 0"
assert_matches "$LOG9e" ".nvmrc requires Node.*20\.99999\.0" \
    "preflight warns when exact .nvmrc version is missing (even if major matches system)"

# Case F: malformed package.json → preflight must NOT abort setup
# Regression guard for Codex's P2 finding about set -e + jq.
S9f=$(scratch_dir preflight-bad-json)
make_project "$S9f" flat
echo '{"name": "bad", this is not valid json' > "$S9f/package.json"
LOG9f="$S9f/.setup.log"

run_setup "$S9f" "$LOG9f" -p "PreflightF" -t typescript
assert_equals "$?" "0" "malformed package.json → setup STILL exits 0 (no set -e abort)"
assert_contains "$LOG9f" "Prerequisites OK" \
    "setup reached Prerequisites OK despite malformed package.json"

# ===========================================================================
# Report
# ===========================================================================
report "test-setup.sh"
