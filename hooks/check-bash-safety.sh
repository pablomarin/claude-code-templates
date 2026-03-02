#!/bin/bash
# .claude/hooks/check-bash-safety.sh
# PreToolUse hook for Bash: audit logging + dangerous pattern blocking.
#
# Fires BEFORE every Bash command. Logs all commands to ~/.claude/audit.log.
# Blocks commands matching high-risk patterns (exit 2 + stderr).
#
# Input (JSON via stdin): {session_id, cwd, tool_name, tool_input: {command}}
# Block: exit 2 + message on stderr
# Allow: exit 0
#
# Requirements: jq (recommended for robust parsing, grep fallback)

INPUT=$(cat)

# --- Parse input ---
if command -v jq &> /dev/null; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
    CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
else
    # grep fallback: extract command value (handles simple cases)
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//')
    SESSION_ID="unknown"
    CWD="unknown"
fi

# Skip empty commands
[ -z "$COMMAND" ] && exit 0

# --- Audit log (always, before any blocking) ---
AUDIT_LOG="${HOME}/.claude/audit.log"
mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
# Redact potential secrets from logged commands (API keys, tokens, passwords)
SAFE_COMMAND=$(printf '%s' "$COMMAND" | sed -E \
  's/(export\s+\w*(KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL)\w*=)[^ ]*/\1[REDACTED]/gi; s/(sk-|ghp_|gho_|github_pat_|xoxb-|xoxp-)[A-Za-z0-9_-]+/\1[REDACTED]/g')
printf '[%s] session=%s cwd=%s cmd=%s\n' "$TIMESTAMP" "$SESSION_ID" "$CWD" "$SAFE_COMMAND" >> "$AUDIT_LOG" 2>/dev/null

# --- High-risk pattern detection ---
# Each check is a separate function for clarity and testability.
# Only flag patterns that are clearly dangerous — minimize false positives.

REASON=""

# 1. Piping remote content to shell (curl/wget ... | sh/bash/zsh)
if echo "$COMMAND" | grep -qE 'curl\s.*\|\s*(sh|bash|zsh)' 2>/dev/null; then
    REASON="Piping remote script to shell (curl | sh)"
elif echo "$COMMAND" | grep -qE 'wget\s.*\|\s*(sh|bash|zsh)' 2>/dev/null; then
    REASON="Piping remote script to shell (wget | sh)"

# 2. Base64 decode piped to shell
elif echo "$COMMAND" | grep -qE 'base64\s.*-d.*\|\s*(sh|bash|zsh|eval)' 2>/dev/null; then
    REASON="Base64-decoded content piped to shell"

# 3. Reverse shell patterns
elif echo "$COMMAND" | grep -qE '/dev/tcp/' 2>/dev/null; then
    REASON="Potential reverse shell (/dev/tcp)"
elif echo "$COMMAND" | grep -qE 'bash\s+-i\s+>&' 2>/dev/null; then
    REASON="Potential reverse shell (bash -i)"
elif echo "$COMMAND" | grep -qE 'nc\s.*-e\s*(sh|bash|/bin)' 2>/dev/null; then
    REASON="Potential reverse shell (netcat)"

# 4. Exfiltration of credentials via network
elif echo "$COMMAND" | grep -qE 'cat.*(id_rsa|id_ed25519|\.ssh/|\.gnupg/|\.aws/credentials|\.env).*\|\s*curl' 2>/dev/null; then
    REASON="Exfiltrating credential files via network"
elif echo "$COMMAND" | grep -qE 'curl.*-d\s*@.*(id_rsa|id_ed25519|\.ssh/|\.env|\.aws/)' 2>/dev/null; then
    REASON="Uploading credential files via curl"

# 5. Mass deletion outside project (already in deny list, but catch variants)
elif echo "$COMMAND" | grep -qE 'rm\s+-[rf]*\s+/' 2>/dev/null && ! echo "$COMMAND" | grep -qE 'rm\s+-[rf]*\s+\./|rm\s+-[rf]*\s+[^/]' 2>/dev/null; then
    REASON="Recursive deletion targeting root filesystem"

# 6. Modifying Claude Code's own config via Bash (defense in depth with ConfigChange hook)
elif echo "$COMMAND" | grep -qE '(sed|awk|echo|tee|printf).*\.claude/(settings|config)' 2>/dev/null; then
    REASON="Attempting to modify Claude Code configuration via Bash"
fi

# --- Block or allow ---
if [ -n "$REASON" ]; then
    printf 'BLOCKED: %s\nCommand: %s\n' "$REASON" "$SAFE_COMMAND" >> "$AUDIT_LOG" 2>/dev/null
    echo "BLOCKED by safety hook: $REASON" >&2
    exit 2
fi

exit 0
