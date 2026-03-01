#!/bin/bash
# .claude/hooks/check-config-change.sh
# ConfigChange hook: logs config file modifications mid-session.
# Optionally blocks removal of deny rules from settings.json (strict mode).
#
# Input (JSON via stdin): {session_id, cwd, hook_event_name, source, file_path}
# Block: exit 2 + message on stderr (same pattern as other hooks).
#
# Requirements: jq (recommended), grep (fallback)

set -e
INPUT=$(cat)

# Parse the changed file path
if command -v jq &> /dev/null; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // ""')
    SOURCE=$(echo "$INPUT" | jq -r '.source // ""')
else
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\(.*\)"/\1/')
    SOURCE=$(echo "$INPUT" | grep -o '"source"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\(.*\)"/\1/')
fi

FILENAME=$(basename "$FILE_PATH" 2>/dev/null || echo "unknown")

# Always log config changes for visibility
echo "Config changed: $FILENAME (source: $SOURCE, path: $FILE_PATH)" >&2

## --- STRICT MODE (uncomment to block deny-rule removals) ---
## Checks if settings.json lost any deny rules compared to git HEAD.
## Uses exit-code-2 blocking pattern.
#
# if [[ "$FILENAME" == "settings.json" ]] && command -v git &> /dev/null; then
#     DENY_BEFORE=$(git show HEAD:"$FILE_PATH" 2>/dev/null | grep -c '"deny"' || echo "0")
#     DENY_AFTER=$(grep -c '"deny"' "$FILE_PATH" 2>/dev/null || echo "0")
#     if [ "$DENY_AFTER" -lt "$DENY_BEFORE" ]; then
#         echo "BLOCKED: deny rules were removed from $FILENAME. This may indicate permission escalation." >&2
#         exit 2
#     fi
# fi

exit 0
