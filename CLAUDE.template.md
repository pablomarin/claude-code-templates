# CLAUDE.md - [Project Name]

## Project Overview

### What Is This?
[PROJECT DESCRIPTION - 2-3 sentences explaining what this project does]

### Tech Stack
[TECH STACK - Fill in per project]
- **Backend:**
- **Frontend:**
- **Database:**
- **Deploy:**

### File Structure

**Replace this example with YOUR project's actual structure. Claude uses this to navigate your codebase.**

```
project/
├── src/              # Backend code
├── frontend/         # Frontend code
├── tests/            # Test files
├── docs/             # Documentation
│   ├── prds/         # Product requirements
│   ├── plans/        # Design documents
│   ├── solutions/    # Compounded learnings (searchable)
│   └── CHANGELOG.md  # Historical record
└── .claude/          # Claude Code configuration
    ├── commands/     # Workflow commands (ENFORCED)
    └── rules/        # Coding standards (auto-loaded)
```

### Design Direction (optional — delete if not needed)
<!-- Remove this comment block and fill in your project's aesthetic:
- Premium, dark-mode-first aesthetic (think Linear.app, Vercel.com)
- Font pairing: Instrument Serif for headlines, Geist for body
- Color palette: deep navy (#0A0E27), electric blue (#3B82F6), warm white (#F8FAFC)
- No generic "AI slop" — avoid Inter, purple gradients, evenly-spaced 3-card grids
-->

### Visual Design Preferences
- Never generate plain static rectangles for hero sections, landing pages, or key visual moments
- Always include at least one dynamic/animated element: SVG waves, Lottie, shader gradients, or canvas particles
- Prefer organic shapes (blobs, curves, clip-paths) over straight edges and 90-degree corners
- Animations must respect `prefers-reduced-motion` — provide static fallbacks

### Deployment (optional — delete if not needed)
<!-- Remove this comment block and fill in your deployment setup:
- Hosted on Vercel, auto-deploys from `main` branch
- Use `vercel --yes` for preview deployments
- Environment variables managed via Vercel dashboard
-->

### Key Commands

**Replace the examples below with your project's actual commands:**

```bash
# Workflows (MANDATORY - hooks enforce these)
/new-feature <name>     # Full feature workflow
/fix-bug <name>         # Bug fix with systematic debugging
/quick-fix <name>       # Trivial changes only (< 3 files)
/codex <instruction>    # Second opinion from OpenAI Codex CLI

# Example project commands:
cd src && uv run pytest                    # Run tests
cd src && uv run ruff check .              # Lint
git checkout -b feat/{name}                # Start feature
```

---

## Detailed Rules

All coding standards, workflow rules, and policies are in `.claude/rules/`.
These files are auto-loaded by Claude Code with the same priority as this file.

**What's in `.claude/rules/`:**
- `principles.md` — Top-level principles and design philosophy
- `workflow.md` — Decision matrix for choosing the right command
- `worktree-policy.md` — Git worktree isolation rules
- `critical-rules.md` — Non-negotiable rules (branch safety, TDD, etc.)
- `memory.md` — How to use persistent memory and save learnings
- `security.md`, `testing.md`, `api-design.md` — Coding standards
- Language-specific: `python-style.md`, `typescript-style.md`, `database.md`, `frontend-design.md`
