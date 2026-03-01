# Third-Party Skill Security Audit

**NEVER install community skills without running through this checklist.**

## Quick Audit (all skills)

| Check                | What to look for                             | Red flag                                                         |
| -------------------- | -------------------------------------------- | ---------------------------------------------------------------- |
| **`bins` field**     | Does the skill define binary executables?    | Any `bins` entry — can run arbitrary code on install             |
| **`install` steps**  | Does it run commands during installation?    | `curl`, `wget`, `pip install`, `npm install` in install metadata |
| **Tool permissions** | What tools does the skill request?           | Unrestricted `Bash`, `Write` to system paths, network access     |
| **HTTP hooks**       | Does it add HTTP hooks to settings?          | URLs pointing to unknown external services                       |
| **Source code**      | Read the SKILL.md and any referenced scripts | Obfuscated code, encoded strings, `eval()` calls                 |

## Trust Signals

| Signal           | Trustworthy                                 | Suspicious                                              |
| ---------------- | ------------------------------------------- | ------------------------------------------------------- |
| **Publisher**    | Known org (anthropic, official marketplace) | Anonymous, new account, no history                      |
| **Adoption**     | Widely used, many installs                  | Zero or very few users                                  |
| **Maintenance**  | Recent updates, responds to issues          | Abandoned, no commits in months                         |
| **Permissions**  | Minimal — only requests what it needs       | Broad — requests Bash, Write, network for a simple task |
| **Transparency** | Source code visible, clear documentation    | Closed source, vague description                        |

## Red Flags — Block Immediately

- Skill runs `curl | sh` or `wget | bash` during install
- Skill requests `Bash(*)` (unrestricted shell) without justification
- Skill adds HTTP hooks that POST to external URLs you don't control
- Skill modifies `.claude/settings.json` permissions (deny/allow rules)
- Skill contains base64-encoded or obfuscated strings
- Skill writes to paths outside the project directory

## Approval Process (Teams)

1. Developer finds a skill they want to install
2. Run through the Quick Audit checklist above
3. Check Trust Signals — at least 3 of 5 should be green
4. If any Red Flag is present — **do not install**, escalate to team lead
5. Approved skills get added to `enabledPlugins` in the shared settings template

## Rules

1. NEVER install a skill without auditing its SKILL.md and install metadata
2. NEVER approve skills with `bins` fields or arbitrary install scripts
3. NEVER allow skills that request broader permissions than their function requires
4. ALWAYS prefer official marketplace skills over community/unknown publishers
5. ALWAYS review skill updates — a safe skill can become malicious after an update
