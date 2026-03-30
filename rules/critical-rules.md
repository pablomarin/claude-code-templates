# Critical Rules

- **CHECK BRANCH** - Never work on `main`
- **USE WORKFLOW COMMANDS** - `/new-feature`, `/fix-bug`, or `/quick-fix`
- **SYSTEMATIC DEBUGGING** - Use `/superpowers:systematic-debugging` for bugs
- **DESIGN REVIEW** - Get a second opinion (Codex or user) on the plan BEFORE implementing
- **TDD MANDATORY** - Red-Green-Refactor via Superpowers
- **E2E TESTING** - User use cases for any user-facing changes (Playwright for web, API/CLI verification for non-browser)
- **UPDATE STATE** - CONTINUITY.md + CHANGELOG.md (Stop hook enforces)
- **RESEARCH FIRST** - WebSearch/WebFetch/Context7 before implementing
- **CHALLENGE ME** - Don't blindly agree
- **NO BUGS LEFT BEHIND** - Never defer known issues "for later." Fix everything found during reviews, testing, and implementation before moving on. If a reviewer or tool flags an issue, it gets fixed in the same branch — no "follow-up PR" for known problems. This includes deployment, infrastructure, and configuration issues, not just code bugs.
