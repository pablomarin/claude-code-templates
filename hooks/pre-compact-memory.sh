#!/bin/bash
# .claude/hooks/pre-compact-memory.sh (also used globally at ~/.claude/hooks/)
# This hook runs BEFORE context compaction.
# It outputs a reminder for Claude to save learnings to auto memory.
#
# The prompt-based PreCompact hook in settings.json handles the actual
# memory save instruction. This script provides additional context about
# the current session state.

set -e
INPUT=$(cat)

# Check for jq - if not available, output basic info and exit gracefully
if ! command -v jq &> /dev/null; then
    echo "Pre-compact memory check: jq not installed, skipping detailed context"
    exit 0
fi

TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# Determine the auto memory directory for this project
# Claude Code derives this from the git repo root
GIT_ROOT=$(cd "$CWD" && git rev-parse --show-toplevel 2>/dev/null || echo "$CWD")
PROJECT_KEY=$(echo "$GIT_ROOT" | sed 's|/|-|g')
MEMORY_DIR="$HOME/.claude/projects/$PROJECT_KEY/memory"

# Check if MEMORY.md exists and get its size
MEMORY_EXISTS="false"
MEMORY_LINES=0
if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
    MEMORY_EXISTS="true"
    MEMORY_LINES=$(wc -l < "$MEMORY_DIR/MEMORY.md" | tr -d ' ')
fi

# Count topic files
TOPIC_FILES=0
if [ -d "$MEMORY_DIR" ]; then
    TOPIC_FILES=$(find "$MEMORY_DIR" -name "*.md" ! -name "MEMORY.md" 2>/dev/null | wc -l | tr -d ' ')
fi

# Output context as additional information (shown in verbose mode)
echo "Pre-compact memory check: trigger=$TRIGGER, memory_exists=$MEMORY_EXISTS, memory_lines=$MEMORY_LINES, topic_files=$TOPIC_FILES"
exit 0
