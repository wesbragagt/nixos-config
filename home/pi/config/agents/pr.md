---
name: pr
description: Create a GitHub pull request for the current branch. Commits first, then pushes and opens a PR with a generated title and body.
tools: bash
---

Create a GitHub pull request from the current branch. Always commit first, then push, then open the PR.

## Step 1: Commit any uncommitted changes

Use the commit agent to stage and commit any pending changes. If the working tree is clean, skip this step.

## Step 2: Check for an existing PR

Run `gh pr view --json number,title,body,baseRefName 2>/dev/null`

If a PR already exists for this branch:
- Push the branch
- Regenerate the PR body based on the full current diff against the base
- Update the existing PR description with `gh pr edit --body "<updated body>"`
- Output the PR URL and note the description was updated
- Skip Steps 3-5 below

Only proceed to Step 3 if no PR exists yet.

## Step 3: Identify branch and base

Run `git branch --show-current` to get the current branch.

Determine the base branch:
1. If the user specified a base branch, use it
2. Check if `main` or `master` exists — prefer `main`
3. Fall back to the repo's default remote HEAD

If the current branch IS the base branch, stop and tell the user they need to be on a feature branch.

## Step 4: Push the branch

Run `git push -u origin HEAD`

If the push fails (non-fast-forward), do NOT force-push. Tell the user and ask how to proceed.

## Step 5: Generate PR title and body

Look at commits: `git log origin/<base>..HEAD --oneline`
Get diff summary: `git diff origin/<base>..HEAD --stat`

**Title**: Clear, concise, under 72 chars, sentence case, no trailing period. Incorporate user context if provided.

**Body**:
```
## Summary

<1-2 paragraphs explaining the goal>

## Changes

- <bullet list of notable changes from commits and diff>

## Technical Details

<implementation notes or architecture decisions — omit if nothing non-obvious>
```

## Step 6: Create the PR

```bash
gh pr create --base <base-branch> --title "<title>" --body "<body>"
```

Output the PR URL.

## What NOT to do

- Do not force-push to fix a rejected push — ask the user
- Do not open a PR from the default branch to itself
- Do not skip the commit step if there are uncommitted changes
- Do not add `--draft` unless the user explicitly asked
- Do not request reviewers unless the user asked
