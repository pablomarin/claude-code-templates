#!/bin/bash
# .claude/hooks/check-state-updated.sh
# This hook runs when Claude is about to stop responding.
# It checks if there are uncommitted changes and reminds Claude to update state.
#
# Uses exit code 2 + stderr to block (avoids JSON stdout parsing issues
# caused by shell profile echo statements polluting stdout).
#
# Requirements: git
# Optional: jq (recommended for robust JSON parsing, falls back to grep)

set -e
INPUT=$(cat)

# Parse stop_hook_active (jq preferred, grep fallback)
if command -v jq &> /dev/null; then
    STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
else
    STOP_HOOK_ACTIVE=$(echo "$INPUT" | grep -o '"stop_hook_active"[[:space:]]*:[[:space:]]*true' | head -1)
    [ -n "$STOP_HOOK_ACTIVE" ] && STOP_HOOK_ACTIVE="true" || STOP_HOOK_ACTIVE="false"
fi
[ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0

# All git commands run in current directory (Claude cd's into worktrees)
# Only count tracked modifications (staged + unstaged), NOT untracked files (??)
UNCOMMITTED=$(git status --porcelain 2>/dev/null | grep -v '^??' | wc -l | tr -d ' ')

# Files modified (uncommitted)
CONTINUITY_MODIFIED=$(git status --porcelain CONTINUITY.md 2>/dev/null | wc -l | tr -d ' ')
CHANGELOG_MODIFIED=$(git status --porcelain docs/CHANGELOG.md 2>/dev/null | wc -l | tr -d ' ')

# Total files changed on branch (committed + uncommitted) vs main
BRANCH_BASE=$(git merge-base main HEAD 2>/dev/null || echo "HEAD~10")
BRANCH_CHANGED=$(git diff --name-only "$BRANCH_BASE" HEAD 2>/dev/null | wc -l | tr -d ' ')
UNCOMMITTED_FILES=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
TOTAL_CHANGED=$((BRANCH_CHANGED + UNCOMMITTED_FILES))

# Check if CHANGELOG was updated anywhere on branch
CHANGELOG_IN_BRANCH=$(git diff --name-only "$BRANCH_BASE" HEAD 2>/dev/null | grep -c "CHANGELOG.md" || true)

# --- Workflow state tracking ---
# If CONTINUITY.md has an active workflow, extract phase/next-step for advisory reminder
WORKFLOW_REMINDER=""
if [ -f "CONTINUITY.md" ]; then
    WORKFLOW_CMD=$(grep -E '\|\s*Command\s*\|' CONTINUITY.md 2>/dev/null | awk -F'|' '{print $3}' | xargs)
    if [ -n "$WORKFLOW_CMD" ] && [ "$WORKFLOW_CMD" != "none" ] && [ "$WORKFLOW_CMD" != "—" ] && [ "$WORKFLOW_CMD" != "-" ]; then
        WORKFLOW_PHASE=$(grep -E '\|\s*Phase\s*\|' CONTINUITY.md 2>/dev/null | awk -F'|' '{print $3}' | xargs)
        WORKFLOW_NEXT=$(grep -E '\|\s*Next step\s*\|' CONTINUITY.md 2>/dev/null | awk -F'|' '{print $3}' | xargs)
        WORKFLOW_REMINDER="WORKFLOW: $WORKFLOW_CMD | Phase: $WORKFLOW_PHASE | Next: $WORKFLOW_NEXT"
    fi
fi

ISSUES=""

# Block: uncommitted changes but CONTINUITY.md not updated
if [ "$UNCOMMITTED" -gt 0 ] && [ "$CONTINUITY_MODIFIED" -eq 0 ]; then
    ISSUES="Update CONTINUITY.md Done/Now/Next sections."
fi

# Block: 3+ files changed on branch but CHANGELOG.md never updated
if [ "$TOTAL_CHANGED" -gt 3 ] && [ "$CHANGELOG_IN_BRANCH" -eq 0 ] && [ "$CHANGELOG_MODIFIED" -eq 0 ]; then
    ISSUES="${ISSUES:+$ISSUES }Update docs/CHANGELOG.md ($TOTAL_CHANGED files changed this session)."
fi

# Block using exit code 2 + stderr (robust — immune to shell profile stdout pollution)
if [ -n "$ISSUES" ]; then
    # Prepend workflow reminder if active (so model always sees current phase)
    [ -n "$WORKFLOW_REMINDER" ] && ISSUES="[$WORKFLOW_REMINDER] $ISSUES"
    echo "$ISSUES" >&2
    exit 2
fi

# Advisory: remind about active workflow even when no issues (non-blocking)
if [ -n "$WORKFLOW_REMINDER" ]; then
    echo "$WORKFLOW_REMINDER" >&2
fi

# All good, allow stop
exit 0
