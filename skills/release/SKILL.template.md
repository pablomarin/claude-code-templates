---
name: release
description: Create a release PR between environments (dev→test or test→prod). Use when deploying features to test or production. Invoke with /release test or /release prod.
---

# Release PR Creator

Create a release pull request that summarizes all changes being promoted between environments.

## Usage

```
/release test    — Create PR from dev → test
/release prod    — Create PR from test → prod
```

## Workflow

### Step 1: Determine Target

Read the argument passed to the skill:
- `test` → base: `test`, head: `dev`
- `prod` → base: `prod`, head: `test`

If no argument or an invalid argument is provided, ask the user: "Which environment? `test` or `prod`?"

### Step 2: Fetch and Compare

Run these commands:
```bash
git fetch origin <base> <head>
git log --oneline origin/<base>..origin/<head> --no-merges
```

**If there are zero commits**, tell the user: "There are no new changes to release to `<target>`. Nothing to do." and stop.

### Step 3: Gather Commit Details

Get the full commit messages for all non-merge commits between the two branches:
```bash
git log origin/<base>..origin/<head> --no-merges --format="--- COMMIT %h ----%n%s%n%n%b%n"
```

Read through ALL commit messages carefully. Each squash-merged PR appears as a single commit whose subject line contains the PR number (e.g. `feat: something (#1234)`).

### Step 4: Categorize Changes

Group every PR into one of these categories based on commit message prefixes and content:

- **Features** — new capabilities, new endpoints, new UI components
- **Fixes** — bug fixes, regressions, error handling corrections
- **Improvements** — refactors, performance, configuration changes, enhancements to existing features
- **Chores** — dependency updates, CI/CD, infrastructure, formatting, docs

Combine related PRs under a single bullet when they are part of the same feature (e.g., multiple SharePoint sync PRs grouped together).

### Step 5: Build PR Description

Use this exact template:

```markdown
## Summary

Release from **<head>** → **<base>** encompassing <N> PRs merged since the last <environment> deploy.

---

### Features

- **Feature Name** (#PR1, #PR2)
  - Detail 1
  - Detail 2

### Fixes

- **Fix description** (#PR) — short explanation of what was wrong and what was fixed

### Improvements

- **Improvement description** (#PR1, #PR2) — short explanation

### Chores

- **Chore description** (#PR) — short explanation

---

## PRs Included

| PR | Title |
|----|-------|
| #XXXX | PR title |
```

**Rules:**
- Omit any category section that has zero items (e.g., if there are no Chores, don't include that heading)
- The "PRs Included" table must list ALL PRs in reverse chronological order
- Feature descriptions should include enough detail for stakeholders to understand what shipped
- Fix descriptions should briefly explain what was broken and how it was resolved

### Step 6: Determine Today's Date

Get today's date:
```bash
date +%m/%d
```

Use this for the PR title. Never rely on dates from conversation context or memory.

### Step 7: Create the PR

Build the title based on target:
- test: `TEST MM/DD`
- prod: `PROD MM/DD`

Create the PR:
```bash
gh pr create --base <base> --head <head> --title "<TITLE>" --body "<BODY>"
```

Report the PR URL to the user when done.

## Guidelines

- Always fetch fresh branch data before comparing
- Never include a "Test Plan" section in the PR body
- Always use `date` command for today's date, never infer it
- If `gh pr create` fails because a PR already exists, inform the user and provide the existing PR URL
