# .claude/hooks/check-bash-safety.ps1
# PreToolUse hook for Bash: audit logging + dangerous pattern blocking.
#
# Fires BEFORE every Bash command. Logs all commands to ~/.claude/audit.log.
# Blocks commands matching high-risk patterns (exit 2 + stderr).
#
# Input (JSON via stdin): {session_id, cwd, tool_name, tool_input: {command}}
# Block: exit 2 + message on stderr
# Allow: exit 0

$ErrorActionPreference = "SilentlyContinue"

$RawInput = $input | Out-String
$Data = $RawInput | ConvertFrom-Json -ErrorAction SilentlyContinue

$Command = if ($Data.tool_input.command) { $Data.tool_input.command } else { "" }
$SessionId = if ($Data.session_id) { $Data.session_id } else { "unknown" }
$Cwd = if ($Data.cwd) { $Data.cwd } else { "unknown" }

# Skip empty commands
if (-not $Command) { exit 0 }

# --- Audit log ---
$AuditLog = Join-Path $env:USERPROFILE ".claude" "audit.log"
$AuditDir = Split-Path $AuditLog -Parent
if (-not (Test-Path $AuditDir)) { New-Item -ItemType Directory -Path $AuditDir -Force | Out-Null }
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
# Redact potential secrets from logged commands
$SafeCommand = $Command -replace '(export\s+\w*(KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL)\w*=)[^ ]*', '$1[REDACTED]'
$SafeCommand = $SafeCommand -replace '(sk-|ghp_|gho_|github_pat_|xoxb-|xoxp-)[A-Za-z0-9_-]+', '$1[REDACTED]'
$LogEntry = "[$Timestamp] session=$SessionId cwd=$Cwd cmd=$SafeCommand"
Add-Content -Path $AuditLog -Value $LogEntry -ErrorAction SilentlyContinue

# --- High-risk pattern detection ---
$Reason = ""

# 1. Piping remote content to shell
if ($Command -match 'curl\s.*\|\s*(sh|bash|zsh|cmd|powershell)') {
    $Reason = "Piping remote script to shell (curl | sh)"
}
elseif ($Command -match 'wget\s.*\|\s*(sh|bash|zsh|cmd|powershell)') {
    $Reason = "Piping remote script to shell (wget | sh)"
}
# Also catch PowerShell-specific download-and-execute
elseif ($Command -match 'Invoke-Expression.*Invoke-WebRequest|iex.*iwr|IEX.*\(New-Object') {
    $Reason = "Download and execute pattern (Invoke-Expression)"
}
# 2. Base64 decode piped to shell
elseif ($Command -match 'base64.*-d.*\|\s*(sh|bash|zsh|eval)') {
    $Reason = "Base64-decoded content piped to shell"
}
elseif ($Command -match '\[Convert\]::FromBase64.*Invoke-Expression') {
    $Reason = "Base64-decoded content executed via PowerShell"
}
# 3. Reverse shell patterns
elseif ($Command -match '/dev/tcp/') {
    $Reason = "Potential reverse shell (/dev/tcp)"
}
elseif ($Command -match 'bash\s+-i\s+>&') {
    $Reason = "Potential reverse shell (bash -i)"
}
elseif ($Command -match 'nc\s.*-e\s*(sh|bash|/bin|cmd|powershell)') {
    $Reason = "Potential reverse shell (netcat)"
}
# 4. Exfiltration of credentials via network
elseif ($Command -match 'cat.*(id_rsa|id_ed25519|\.ssh|\.gnupg|\.aws\\credentials|\.env).*\|\s*curl') {
    $Reason = "Exfiltrating credential files via network"
}
elseif ($Command -match 'curl.*-d\s*@.*(id_rsa|id_ed25519|\.ssh|\.env|\.aws)') {
    $Reason = "Uploading credential files via curl"
}
elseif ($Command -match 'Get-Content.*(id_rsa|\.ssh|\.aws|\.env).*Invoke-WebRequest') {
    $Reason = "Exfiltrating credential files via PowerShell"
}
# 5. Mass deletion (catch variants beyond static deny list)
elseif ($Command -match 'rm\s+-[rf]*\s+/' -and $Command -notmatch 'rm\s+-[rf]*\s+\./') {
    $Reason = "Recursive deletion targeting root filesystem"
}
elseif ($Command -match 'Remove-Item.*-Recurse.*[A-Z]:\\$') {
    $Reason = "Recursive deletion targeting drive root"
}
# 6. Modifying Claude Code config via Bash
elseif ($Command -match '(sed|awk|echo|tee|printf|Set-Content|Out-File).*\.claude[/\\](settings|config)') {
    $Reason = "Attempting to modify Claude Code configuration via Bash"
}

# --- Block or allow ---
if ($Reason) {
    Add-Content -Path $AuditLog -Value "BLOCKED: $Reason`nCommand: $Command" -ErrorAction SilentlyContinue
    [Console]::Error.WriteLine("BLOCKED by safety hook: $Reason")
    exit 2
}

exit 0
