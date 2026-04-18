# Why a Harness, Not a Template

A template is files you copy once. A harness is a system that runs continuously around your work — catching slip-ups, enforcing discipline, compounding knowledge. Claude Codex Forge started as a template and grew into a harness through months of production iteration.

## Why two coding agents?

One coding agent will confidently ship the wrong thing. Two will disagree — and disagreement is the signal.

The harness uses **Claude Code** (Anthropic) and **OpenAI's Codex** together:

- **Claude designs.** It proposes plans, writes code, explains tradeoffs.
- **Codex reviews independently.** It reads the same plan or diff without seeing Claude's reasoning, and flags issues Claude missed.
- **Engineering Council adjudicates ambiguity.** When the two disagree or when a strategic choice has real risk, a 5-advisor council (3 Claude personas + 2 Codex personas + Codex chairman) runs in parallel and returns a verdict with mandatory minority reports.

This is not "more review is better." It's **two separately-trained models with different failure modes**. Codex catches things Claude consistently misses; Claude catches things Codex consistently misses. Without Codex, you lose that diversity — the workflow still runs, but every step falls back to user review.

## Discipline by construction

You can skip good practice when it feels optional. The harness makes it structural:

- `/new-feature` and `/fix-bug` commands bake in TDD, research-before-design, approach comparison, and a contrarian gate — you follow them or you don't ship
- `check-workflow-gates.sh` literally blocks `git commit`, `git push`, and `gh pr create` until CONTINUITY.md shows `Code review loop`, `Simplified`, and `Verified` markers
- `check-bash-safety.sh` blocks dangerous Bash patterns before they run (pipe-to-shell, reverse shells, credential exfiltration)
- `ConfigChange` hook logs every modification to `.claude/settings.json` so permission escalation is auditable
- Every Stop turn reminds Claude to update state; `check-state-updated.sh` blocks if the reminder is ignored

Discipline is guided by commands and **guarded by hooks**. You can still override (it's your machine) but every override is explicit.

## Continuous memory

Sessions end. State doesn't.

- **Auto-memory** persists locally across sessions and context compaction (the `PreCompact` hook rescues learnings *before* compression, so nothing gets dropped silently)
- **`CONTINUITY.md`** — Done / Now / Next, updated every turn, reloaded every session, travels with the repo
- **`docs/CHANGELOG.md`** — historical record, travels with the repo
- **`docs/solutions/`** — bug root causes + patterns, indexed by problem type, travels with the repo via git

Three of those travel with the repo. Auto-memory is local/per-worktree (it doesn't sync across teammates), but the git-tracked files mean every root cause, decision, and pattern compounds across weeks and teammates. The same bug never needs to be debugged twice.

## Team-scale by default

One GitHub repo becomes the hub:

- Shared `CLAUDE.md` — project description, tech stack, commands
- Shared `.claude/rules/` — coding standards, workflow rules, security baseline
- Shared `.claude/commands/` — custom slash commands all developers use
- Shared hooks — consistent quality gates across the team

Multiple developers run parallel Claude sessions via **auto-created git worktrees** (`/new-feature` and `/fix-bug` spawn them). Each session is isolated — own branch, own filesystem, own auto-memory — but loads the same project context. You can have three Claude sessions working on three features simultaneously without them mixing state.

## Inheritance

Started from [Boris Cherny's workflow](https://www.anthropic.com/engineering/claude-code-best-practices) (Claude Code's creator), Anthropic's official best practices, and [OpenClaw's pre-compaction memory patterns](https://github.com/openclaw/openclaw/discussions/6038). Evolved into a dual-agent harness through ongoing iteration.

Boris's key insight drives the whole system:

> "Probably the most important thing to get great results out of Claude Code — **give Claude a way to verify its work**. If Claude has that feedback loop, it will **2-3x the quality** of the final result."

Every phase of the workflow is a verification loop. Research verifies assumptions against current docs. Plan review verifies design against the codebase. TDD verifies implementation against tests. Code review loops verify correctness against two reviewers. `/simplify`, `verify-app`, `verify-e2e` — each one another loop. That accumulated verification is what makes the output reliable.
