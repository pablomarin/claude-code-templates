# Creating Your Own Skills

Use `skills/SKILL.template.md` as a starting point for custom skills.

## Quick Steps

1. Copy the template: `cp skills/SKILL.template.md .claude/skills/my-skill/SKILL.md`
2. Edit the `name` and `description` in the YAML frontmatter
3. Write your instructions in the markdown body
4. Scope `allowed-tools` to the minimum needed
5. Test it: `/my-skill`

## Skill Storage Locations

| Level    | Path                               | Scope             |
| -------- | ---------------------------------- | ----------------- |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project  | `.claude/skills/<name>/SKILL.md`   | This project only |

## Progressive Disclosure (3 levels)

| Level            | When Loaded            | Budget                                             |
| ---------------- | ---------------------- | -------------------------------------------------- |
| **Metadata**     | Always (system prompt) | ~100 tokens per skill — keep `description` concise |
| **Instructions** | On skill activation    | < 5,000 tokens — the SKILL.md body                 |
| **References**   | On demand              | Unlimited — files in `references/`, `scripts/`     |

## Common Mistakes

| Mistake                               | Fix                                                |
| ------------------------------------- | -------------------------------------------------- |
| Vague description ("helps with code") | Be specific: what it does AND when to trigger      |
| Missing trigger phrases               | Include words users would naturally say            |
| `allowed-tools: "*"`                  | Scope to specific tools: `Read, Grep, Bash(git:*)` |
| Huge SKILL.md body (1000+ lines)      | Move details to `references/` files                |
| First person ("I can help you...")    | Write in third person ("Processes PDF files...")   |

> **Cross-platform:** Agent Skills is an open standard. Skills created here also work in Cursor, Codex, and Gemini CLI. See [agentskills.io/specification](https://agentskills.io/specification).
