#!/bin/bash
# .claude/hooks/check-state-updated.sh
# This hook runs when Claude is about to stop responding.
# It checks if there are uncommitted changes and reminds Claude to update state.
#
# Requirements: jq, git
# Install jq: brew install jq (macOS) or apt install jq (Linux)

set -e

# Read the hook input from stdin
INPUT=$(cat)

# Check if stop_hook_active to prevent infinite loops
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    # Already in a stop hook loop, don't block again
    exit 0
fi

# Check for uncommitted changes (trim whitespace)
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

# Check if CONTINUITY.md was modified in this session (trim whitespace)
CONTINUITY_MODIFIED=$(git status --porcelain CONTINUITY.md 2>/dev/null | wc -l | tr -d ' ')

# Build response
ISSUES=""

if [ "$UNCOMMITTED" -gt 0 ] && [ "$CONTINUITY_MODIFIED" -eq 0 ]; then
    ISSUES="You have uncommitted changes but CONTINUITY.md hasn't been updated. Please update the Done/Now/Next sections to reflect the current state before finishing."
fi

# Check if CHANGELOG should be updated (if there are significant changes)
CHANGELOG_MODIFIED=$(git status --porcelain docs/CHANGELOG.md 2>/dev/null | wc -l | tr -d ' ')

# Count changed files (more robust parsing)
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')

if [ "$CHANGED_FILES" -gt 3 ] && [ "$CHANGELOG_MODIFIED" -eq 0 ]; then
    if [ -n "$ISSUES" ]; then
        ISSUES="$ISSUES Also, consider updating docs/CHANGELOG.md for the significant changes made ($CHANGED_FILES files changed)."
    else
        ISSUES="Consider updating docs/CHANGELOG.md for the significant changes made ($CHANGED_FILES files changed)."
    fi
fi

# If there are issues, block and ask Claude to continue
if [ -n "$ISSUES" ]; then
    # Output JSON that tells Claude to continue working
    echo "{\"decision\": \"block\", \"reason\": \"$ISSUES\"}"
    exit 0
fi

# All good, allow stop
exit 0
