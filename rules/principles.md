# Principles

## Top-Level Principles

**Work doggedly.** Be autonomous. Continue working toward the user's goal until you can no longer make progress.

**Work smart.** When debugging, think deeply. Add logging to check assumptions.

**Check your work.** Run code to verify it works. Check logs after starting processes.

**Research first.** AI knowledge has a cutoff. Use the `research-first` agent (or Context7/WebFetch/WebSearch manually) to check current docs before design. See Phase 2 in `/new-feature` and Phase 2.5 in `/fix-bug`.

**Learn from competitors.** Before implementing features, research how established products solved it.

## Core Design Philosophy

- **Brutal simplicity** over clever solutions (KISS)
- **Composition** over inheritance
- **Immutability** by default
- **DRY** - if it appears twice, extract it
- **Reuse** - check if a utility exists before creating new code
