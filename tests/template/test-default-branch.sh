#!/usr/bin/env bash
# tests/template/test-default-branch.sh — fixture tests for hooks/lib/default-branch.{sh,ps1}.
#
# Verifies the strict contract:
#   - Branch name on stdout (only)
#   - Exit 0 on success, exit 1 on bail
#   - No stderr noise on any path
#
# Run from repo root:  bash tests/template/test-default-branch.sh

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=lib.sh
source "$REPO_ROOT/tests/template/lib.sh"

init_counters

LIB_SH="$REPO_ROOT/hooks/lib/default-branch.sh"
LIB_PS="$REPO_ROOT/hooks/lib/default-branch.ps1"

# ---------------------------------------------------------------------------
# Fixture helper: build a scratch git repo with the requested shape, run the
# helper, capture stdout + exit code + stderr length.
#
# scratch_branches: space-separated list, first one is checked-out
# scratch_remote:   "yes" to add origin remote, "no" to skip
# scratch_origin_head: branch name to set as origin/HEAD, or "" to skip
# scratch_detached: "yes" to detach HEAD after setup
# ---------------------------------------------------------------------------
build_fixture() {
    local scratch="$1" branches="$2" remote="$3" origin_head="$4" detached="$5"
    mkdir -p "$scratch"
    (
        cd "$scratch" || exit 1
        git init -q
        git config user.email t@t && git config user.name t
        local first=""
        for b in $branches; do
            if [[ -z "$first" ]]; then
                git checkout -q -b "$b"
                first="$b"
                git commit --allow-empty -q -m "init"
            else
                git branch -q "$b" "$first"
            fi
        done
        if [[ "$remote" == "yes" ]]; then
            local fake_remote="$scratch.remote.git"
            git init -q --bare "$fake_remote"
            git remote add origin "$fake_remote"
            git push -q origin "$first" 2>/dev/null || true
            if [[ -n "$origin_head" ]]; then
                git symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/$origin_head" 2>/dev/null
            fi
        fi
        if [[ "$detached" == "yes" ]]; then
            git checkout -q --detach
        fi
    )
}

run_helper_sh() {
    local scratch="$1"
    (cd "$scratch" && bash "$LIB_SH") > "$scratch/.out" 2> "$scratch/.err"
    echo "$?"
}

# ---------------------------------------------------------------------------
# Fixture 1: origin/HEAD set to main → returns "main", exit 0
# ---------------------------------------------------------------------------
start_test "origin/HEAD = main → returns main, exit 0"
S1=$(scratch_dir)
build_fixture "$S1" "main" "yes" "main" "no"
EXIT=$(run_helper_sh "$S1")
assert_equals "$EXIT" "0" "exit code 0"
assert_equals "$(cat "$S1/.out")" "main" "stdout = 'main'"
assert_equals "$(wc -c < "$S1/.err" | tr -d ' ')" "0" "stderr is empty"

# ---------------------------------------------------------------------------
# Fixture 2: origin/HEAD set to master → returns "master", exit 0
# ---------------------------------------------------------------------------
start_test "origin/HEAD = master → returns master, exit 0"
S2=$(scratch_dir)
build_fixture "$S2" "master" "yes" "master" "no"
EXIT=$(run_helper_sh "$S2")
assert_equals "$EXIT" "0" "exit code 0"
assert_equals "$(cat "$S2/.out")" "master" "stdout = 'master'"

# ---------------------------------------------------------------------------
# Fixture 3: origin/HEAD unset + main exists locally → returns "main", exit 0
# ---------------------------------------------------------------------------
start_test "origin/HEAD unset + main local → returns main"
S3=$(scratch_dir)
build_fixture "$S3" "main" "yes" "" "no"
EXIT=$(run_helper_sh "$S3")
assert_equals "$EXIT" "0" "exit code 0"
assert_equals "$(cat "$S3/.out")" "main" "stdout = 'main'"

