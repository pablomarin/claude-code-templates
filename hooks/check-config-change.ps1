# .claude/hooks/check-config-change.ps1
# ConfigChange hook: logs config file modifications mid-session.
# Optionally blocks removal of deny rules from settings.json (strict mode).
#
# Input (JSON via stdin): {session_id, cwd, hook_event_name, source, file_path}
# Output: JSON to stdout — {"decision":"block","reason":"..."} to reject changes.

$Input = $input | Out-String
$Data = $Input | ConvertFrom-Json -ErrorAction SilentlyContinue

$FilePath = if ($Data.file_path) { $Data.file_path } else { "unknown" }
$Source = if ($Data.source) { $Data.source } else { "unknown" }
$FileName = Split-Path $FilePath -Leaf -ErrorAction SilentlyContinue
if (-not $FileName) { $FileName = "unknown" }

# Always log config changes for visibility
[Console]::Error.WriteLine("Config changed: $FileName (source: $Source, path: $FilePath)")

## --- STRICT MODE (uncomment to block deny-rule removals) ---
#
# if ($FileName -eq "settings.json" -and (Get-Command git -ErrorAction SilentlyContinue)) {
#     $DenyBefore = (git show HEAD:$FilePath 2>$null | Select-String -Pattern '"deny"' | Measure-Object).Count
#     $DenyAfter = (Get-Content $FilePath -ErrorAction SilentlyContinue | Select-String -Pattern '"deny"' | Measure-Object).Count
#     if ($DenyAfter -lt $DenyBefore) {
#         [Console]::Error.WriteLine("BLOCKED: deny rules were removed from $FileName. This may indicate permission escalation.")
#         exit 2
#     }
# }

exit 0
