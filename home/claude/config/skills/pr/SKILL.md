---
name: pr
description: Create or update a GitHub pull request for the current branch, committing pending changes first. Use when the user wants to open a PR, update an existing PR, or ship a branch for review.
argument-hint: "[optional PR title, base branch, or description context]"
---

# pr

Create or update a GitHub pull request from the current branch.

Always commit first, then push, then create or update the PR.

The PR description should be written for reviewers who need to quickly understand:

- what problem changed
- why the change matters
- what behavior is different
- how the implementation works
- how it was verified

Avoid implementation-first descriptions.

## Step 1: Commit any uncommitted changes

Invoke the `/commit` skill to stage and commit any pending changes before creating or updating the PR.

If the working tree is clean, skip this step and proceed.

## Step 2: Check for an existing PR

```bash
gh pr view --json number,title,body,baseRefName,url 2>/dev/null
```

If a PR already exists for this branch:

* Commit any new changes first
* Push the branch
* Regenerate the PR body using the full current diff against the base branch
* Do not describe only the latest commits
* Update the existing PR description:

```bash
gh pr edit --body "<updated body>"
```

* Output the PR URL
* Say that the existing PR description was updated
* Skip PR creation

Only proceed to Step 3 if no PR exists yet.

## Step 3: Identify branch and base

Get the current branch:

```bash
git branch --show-current
```

Determine the base branch in this order:

1. If the user specified a base branch, use it.
2. Prefer `main` if it exists.
3. Use `master` if `main` does not exist.
4. Fall back to the remote default branch:

```bash
git remote show origin | grep 'HEAD branch'
```

If the current branch is the base branch, stop and tell the user they need to create a feature branch before opening a PR.

## Step 4: Push the branch

```bash
git push -u origin HEAD
```

If the push is rejected because of a non-fast-forward update, do not force-push.

Tell the user the branch is behind or diverged and ask how they want to proceed.

## Step 5: Understand the change before writing

Inspect the branch relative to the base:

```bash
git log origin/<base>..HEAD --oneline
git diff origin/<base>..HEAD --stat
git diff origin/<base>..HEAD --name-only
```

When needed, inspect relevant diffs:

```bash
git diff origin/<base>..HEAD -- <file>
```

Before writing the PR body, identify:

* the user-facing or operator-facing problem
* the behavior change
* any config or API changes
* important implementation decisions
* migration/backward compatibility impact
* verification and test coverage
* any risks, rollout notes, or follow-ups

Do not simply summarize files changed.

## Step 6: Generate the PR title

Derive a clear title from the branch name, commits, and user-provided context.

Rules:

* Under 72 characters when possible
* Sentence case
* No trailing period
* Prefer behavior/value over implementation detail
* Avoid vague titles like `Update handoff logic`

Good examples:

```text
Gate Invoice Tracker handoff on support ingestion readiness
```

```text
Add per-rule readiness check for invoice support docs
```

```text
Skip handoff when required support docs are not processed
```

## Step 7: Generate the PR body

Write the body using this structure.

Use optional sections only when they add value.

```md
## Summary

<Start with the behavior change in plain English. Explain the problem this PR solves and why it matters. Keep this section reviewer-friendly and avoid leading with internal implementation details.>

<If relevant, explain who benefits: users, ops, downstream systems, maintainers, etc.>

## Behavior change

<Describe what is different after this PR. Include defaults and backward compatibility when relevant.>

## Implementation

<Explain the important implementation details. Focus on decisions reviewers need to understand, not every file touched.>

## Testing

<Describe meaningful test coverage or manual verification.>

## Notes

<Optional. Include rollout notes, config examples, limitations, risks, or follow-ups only if useful.>
```

### PR writing rules

<rules>
* Lead with behavior, not internals.
* Explain the problem before the solution.
* Prefer “what changed and why” over a raw changelog.
* Do not dump every modified file unless each one matters to reviewer understanding.
* Keep the Summary to 1–2 short paragraphs.
* Use `Behavior change` when runtime behavior, config behavior, user behavior, or operational behavior changes.
* Use `Implementation` for architecture decisions, non-obvious tradeoffs, or important mechanics.
* Use `Testing` for tests, dry-runs, manual checks, or verification.
* Use `Notes` only for useful extras like config examples, rollout details, risks, or compatibility.
* If there is no meaningful content for an optional section, omit it.
* Use bullets for scanability.
* Avoid markdown tables unless they clearly improve readability.
* Keep it factual. Do not pad with filler.
* If the user provided context, incorporate it into the Summary or Notes section instead of replacing the template.
</rules>

### Config or status-rule changes

If the PR adds config, flags, statuses, rules, or state transitions, include a simple example.

Prefer:

````md
## Notes

Example config:

```json
{
  "require_support_ingestion_processed": true
}
```

Default behavior:

* omitted → current behavior
* `false` → current behavior
* `true` → enables the new readiness gate
````

For status handling, prefer clear bullets:

````md
A document is considered processed only when:

- `auto_passed` → processed

All other states are treated as not processed:

- missing row
- `needs_review`
- `failed`
````

### Design rationale

If the implementation involved a meaningful tradeoff, explain it plainly.

Prefer:

```md
This check happens in application code instead of SQL so skipped records can still emit a decision explaining why they did not proceed.
```

Avoid:

```md
SQL projects, rules decide.
```

Clever phrasing is okay in comments, but PR descriptions should optimize for fast reviewer comprehension.

## Step 8: Prohibited PR body content

<rules>
* Do not reference review tooling, AI agents, internal review steps, or scratch artifacts.
* Do not mention `pi`, `pi /review`, `claude`, `Claude Code`, `gpt`, `Copilot`, `ultrareview`, sibling-agent reviews, or any AI/code-assist tool by name.
* Do not include “Follow-up from <review>”, “Addressed per <review>”, or “<reviewer> flagged …”.
* Re-attribute reasoning to the code itself.
* Do not reference internal files from review tooling, such as `reviews/*.md`, transcripts, or scratch notes.
* Do not describe the process that produced the change. Describe the change and the reasoning behind it.
</rules>

Good:

```md
Ties on `update_time` were not deterministic, so this now uses `(update_time, id)` for stable ordering.
```

Bad:

```md
Claude review flagged that ties on `update_time` were not deterministic.
```

## Step 9: Create or update the PR

Create a new PR:

```bash
gh pr create \
  --base <base-branch> \
  --title "<title>" \
  --body "<body>"
```

After creation, output the PR URL.

If updating an existing PR:

```bash
gh pr edit --body "<updated body>"
```


After updating, output the PR URL.

## What NOT to do

<rules>
* Do not force-push to fix a rejected push.
* Do not open a PR from the default branch to itself.
* Do not skip `/commit` when there are uncommitted changes.
* Do not add `--draft` unless the user explicitly asks for a draft PR.
* Do not mark the PR as ready for review unless the user asks.
* Do not request reviewers unless the user asks.
* Do not create a PR body that is just a commit list.
* Do not lead with low-level implementation details when there is a clear product, ops, or behavior impact.
</rules>
