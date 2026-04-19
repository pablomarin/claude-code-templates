#!/bin/bash
# .claude/hooks/check-workflow-gates.sh
# PreToolUse hook for Bash: blocks commit/push/PR if quality gates aren't complete.
#
# Fires BEFORE Bash commands. Only activates when:
# 1. An active workflow exists in CONTINUITY.md (Command != none)
# 2. The command is git commit, git push, or gh pr create
# 3. Always-required quality gate checklist items aren't checked off
#
# Gated markers (canonical vocabulary — see rules/testing.md "Canonical E2E gate vocabulary"):
#   "Code review loop"  — code review must pass
#   "Simplified"        — code simplification must run
#   "Verified (tests"   — unit tests + lint + types + migrations must pass
#   "E2E verified"      — Phase 5.4 E2E must pass OR be explicitly N/A with reason
#
# Non-gated (conditional) items like "E2E use cases designed" and "E2E regression
# passed" stay advisory — the model decides if they apply. The E2E verified gate
# has an explicit N/A escape: `- [x] E2E verified — N/A: <reason>`.
#
# Input (JSON via stdin): {session_id, cwd, tool_name, tool_input: {command}}
# Block: exit 2 + message on stderr
# Allow: exit 0
#
# Requirements: jq (recommended, grep fallback)

INPUT=$(cat)

# --- Parse command ---
if command -v jq &> /dev/null; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
else
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//')
fi

[ -z "$COMMAND" ] && exit 0

# --- Only gate ship actions ---
IS_SHIP=false
echo "$COMMAND" | grep -qE '^\s*git\s+commit\b' && IS_SHIP=true
echo "$COMMAND" | grep -qE '^\s*git\s+push\b' && IS_SHIP=true
echo "$COMMAND" | grep -qE '^\s*gh\s+pr\s+create\b' && IS_SHIP=true

# Not a ship action — allow immediately
$IS_SHIP || exit 0

# --- Check for active workflow ---
[ ! -f "CONTINUITY.md" ] && exit 0

# Use flexible whitespace matching — formatters may pad table cells
WORKFLOW_CMD=$(grep -iE '\|\s*Command\s*\|' CONTINUITY.md 2>/dev/null | head -1 | awk -F'|' '{print $3}' | xargs)
# No active workflow — allow
[ -z "$WORKFLOW_CMD" ] && exit 0
[ "$WORKFLOW_CMD" = "none" ] && exit 0
[ "$WORKFLOW_CMD" = "—" ] && exit 0
[ "$WORKFLOW_CMD" = "-" ] && exit 0

# --- Active workflow: check always-required quality gates ---
# Extract the Checklist section (between ### Checklist and next ## heading)
CHECKLIST=$(sed -n '/^### Checklist/,/^## /p' CONTINUITY.md 2>/dev/null)

# Only gate on the 4 pre-ship quality gates:
#   "Code review loop" — code review must pass before shipping
#   "Simplified" — code simplification must run before shipping
#   "Verified (tests" — tests/lint/types must pass before shipping
#   "E2E verified" — Phase 5.4 must pass OR be checked [x] with an N/A reason
# Explicitly exclude non-gate items that contain similar words:
#   "PR reviews addressed" — happens AFTER PR, not a pre-ship gate
#   "Plugins verified" — pre-flight check, not a quality gate
#   "Plan review loop" — design phase discipline, not a pre-ship gate
#   "E2E use cases designed" — Phase 3.2b, conditional on user-facing change
#   "E2E regression passed" — Phase 5.4b, conditional on accumulated UCs
#   "E2E use cases graduated" / "E2E specs graduated" — post-PASS housekeeping
UNCHECKED=$(echo "$CHECKLIST" | grep '\- \[ \]' | grep -iE '(Code review loop|Simplified|Verified \(tests|E2E verified)' || true)

if [ -n "$UNCHECKED" ]; then
    UNCHECKED_COUNT=$(echo "$UNCHECKED" | wc -l | tr -d ' ')
    MISSING=$(echo "$UNCHECKED" | sed 's/- \[ \] /  - /')
    echo "WORKFLOW GATE: $UNCHECKED_COUNT required quality gate(s) incomplete." >&2
    echo "Complete these before shipping:" >&2
    echo "$MISSING" >&2
    echo "" >&2
    echo "How to clear each gate:" >&2
    echo "  - Code review loop:  run /codex review + /pr-review-toolkit:review-pr, fix findings" >&2
    echo "  - Simplified:        run /simplify" >&2
    echo "  - Verified (tests):  run the verify-app agent" >&2
    echo "  - E2E verified:      run the verify-e2e agent AND persist its report, OR mark N/A:" >&2
    echo '                         - [x] E2E verified — N/A: <specific reason>' >&2
    echo "  See .claude/rules/testing.md for the canonical gate vocabulary." >&2
    exit 2
fi

exit 0
