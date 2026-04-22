# The Complete Workflow

How a feature goes from idea to merged PR.

```
┌─────────────────────────────────────────────────────────────┐
│ 1. START: Launch a Workflow Command                         │
│    /new-feature {name} → creates isolated git worktree      │
│    /fix-bug {name}     → creates isolated git worktree      │
│    /quick-fix {name}   → creates a branch (small changes)   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. PRD PHASE (Custom Commands)                              │
│    /prd:discuss {feature}  → Refine user stories            │
│    /prd:create {feature}   → Generate structured PRD        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. RESEARCH — `research-first` agent (Phase 2 enforcement)  │
│    → Context7 + official docs + changelogs per dependency   │
│    → Produces structured brief in `docs/research/`          │
│    → Design phase reads this before any planning starts     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. DESIGN + REVIEW LOOP (iterates until no P0/P1/P2)        │
│                                                             │
│    ┌───────────────────────────────────────────┐            │
│    │ a. /superpowers:brainstorming             │            │
│    │    → Interactive design exploration       │            │
│    │    → Followed by /council contrarian gate │            │
│    │      after approach comparison            │            │
│    └──────────────────┬────────────────────────┘            │
│                       ▼                                     │
│    ┌───────────────────────────────────────────┐            │
│    │ b. /superpowers:writing-plans             │            │
│    │    → Write detailed TDD tasks             │            │
│    └──────────────────┬────────────────────────┘            │
│                       ▼                                     │
│    ┌───────────────────────────────────────────┐            │
│    │ c. Claude + /codex review the plan        │◄──┐        │
│    │    → Two independent validations          │   │        │
│    │    → If no Codex: user reviews instead    │   │        │
│    └──────────────────┬────────────────────────┘   │        │
│                       ▼                            │        │
│              ┌────────────────┐                    │        │
│              │ P0/P1/P2?      │── Yes ──► Edit ────┘        │
│              └───────┬────────┘          plan               │
│                      No                                     │
│                      ▼                                      │
│              No P0/P1/P2s → Plan approved ✓                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. EXECUTE (Superpowers Plugin)                             │
│    /superpowers:subagent-driven-development                 │
│    → TDD enforced (RED-GREEN-REFACTOR)                      │
│    → Dispatch Plan (DAG) controls parallelism               │
│    → Auto-format on save (ruff/prettier)                    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 5b. DEBUG (if bugs encountered)                             │
│    /superpowers:systematic-debugging                        │
│    → 4-phase root cause analysis                            │
│    → NO fixes without investigation first                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. CODE REVIEW LOOP (repeats until no P0/P1/P2 issues)      │
│                                                             │
│    ┌──────────────────────┐ ┌────────────────────────────┐  │
│    │ /codex review        │ │ /pr-review-toolkit:review-pr│ │
│    │ → Independent second │ │ → 6 specialized agents      │ │
│    │   opinion from Codex │ │   (silent failures, tests,  │ │
│    │                      │ │    types, comments, code)   │ │
│    └──────────┬───────────┘ └─────────────┬───────────────┘ │
│               └──────────┬────────────────┘                 │
│                          ▼                                  │
│               ┌─────────────────────┐                       │
│               │ P0/P1/P2 issues?    │── Yes ──► Fix ──┐     │
│               └──────────┬──────────┘                 │     │
│                          No (P3s acceptable)     ┌────┘     │
│                          ▼                       │          │
│               Reviews passed ✓       ◄───────────┘          │
│                                      (run both again)       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. CODE SIMPLIFY                                            │
│    /simplify                                                │
│    → Cleans up architecture, improves readability           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. VERIFY                                                   │
│    "Use the verify-app agent"                               │
│    → Unit tests + migrations + lint + types                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. E2E USE CASE TESTS (if user-facing changes)              │
│    "Use the verify-e2e agent"                               │
│    → Feature mode: validate new user journeys               │
│    → Regression mode: replay tests/e2e/use-cases/ suite     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 10. COMPOUND LEARNINGS                                      │
│    docs/solutions/ + auto memory                            │
│    → Bug root causes, patterns, solutions saved             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 11. COMMIT & CREATE PR                                      │
│    → Update CONTINUITY.md (Done/Now/Next)                   │
│    → Update docs/CHANGELOG.md (if 3+ files changed)         │
│    → git add, commit, push to origin                        │
│    → gh pr create                                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 12. WAIT FOR PR REVIEWS                                     │
│    → Copilot, Claude, Codex auto-review on GitHub           │
│    → Peer reviews from other developers                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 13. PROCESS PR REVIEW COMMENTS                              │
│    /review-pr-comments                                      │
│    → Address comments from all reviewers                    │
│    → Fix issues, push, wait for approval                    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 14. FINISH                                                  │
│    /finish-branch                                           │
│    → Merge PR to main (if not already merged)               │
│    → Delete remote branch                                   │
│    → Delete local branch + worktree                         │
│    → Restart servers from main                              │
└─────────────────────────────────────────────────────────────┘
```

## Why This Workflow?

Based on Boris Cherny's key insight:

> "Probably the most important thing to get great results out of Claude Code — **give Claude a way to verify its work**. If Claude has that feedback loop, it will **2-3x the quality** of the final result."

The harness operationalizes that insight across every phase:

- **Research** gives Claude current docs (not stale training data)
- **Plan review loop** gives Claude a second set of eyes _before_ writing code
- **TDD** gives Claude executable tests as its verification loop
- **Code review loop** gives Claude parallel reviewers _after_ writing code
- **Simplify + verify + E2E** give Claude three more verification passes before commit
- **PR reviewers + `/review-pr-comments`** give Claude automated reviewers _after_ the PR is open
- **`docs/solutions/` + auto-memory** give Claude learning feedback so the same bug is never debugged twice
