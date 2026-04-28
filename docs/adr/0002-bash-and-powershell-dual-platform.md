# 0002 — Forge ships bash and PowerShell hooks in parallel

## Status

Accepted (2026-04-28)

## Context

Forge is a Claude Code template toolkit that installs hooks (SessionStart, PreToolUse, Stop, PostToolUse, PreCompact, ConfigChange) into downstream projects. Claude Code runs on macOS, Linux, and Windows. Anthropic's documented hook examples are bash. Windows ships PowerShell 5.1 (no `pwsh` by default). Cross-platform support is non-negotiable for a template toolkit serving teams that may span platforms.

## Considered Options

- **Option A (chosen):** Maintain a `.sh` and `.ps1` version of every hook, kept in lockstep via test contracts. setup.sh installs the bash family on Unix; setup.ps1 installs the PowerShell family on Windows.
- **Option B:** Bash-only, requiring Windows users to install Git Bash or WSL. Rejected because Forge users include Windows-native developers without WSL; the install friction would gate adoption.
- **Option C:** Single Node.js or Python wrapper script per hook, dispatched by Claude Code. Rejected because Forge has no runtime dependency today (pure config + scripts), and adding a runtime would inflate setup complexity for the audience.

## Decision

Every hook ships in two files: `<name>.sh` (bash) and `<name>.ps1` (PowerShell). The two implementations have byte-equivalent stderr messages, byte-equivalent exit codes, and structurally-equivalent output. A test contract (`tests/template/test-contracts.sh`) asserts parity on the surfaces that matter.

## Consequences

- ✅ Forge runs natively on every platform Claude Code supports.
- ✅ Test contracts enforce parity, surfacing drift early.
- ⚠️ Every hook change is two implementations. Code review must touch both files. PR #1 (drift-hygiene) demonstrated the cost: 7 review iterations to converge cross-platform.
- ⚠️ PowerShell quirks (output streams, `$LASTEXITCODE` capture, `Start-Job` CWD propagation, `powershell.exe` 5.1 vs `pwsh` 7+) require careful authoring. See `tests/template/test-default-branch.sh` and the gotchas captured in code-review history.
- 🔮 If a future Claude Code feature provides a portable hook runtime (e.g., WASM-based hooks), this ADR may be superseded.
