#!/bin/bash
# SessionStart hook: silently inject git branch into Claude's context
# Uses hookSpecificOutput.additionalContext for clean, non-visible injection

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# JSON-escape the branch name (handle quotes, backslashes)
if command -v jq &> /dev/null; then
    jq -n --arg branch "$BRANCH" \
      '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":("Current branch: " + $branch)}}'
else
    # Fallback: escape JSON-special characters
    SAFE_BRANCH=$(printf '%s' "$BRANCH" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Current branch: %s"}}\n' "$SAFE_BRANCH"
fi
exit 0
