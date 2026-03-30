#!/bin/bash
# .claude/hooks/check-workflow-gates.sh
# PreToolUse hook for Bash: blocks commit/push/PR if quality gates aren't complete.
#
# Fires BEFORE Bash commands. Only activates when:
# 1. An active workflow exists in CONTINUITY.md (Command != none)
# 2. The command is git commit, git push, or gh pr create
# 3. Always-required quality gate checklist items aren't checked off
#
# Only gates on ALWAYS-REQUIRED items (review, simplify, verify).
# Conditional items like "E2E use cases tested (if user-facing)" are NOT gated —
# the model decides if they apply.
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

# Only gate on the 3 pre-ship quality gates:
#   "Code review loop" — code review must pass before shipping
#   "Simplified" — code simplification must run before shipping
#   "Verified" — tests/lint/types must pass before shipping
# Explicitly exclude non-gate items that contain similar words:
#   "PR reviews addressed" — happens AFTER PR, not a pre-ship gate
#   "Plugins verified" — pre-flight check, not a quality gate
#   "Plan review loop" — design phase discipline, not a pre-ship gate
UNCHECKED=$(echo "$CHECKLIST" | grep '\- \[ \]' | grep -iE '(Code review loop|Simplified|Verified \(tests)' || true)

if [ -n "$UNCHECKED" ]; then
    UNCHECKED_COUNT=$(echo "$UNCHECKED" | wc -l | tr -d ' ')
    MISSING=$(echo "$UNCHECKED" | sed 's/- \[ \] /  - /')
    echo "WORKFLOW GATE: $UNCHECKED_COUNT required quality gate(s) incomplete." >&2
    echo "Complete these before shipping:" >&2
    echo "$MISSING" >&2
    exit 2
fi

exit 0
