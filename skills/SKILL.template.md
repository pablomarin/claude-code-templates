---
# === REQUIRED FIELDS ===
name: my-skill-name
#   Max 64 chars. Lowercase letters, numbers, hyphens only.
#   Becomes the /slash-command (e.g., /my-skill-name).
#   Must match the parent directory name.
#   Cannot contain "anthropic" or "claude".

description: >
  One-paragraph description of what this skill does AND when to use it.
  This is how Claude discovers your skill from 50+ installed skills —
  make it specific. Include trigger phrases users would naturally say.
  Max 1024 chars. Write in third person. Be "pushy" to avoid under-triggering.
  Example: "Generate PDF reports from data. Use when the user asks to
  create a report, export to PDF, or build a document."

# === OPTIONAL FIELDS ===

# argument-hint: [filename] [format]
#   Hint shown during autocomplete when user types /my-skill-name

# license: Apache-2.0
#   Or: "Proprietary. See LICENSE.txt"

# compatibility: Requires git and docker
#   Max 500 chars. Environment requirements.

# disable-model-invocation: false
#   If true: only user can invoke via /name. Description NOT loaded into
#   context at startup. Use for rarely-needed skills to save context budget.

# user-invocable: true
#   If false: hidden from / menu. Only Claude can trigger it.
#   Use for background knowledge skills.

# model: sonnet
#   Override model for this skill (sonnet, opus, haiku).

# context: fork
#   Run in a forked subagent (isolated, no conversation history).

# agent: general-purpose
#   Which subagent when context: fork. Options: Explore, Plan, general-purpose,
#   or a custom agent from .claude/agents/.

# allowed-tools:
#   - Read
#   - Grep
#   - Glob
#   - Bash(git:*)
#   Pre-approved tools (no user confirmation needed). Scope tightly:
#     Read, Grep, Glob           — read-only exploration
#     Bash(git:*)                — git commands only
#     Bash(npm:*), Bash(uv:*)   — package manager only
#   NEVER use "*" (all tools) unless absolutely necessary.

# metadata:
#   author: your-org
#   version: "1.0"
---

# [Skill Name]

> Brief one-liner of what this skill does.

## Instructions

[Main instructions go here. This is Level 2 — loaded when the skill is
triggered. Keep under 500 lines / 5,000 tokens.]

### Step 1: [First action]

[What Claude should do first]

### Step 2: [Second action]

[What Claude should do next]

### Step 3: [Verify]

[How to verify the work]

## Variables

Use these in your skill content:

- `$ARGUMENTS` — all arguments passed (e.g., `/my-skill-name arg1 arg2`)
- `$0`, `$1` — specific arguments by index
- `` !`command` `` — dynamic context (shell output injected before Claude sees it)
- `${CLAUDE_SESSION_ID}` — current session ID

## References

[Link to files in references/ or scripts/ directories. These are Level 3 —
loaded on demand only when Claude needs them.]

<!-- Example:
See `references/PATTERNS.md` for the full pattern library.
Run `scripts/validate.py` to check output.
-->
