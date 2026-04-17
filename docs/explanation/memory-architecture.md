# How Memory Works

Claude Code has **two layers of memory** that this template configures. Together, they ensure Claude never "wakes up with amnesia."

## Memory Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    GLOBAL (all projects)                         │
│  ~/.claude/CLAUDE.md          ← Your personal instructions       │
│  ~/.claude/settings.json      ← Global hooks (PreCompact, Stop)  │
│  ~/.claude/hooks/             ← Global hook scripts              │
│  ~/.claude/rules/             ← Personal rules (all projects)    │
└──────────────────────────────────────────────────────────────────┘
         │ loaded every session
         ▼
┌──────────────────────────────────────────────────────────────────┐
│                PROJECT-LEVEL (per project)                       │
│  CLAUDE.md                    ← Project description (slim, yours)│
│  .claude/rules/               ← Coding standards + workflow rules│
│  CONTINUITY.md                ← Task state (Done/Now/Next)       │
│  .claude/settings.json        ← Project hooks + permissions      │
│  .mcp.json                    ← MCP servers (Playwright, Context7)│
│  docs/solutions/              ← Compounded knowledge base        │
└──────────────────────────────────────────────────────────────────┘
         │ loaded every session
         ▼
┌──────────────────────────────────────────────────────────────────┐
│                AUTO MEMORY (Claude writes this)                  │
│  ~/.claude/projects/<project>/memory/                            │
│    MEMORY.md                  ← Index (first 200 lines loaded)   │
│    debugging.md               ← Debugging patterns               │
│    patterns.md                ← Code patterns discovered         │
│    preferences.md             ← Your preferences learned         │
└──────────────────────────────────────────────────────────────────┘
```

## What Each Layer Does

| Layer                 | Who writes it | What it contains                                 | When it loads                                 |
| --------------------- | ------------- | ------------------------------------------------ | --------------------------------------------- |
| **Global CLAUDE.md**  | You (once)    | Memory instructions, personal preferences        | Every session, all projects                   |
| **Project CLAUDE.md** | You           | Project description, tech stack, commands (slim) | Every session, this project                   |
| **`.claude/rules/`**  | Template      | Workflow, principles, coding standards           | Every session, this project                   |
| **CONTINUITY.md**     | Claude        | Task state: Done/Now/Next/Blockers               | Auto-loaded via `@CONTINUITY.md` in CLAUDE.md |
| **Auto Memory**       | Claude        | Learned patterns, solutions, preferences         | MEMORY.md first 200 lines auto-loaded         |
| **docs/solutions/**   | Claude        | Bug fixes, error solutions, patterns             | On-demand when relevant                       |

## How Memory Persists

Three hooks work together to prevent memory loss:

```
Session Start                    During Session                Before Compaction
     │                               │                              │
     ▼                               ▼                              ▼
┌──────────┐                  ┌──────────────┐              ┌──────────────┐
│SessionStart│                │  Stop Hook   │              │PreCompact Hook│
│  Hook     │                │  (global)    │              │  (global +   │
│           │                │              │              │   project)   │
│ Injects:  │                │ Reminds:     │              │ Saves:       │
│ • Branch  │                │ "Save any    │              │ All session  │
│   (silent │                │  learnings   │              │ learnings to │
│   context)│                │  to memory"  │              │ auto memory  │
│           │                │              │              │ before       │
│ Via JSON  │                │ (lightweight │              │ compression  │
│ additiona-│                │  - no block) │              │              │
│ lContext  │                │              │              │              │
└──────────┘                  └──────────────┘              └──────────────┘
```

## What Claude Remembers

Over time, Claude's auto memory accumulates:

- **Project patterns**: Build commands, test conventions, code style
- **Bug solutions**: Root causes and fixes (also in `docs/solutions/`)
- **Your preferences**: Tool choices, workflow habits, communication style
- **Architecture notes**: Key files, module relationships, abstractions
- **Debugging insights**: Common error causes, tricky edge cases

## Managing Memory

```bash
# View/edit memory files in Claude Code
/memory

# Tell Claude to remember something explicitly
"Remember that we use pnpm, not npm"
"Save to memory that the API tests require a local Redis instance"

# Tell Claude to forget something
"Forget the Redis requirement, we switched to in-memory cache"

# Force enable/disable auto memory (if needed)
# Auto memory is ON by default — no env var needed
# export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1  # Force off
# export CLAUDE_CODE_DISABLE_AUTO_MEMORY=0  # Force on
```
