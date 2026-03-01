# Review PR Comments

> **Process review comments left by automated reviewers (GitHub Copilot, Codex, Claude) or peer developers on your pull request.**

## When to Use

- After creating a PR and waiting for automated/peer reviews
- When review comments arrive on your GitHub pull request
- Before merging — to address all feedback

---

## Step 1: Fetch PR comments

```bash
# Find the PR number for current branch
PR_NUMBER=$(gh pr view --json number -q '.number' 2>/dev/null)
echo "PR #$PR_NUMBER"

# List all review comments
gh api repos/{owner}/{repo}/pulls/$PR_NUMBER/comments --jq '.[].body' 2>/dev/null || \
gh pr view $PR_NUMBER --comments
```

**If no PR exists:** This command only applies after a PR has been created. Go back to the workflow and create a PR first.

## Step 2: Process each comment

For each review comment:

1. **Read the comment** — understand what the reviewer is asking
2. **Evaluate the feedback** — is it valid? Does it conflict with project conventions?
3. **If valid** — make the fix
4. **If questionable** — challenge it. Use `/superpowers:receiving-code-review` for rigorous evaluation before blindly implementing suggestions

```
/superpowers:receiving-code-review
```

> **IMPORTANT:** Do not blindly agree with every review comment. Verify technical accuracy before implementing. The receiving-code-review skill enforces this discipline.

## Step 3: Re-run quality gates on changes

After fixing review comments, verify no regressions:

```
/simplify
```

Then verify:

```
Task tool → subagent_type: "verify-app", prompt: "Run verification and report pass/fail verdict."
```

## Step 4: Push fixes

```bash
git add -A
git commit -m "fix: address PR review comments"
git push
```

---

## Checklist

- [ ] Fetched all PR review comments
- [ ] Evaluated each comment (don't blindly agree)
- [ ] Fixed valid issues
- [ ] Ran `/simplify` on changes
- [ ] Verified via `verify-app` agent
- [ ] Pushed fixes
