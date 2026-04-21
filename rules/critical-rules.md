# Critical Rules

- **CHECK BRANCH** - Never work on `main`
- **USE WORKFLOW COMMANDS** - `/new-feature`, `/fix-bug`, or `/quick-fix`
- **SYSTEMATIC DEBUGGING** - Use `/superpowers:systematic-debugging` for bugs
- **DESIGN REVIEW** - Get a second opinion (Codex or user) on the plan BEFORE implementing
- **CONTRARIAN GATE** - Never self-certify approach selection; Codex validates the skip
- **TDD MANDATORY** - Red-Green-Refactor via Superpowers
- **E2E TESTING** - Use the `verify-e2e` agent to execute user use cases for any user-facing change. Project-type matrix: fullstack=API+UI, api=API only, cli=CLI only. **No cheating in ARRANGE or VERIFY** — never raw DB writes (`psql -c "INSERT"`, `mysql -e "UPDATE"`, `mongosh --eval`), internal/undocumented endpoints, or file-injection on disk, even to seed test data. E2E setup goes through the app's public API, public signup/login, app CLI, UI, or documented seed commands (`make seed-dev`, `manage.py loaddata`). **If the sanctioned path is broken, FIX it** (see NO BUGS LEFT BEHIND below). See `.claude/rules/testing.md` for the full interface matrix.
- **UPDATE STATE** - CONTINUITY.md + CHANGELOG.md (Stop hook enforces)
- **RESEARCH FIRST** - WebSearch/WebFetch/Context7 before implementing
- **CHALLENGE ME** - Don't blindly agree
- **NO BUGS LEFT BEHIND** - Never defer known issues "for later." Fix everything found during reviews, testing, and implementation before moving on. If a reviewer or tool flags an issue, it gets fixed in the same branch — no "follow-up PR" for known problems. This includes deployment, infrastructure, and configuration issues, not just code bugs.