# ---------------------------------------------------------------------------
# Fixture 4: origin/HEAD unset + only master exists → returns "master"
# ---------------------------------------------------------------------------
start_test "origin/HEAD unset + master local → returns master"
S4=$(scratch_dir)
build_fixture "$S4" "master" "yes" "" "no"
EXIT=$(run_helper_sh "$S4")
assert_equals "$EXIT" "0" "exit code 0"
assert_equals "$(cat "$S4/.out")" "master" "stdout = 'master'"

# ---------------------------------------------------------------------------
# Fixture 5: no remote at all + main exists → returns "main"
# ---------------------------------------------------------------------------
start_test "no remote + main local → returns main"
S5=$(scratch_dir)
build_fixture "$S5" "main" "no" "" "no"
EXIT=$(run_helper_sh "$S5")
assert_equals "$EXIT" "0" "exit code 0"
assert_equals "$(cat "$S5/.out")" "main" "stdout = 'main'"

# ---------------------------------------------------------------------------
# Fixture 6: no main, no master, no remote → exit 1, empty stdout
# ---------------------------------------------------------------------------
start_test "neither branch exists → exit 1, empty stdout"
S6=$(scratch_dir)
build_fixture "$S6" "develop" "no" "" "no"
EXIT=$(run_helper_sh "$S6")
assert_equals "$EXIT" "1" "exit code 1"
assert_equals "$(cat "$S6/.out")" "" "stdout empty on bail"
assert_equals "$(wc -c < "$S6/.err" | tr -d ' ')" "0" "stderr still empty on bail"

# ---------------------------------------------------------------------------
# Fixture 7: detached HEAD + main exists → returns main (HEAD ≠ default)
# ---------------------------------------------------------------------------
start_test "detached HEAD + main local → returns main"
S7=$(scratch_dir)
build_fixture "$S7" "main" "yes" "" "yes"
EXIT=$(run_helper_sh "$S7")
assert_equals "$EXIT" "0" "exit code 0"
assert_equals "$(cat "$S7/.out")" "main" "stdout = 'main'"

# ---------------------------------------------------------------------------
# Fixture 8: both main and master exist locally, origin/HEAD unset → returns "main"
# PRD US-003 edge case: Method 2 (local main check) fires before Method 3
# (local master check), so "main" wins when both branches are present.
# ---------------------------------------------------------------------------
start_test "origin/HEAD unset + both main and master local → returns main (Method 2 before Method 3)"
S8=$(scratch_dir)
build_fixture "$S8" "main master" "yes" "" "no"
EXIT=$(run_helper_sh "$S8")
assert_equals "$EXIT" "0" "exit code 0"
assert_equals "$(cat "$S8/.out")" "main" "stdout = 'main' (main preferred over master)"

# ---------------------------------------------------------------------------
# PowerShell parity (skipped if pwsh unavailable)
# ---------------------------------------------------------------------------
if command -v pwsh >/dev/null 2>&1; then
    start_test "pwsh: origin/HEAD = main → returns main"
    S8=$(scratch_dir)
    build_fixture "$S8" "main" "yes" "main" "no"
    OUT=$(cd "$S8" && pwsh -NoProfile -File "$LIB_PS" 2>/dev/null)
    EXIT=$?
    assert_equals "$EXIT" "0" "pwsh exit code 0"
    assert_equals "$OUT" "main" "pwsh stdout = 'main'"

    start_test "pwsh: neither branch exists → exit 1"
    S9=$(scratch_dir)
    build_fixture "$S9" "develop" "no" "" "no"
    OUT=$(cd "$S9" && pwsh -NoProfile -File "$LIB_PS" 2>/dev/null)
    EXIT=$?
    assert_equals "$EXIT" "1" "pwsh exit code 1"
    assert_equals "$OUT" "" "pwsh stdout empty on bail"
fi

report "test-default-branch.sh"
