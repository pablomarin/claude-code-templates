#!/bin/bash
# .claude/hooks/post-tool-format.sh
# This hook runs after Edit or Write tool is used.
# It automatically formats the modified file based on its type.
#
# Optional: jq (recommended for robust JSON parsing, falls back to grep)
# Optional: ruff (for Python), prettier (for JS/TS/JSON/MD)
#
# Security: Follows Anthropic best practices
# - Validates and sanitizes inputs
# - Blocks path traversal attacks
# - Skips sensitive files
# - Uses quoted variables

set -e

# Read and parse input
INPUT=$(cat)

# Parse file_path (jq preferred, grep fallback)
if command -v jq &> /dev/null; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Exit if no file path
[ -z "$FILE_PATH" ] && exit 0

# Security: Block path traversal
if echo "$FILE_PATH" | grep -q '\.\.'; then
    echo "Security: Path traversal blocked" >&2
    exit 0
fi

# Security: Skip sensitive files
BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
    .env*|*.key|*.pem|*.secret|*credential*|*password*|*.p12|*.pfx)
        exit 0
        ;;
esac

# Skip files in sensitive directories
case "$FILE_PATH" in
    *.git/*|*node_modules/*|*.ssh/*|*secrets/*)
        exit 0
        ;;
esac

# Get file extension
EXTENSION="${FILE_PATH##*.}"

# Format based on file type
case "$EXTENSION" in
    py)
        # Python files - format with ruff
        if [ -d "$CLAUDE_PROJECT_DIR/src" ]; then
            cd "$CLAUDE_PROJECT_DIR/src" 2>/dev/null && uv run ruff format "$FILE_PATH" 2>/dev/null || true
        else
            uv run ruff format "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    ts|tsx|js|jsx)
        # TypeScript/JavaScript files - format with prettier
        npx prettier --write "$FILE_PATH" 2>/dev/null || true
        ;;
    json)
        # JSON files - format with prettier (skip package-lock.json)
        [ "$BASENAME" = "package-lock.json" ] && exit 0
        npx prettier --write "$FILE_PATH" 2>/dev/null || true
        ;;
    md)
        # Markdown files - format with prettier
        npx prettier --write "$FILE_PATH" 2>/dev/null || true
        ;;
esac

exit 0
