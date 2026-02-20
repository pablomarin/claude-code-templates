# Codex Second Opinion

> **Get a second opinion from OpenAI's Codex CLI.**
> Use for code reviews, design plan reviews, architecture feedback, or general questions.

---

## Prerequisites

- **Codex CLI** installed: `npm i -g @openai/codex` or `brew install --cask codex`
- **Codex authenticated**: `codex login` (requires ChatGPT Plus/Pro/Business or API key)
- Verify: `codex --version` (requires v0.101.0+)

---

## Mode Detection

Analyze `$ARGUMENTS` to determine the mode:

- **Code Review Mode**: Arguments match review-related keywords — "review code", "code review", "review changes", "review diff", "review PR", or bare "review"
- **Design Review Mode**: Arguments reference a plan, design, or architecture — "review the plan", "review the design", "review architecture"
- **General Mode**: Everything else (give opinion, analyze code, brainstorm, ask a question)

---

## A) Code Review Mode

Triggered when `$ARGUMENTS` matches review-related keywords.

### Step 1: Ask what to review

Use `AskUserQuestion` with these options:

| Option | Flag |
|--------|------|
| Uncommitted changes (staged + unstaged) | `--uncommitted` |
| Changes vs main branch | `--base main` |
| A specific commit | `--commit <SHA>` (ask user for SHA) |

### Step 2: Run Codex review

> **IMPORTANT:** `codex exec review` preset flags (`--uncommitted`, `--base`, `--commit`) cannot be combined with a custom prompt argument. Use `-c developer_instructions=` to inject focus areas instead.

```bash
codex exec review \
  -c model="gpt-5.3-codex" \
  -c model_reasoning_effort="xhigh" \
  -c developer_instructions="Focus on: correctness, security vulnerabilities, performance bottlenecks, error handling gaps, and maintainability. Flag anything that could break in production." \
  --sandbox read-only \
  --ephemeral \
  --color never \
  [--uncommitted | --base main | --commit SHA]
```

**If reviewing a branch**, add `--title` for context:
```bash
codex exec review \
  -c model="gpt-5.3-codex" \
  -c model_reasoning_effort="xhigh" \
  -c developer_instructions="Focus on: correctness, security vulnerabilities, performance bottlenecks, error handling gaps, and maintainability. Flag anything that could break in production." \
  --sandbox read-only \
  --ephemeral \
  --color never \
  --base main \
  --title "feat: add user authentication"
```

**Timeout: 1200000ms (20 minutes)** — Codex reasoning can take time.

### Step 3: Display output

Display Codex's output verbatim to the user. Do not summarize or edit it.

---

## B) Design Review Mode

Triggered when `$ARGUMENTS` references a plan, design, or architecture document.

This is used during the **mandatory design review step** (Phase 3.3 of `/new-feature` and `/fix-bug`).

### Step 1: Identify the plan

Check for the most recent plan file:
```bash
ls -t docs/plans/ 2>/dev/null | head -1
```

Also check if there's a plan in the current conversation context. If the user specified a file, use that.

### Step 2: Run Codex exec with the plan

```bash
codex exec \
  -c model="gpt-5.3-codex" \
  -c model_reasoning_effort="xhigh" \
  --sandbox read-only \
  --ephemeral \
  --color never \
  "Review the implementation plan in [plan file path]. Evaluate:
  1. ARCHITECTURE: Are there design flaws or over-engineering?
  2. RISK: What could go wrong? What edge cases are missing?
  3. ALTERNATIVES: Is there a simpler approach?
  4. DEPENDENCIES: Are there breaking changes or version conflicts?
  5. TESTING: Is the plan testable? What's hard to test?
  Flag any concerns that should be addressed BEFORE implementation begins."
```

**Timeout: 1200000ms (20 minutes)** — Codex reasoning can take time.

### Step 3: Display output

Display Codex's output verbatim to the user. Do not summarize or edit it.

---

## C) General Mode

Triggered for everything that isn't a code review or design review request.

### Step 1: Gather context

Run these in parallel for situational awareness:

```bash
git diff --stat
```

```bash
git status --short
```

If the user's instruction references a specific file, read that file to include as context.

### Step 2: Run Codex exec

Construct the prompt by combining the user's instruction with the gathered context.

```bash
codex exec \
  -c model="gpt-5.3-codex" \
  -c model_reasoning_effort="xhigh" \
  --sandbox read-only \
  --ephemeral \
  --color never \
  "{user's instruction with gathered context}"
```

**Timeout: 1200000ms (20 minutes)** — Codex reasoning can take time.

### Step 3: Display output

Display Codex's output verbatim to the user. Do not summarize or edit it.

---

## Error Handling

- **Codex not installed**: Tell the user to run `npm i -g @openai/codex` (or `brew install --cask codex` on macOS) and `codex login`
- **Authentication error**: Tell the user to run `codex login`
- **Timeout**: Inform the user that Codex took too long and suggest simplifying the request
- **Empty output**: Report that Codex returned no output and suggest rephrasing

---

## Quick Reference

| Use case | Command pattern |
|----------|----------------|
| Review uncommitted changes | `codex exec review --uncommitted` |
| Review branch vs main | `codex exec review --base main --title "description"` |
| Review a specific commit | `codex exec review --commit SHA` |
| Review a design plan | `codex exec "Review the plan in docs/plans/..."` |
| General second opinion | `codex exec "Your question or instruction"` |
