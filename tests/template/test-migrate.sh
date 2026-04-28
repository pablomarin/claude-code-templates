#!/bin/bash
# tests/template/test-migrate.sh — fixtures for scripts/migrate-continuity.sh
# Invoked via: bash tests/template/test-migrate.sh
# CI must have a PowerShell runtime for the cross-platform parity portion of
# test-contracts.sh — this file itself is bash-only (tests bash migration).

set -u  # unset-var detection; do NOT set -e (lib.sh handles failures via counters)

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=lib.sh
source "$REPO_ROOT/tests/template/lib.sh"

init_counters

# ---------------------------------------------------------------------------
# Inline fixture helpers (mirror test-fixtures.sh; kept inline to avoid
# sourcing test-fixtures.sh which would re-run its own test cases here).
# ---------------------------------------------------------------------------
make_legacy_continuity_for_migration() {
    local scratch="$1"
    cat > "$scratch/CONTINUITY.md" <<'EOF'
# CONTINUITY

## Goal

Build a thing that does the thing.

## Architecture Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Database | PostgreSQL | ACID; pgvector |
| Auth     | OAuth2 + JWT | Industry standard |

## State

### Done (recent 2-3 only)

- 2026-04-01: shipped feature X
- 2026-04-02: shipped feature Y
- 2026-04-03: shipped feature Z (older entry — should be trimmed by --migrate)
- 2026-04-04: ancient entry (also trimmed)

### Now

Working on the migration assistant.

### Next

- ship PR #2
- write CHANGELOG entry

EOF
    # Also drop a CLAUDE.md with the dangling @-import.
    cat > "$scratch/CLAUDE.md" <<'EOF'
@CONTINUITY.md

# CLAUDE.md - Test Project

## Project Overview

A test project.
EOF
}

# Helper: assert that string $1 contains literal substring $2.
# (lib.sh's assert_contains takes a file path; we use string semantics here.)
assert_str_contains() {
    local haystack="$1" needle="$2" msg="${3:-string contains '$2'}"
    if echo "$haystack" | grep -qF -- "$needle"; then
        pass "$msg"
    else
        fail "$msg (not found in output)"
    fi
}

run_migrate() {
    local scratch="$1"
    # Pre-install state.template.md so the helper has somewhere to write Now/Next.
    mkdir -p "$scratch/.claude/local"
    [ ! -f "$scratch/.claude/local/state.md" ] && cp "$REPO_ROOT/state.template.md" "$scratch/.claude/local/state.md"
    ( cd "$scratch" && bash "$REPO_ROOT/scripts/migrate-continuity.sh" 2>&1 )
}

start_test "test_migrate_extracts_goal"
scratch=$(mktemp -d)
make_legacy_continuity_for_migration "$scratch"
out=$(run_migrate "$scratch")
assert_str_contains "$out" "Goal" "summary mentions Goal migration"
if grep -qF "Build a thing that does the thing." "$scratch/CLAUDE.md"; then
    pass "goal text appended to CLAUDE.md"
else
    fail "goal text not appended to CLAUDE.md"
fi
rm -rf "$scratch"

start_test "test_migrate_creates_adrs_from_decisions_table"
scratch=$(mktemp -d)
make_legacy_continuity_for_migration "$scratch"
run_migrate "$scratch" >/dev/null
if compgen -G "$scratch/docs/adr/*-database.md" >/dev/null; then pass "Database ADR created"; else fail "Database ADR missing"; fi
if compgen -G "$scratch/docs/adr/*-auth.md" >/dev/null; then pass "Auth ADR created"; else fail "Auth ADR missing"; fi
rm -rf "$scratch"

start_test "test_migrate_trims_done_to_last_3"
scratch=$(mktemp -d)
make_legacy_continuity_for_migration "$scratch"
run_migrate "$scratch" >/dev/null
# Extract ONLY the ### Done block from state.md, then count bullets — not all bullets in the file.
done_count=$(awk '/^### Done/{f=1;next} f && /^### /{f=0} f && /^- /{n++} END{print n+0}' "$scratch/.claude/local/state.md")
if [ "$done_count" -le 3 ]; then pass "Done block has $done_count entries (≤ 3)"; else fail "Done has $done_count entries, expected ≤ 3"; fi
# Verify it kept the LAST entries, not the first (Codex P1: tail vs head).
if grep -qF "2026-04-04: ancient entry" "$scratch/.claude/local/state.md"; then
    fail "Done kept the OLDEST entry — should have used tail, not head"
else
    pass "Done dropped the oldest entry (correct tail behavior)"
fi
rm -rf "$scratch"

start_test "test_migrate_byte_preserves_original"
scratch=$(mktemp -d)
make_legacy_continuity_for_migration "$scratch"
before=$(hash_file "$scratch/CONTINUITY.md")
run_migrate "$scratch" >/dev/null
after=$(hash_file "$scratch/CONTINUITY.md")
assert_equals "$before" "$after" "CONTINUITY.md byte-preserved through --migrate"
rm -rf "$scratch"

start_test "test_migrate_idempotent_state_md"
scratch=$(mktemp -d)
make_legacy_continuity_for_migration "$scratch"
run_migrate "$scratch" >/dev/null
before_state=$(hash_file "$scratch/.claude/local/state.md")
run_migrate "$scratch" >/dev/null  # second run — should detect sentinel and no-op
after_state=$(hash_file "$scratch/.claude/local/state.md")
assert_equals "$before_state" "$after_state" "state.md unchanged on second run (sentinel detected)"
rm -rf "$scratch"

start_test "test_migrate_idempotent_claude_md"
scratch=$(mktemp -d)
make_legacy_continuity_for_migration "$scratch"
run_migrate "$scratch" >/dev/null
before_claude=$(hash_file "$scratch/CLAUDE.md")
run_migrate "$scratch" >/dev/null
after_claude=$(hash_file "$scratch/CLAUDE.md")
assert_equals "$before_claude" "$after_claude" "CLAUDE.md unchanged on second run (sentinel detected)"
rm -rf "$scratch"

start_test "test_migrate_idempotent_no_duplicate_adrs"
scratch=$(mktemp -d)
make_legacy_continuity_for_migration "$scratch"
run_migrate "$scratch" >/dev/null
before_count=$(compgen -G "$scratch/docs/adr/*.md" 2>/dev/null | wc -l | tr -d ' ')
run_migrate "$scratch" >/dev/null
after_count=$(compgen -G "$scratch/docs/adr/*.md" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "$before_count" "$after_count" "ADR file count unchanged on second run"
rm -rf "$scratch"

start_test "test_migrate_flags_dangling_at_import"
scratch=$(mktemp -d)
make_legacy_continuity_for_migration "$scratch"  # creates CLAUDE.md with @CONTINUITY.md
out=$(run_migrate "$scratch")
assert_str_contains "$out" "@CONTINUITY.md" "summary flags dangling @-import"
assert_str_contains "$out" "dangling" "summary uses 'dangling' phrasing"
rm -rf "$scratch"

start_test "test_migrate_no_continuity_present"
scratch=$(mktemp -d)
out=$(run_migrate "$scratch")
assert_str_contains "$out" "No CONTINUITY.md" "graceful no-op when no legacy file"
rm -rf "$scratch"

report "test-migrate.sh"
