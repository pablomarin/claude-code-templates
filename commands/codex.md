# Codex Second Opinion

> **Get a second opinion from OpenAI's Codex CLI.**
> Use for code reviews, plan reviews, architecture feedback, or general questions.

---

## Prerequisites

- **Codex CLI** installed: `npm i -g @openai/codex`
- **Codex authenticated**: `codex login`
- Verify: `codex --version` (requires v0.101.0+)

---

## Mode Detection

Analyze `$ARGUMENTS` to determine the mode:

- **Code Review Mode**: Arguments match review-related keywords — "review code", "code review", "review changes", "review diff", "review PR", or bare "review"
- **General Mode**: Everything else (review a plan, give opinion, analyze architecture, brainstorm, ask a question)

---

## A) Code Review Mode

Triggered when `$ARGUMENTS` matches review-related keywords.

### Step 1: Ask what to review

Use `AskUserQuestion` with these options:

| Option | Flag |
|--------|------|
| Uncommitted changes | `--uncommitted` |
| Changes vs main branch | `--base main` |
| A specific commit | `--commit <SHA>` (ask user for SHA) |

### Step 2: Run Codex review

```bash
codex exec review \
  -c model="gpt-5.3-codex" \
  -c model_reasoning_effort="xhigh" \
  --ephemeral \
  [--uncommitted | --base main | --commit SHA] \
  "Focus on: correctness, security, performance, and maintainability."
```

**Timeout: 600000ms (10 minutes)** — Codex reasoning can take time.

### Step 3: Display output

Display Codex's output verbatim to the user. Do not summarize or edit it.

---

## B) General Mode

Triggered for everything that isn't a code review request.

### Step 1: Gather context

Run these in parallel for situational awareness:

```bash
git diff --stat
```

```bash
git status --short
```

If the user's instruction references a specific file or plan, read that file to include as context.

### Step 2: Run Codex exec

Construct the prompt by combining the user's instruction with the gathered context.

```bash
codex exec \
  -c model="gpt-5.3-codex" \
  -c model_reasoning_effort="xhigh" \
  --sandbox read-only \
  --ephemeral \
  "{user's instruction with gathered context}"
```

**Timeout: 600000ms (10 minutes)** — Codex reasoning can take time.

### Step 3: Display output

Display Codex's output verbatim to the user. Do not summarize or edit it.

---

## Error Handling

- **Codex not installed**: Tell the user to run `npm i -g @openai/codex` and `codex login`
- **Authentication error**: Tell the user to run `codex login`
- **Timeout**: Inform the user that Codex took too long and suggest simplifying the request
- **Empty output**: Report that Codex returned no output and suggest rephrasing
