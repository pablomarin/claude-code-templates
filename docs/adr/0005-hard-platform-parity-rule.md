# 0005 — Cross-platform parity is a hard invariant, not a "should"

## Status

Accepted (2026-04-28)

## Context

Forge maintains both bash (`.sh`) and PowerShell (`.ps1`) implementations of every hook (ADR 0002). A "soft" parity rule (parity is encouraged) historically produced subtle bugs: PowerShell's `Write-Host` is invisible to in-PS callers; `$LASTEXITCODE` gets clobbered by every native call; `Start-Job` runs in `$HOME` on PS 5.1 unless `-WorkingDirectory` is passed (PS 6+ only). PR #1 (drift-hygiene) hit five distinct PowerShell quirks during code review. Without a hard parity contract, drift slips into production.

## Considered Options

- **Option A (chosen):** Hard parity is a code-review checkpoint and a test contract. `tests/template/test-contracts.sh` asserts byte-equivalent stderr messages and structurally-equivalent stdout for cross-platform hook pairs. Reviewers explicitly check both `.sh` and `.ps1` for every hook change. PR cannot land if parity fails.
- **Option B:** Soft parity ("should match"). Reviewers flag drift on a best-effort basis. Rejected: PR #1 demonstrated that human reviewers miss platform-specific bugs; mechanical contracts catch them.
- **Option C:** Build a single source-of-truth (e.g., a YAML spec) and generate both `.sh` and `.ps1` from it. Rejected: Forge has no build step (ADR 0003); introducing a code-generation pipeline would violate the no-build-step decision.

## Decision

Cross-platform parity is a hard invariant. Test contracts in `tests/template/test-contracts.sh` enforce byte-equivalent and structural parity on the surfaces that matter (stderr messages, exit codes, output structure). Code review for any hook change must touch both `.sh` and `.ps1`.

## Consequences

- ✅ Drift between platforms is caught mechanically, not by human attention alone.
- ✅ Cross-platform bugs surface in CI, not in the field.
- ⚠️ Every hook change is two implementations. Estimated cost: 1.5x–2x the time of a single-platform change. Acceptable.
- ⚠️ Test contracts must be maintained as new hooks are added. Adds to the test surface.
- 🔮 If Forge ever moves to a portable hook runtime (ADR 0002 consequence), this rule's cost-benefit changes and the ADR may be superseded.
