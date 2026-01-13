#!/bin/bash
# .claude/hooks/check-state-updated.sh
# This hook runs when Claude is about to stop responding.
# It checks if there are uncommitted changes and reminds Claude to update state.
#
# Requirements: jq, git
# Install jq: brew install jq (macOS) or apt install jq (Linux)

set -e
INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
[ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0

# Uncommitted changes
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

# Files modified (uncommitted)
CONTINUITY_MODIFIED=$(git status --porcelain CONTINUITY.md 2>/dev/null | wc -l | tr -d ' ')
CHANGELOG_MODIFIED=$(git status --porcelain docs/CHANGELOG.md 2>/dev/null | wc -l | tr -d ' ')

# Total files changed on branch (committed + uncommitted) vs main
BRANCH_BASE=$(git merge-base main HEAD 2>/dev/null || echo "HEAD~10")
BRANCH_CHANGED=$(git diff --name-only "$BRANCH_BASE" HEAD 2>/dev/null | wc -l | tr -d ' ')
UNCOMMITTED_FILES=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
TOTAL_CHANGED=$((BRANCH_CHANGED + UNCOMMITTED_FILES))

# Check if CHANGELOG was updated anywhere on branch
CHANGELOG_IN_BRANCH=$(git diff --name-only "$BRANCH_BASE" HEAD 2>/dev/null | grep -c "CHANGELOG.md" || echo "0")

ISSUES=""

# Block: uncommitted changes but CONTINUITY.md not updated
if [ "$UNCOMMITTED" -gt 0 ] && [ "$CONTINUITY_MODIFIED" -eq 0 ]; then
    ISSUES="Update CONTINUITY.md Done/Now/Next sections."
fi

# Block: 3+ files changed on branch but CHANGELOG.md never updated
if [ "$TOTAL_CHANGED" -gt 3 ] && [ "$CHANGELOG_IN_BRANCH" -eq 0 ] && [ "$CHANGELOG_MODIFIED" -eq 0 ]; then
    ISSUES="${ISSUES:+$ISSUES }Update docs/CHANGELOG.md ($TOTAL_CHANGED files changed this session)."
fi

[ -n "$ISSUES" ] && echo "{\"decision\": \"block\", \"reason\": \"$ISSUES\"}" && exit 0
# All good, allow stop
exit 0
