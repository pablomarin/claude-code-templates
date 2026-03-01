#!/bin/bash
# SessionStart hook: silently inject git branch into Claude's context
# Uses hookSpecificOutput.additionalContext for clean, non-visible injection

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Current branch: %s"}}\n' "$BRANCH"
exit 0
