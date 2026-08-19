---
name: pr
description: Create or update a GitHub pull request for the current branch, committing pending changes first. Use when the user wants to open a PR, update an existing PR, or ship a branch for review.
argument-hint: "[optional PR title, base branch, or description context]"
---

# pr

Create or update a GitHub pull request (PR) from the current branch.

Always commit, then push, then create or update the PR.

## Steps

1. Invoke the `/commit` skill if the working tree has changes. Skip if it is clean.
2. Check for an existing PR: `gh pr view --json number,title,body,baseRefName,url 2>/dev/null`
3. Find the branch and the base. Use `git branch --show-current`.
4. Push the branch: `git push -u origin HEAD`
5. Read the change: `git log origin/<base>..HEAD --oneline` and `git diff origin/<base>..HEAD --stat`
6. Write the title and the body.
7. Create or update the PR.

## Base branch

Select the base in this order:

1. The base the user gives.
2. `main`, if it exists.
3. `master`, if `main` does not exist.
4. The remote default branch: `git remote show origin | grep 'HEAD branch'`

Stop if the current branch is the base. Tell the user to create a feature branch.

## Push failures

Do not force-push after a rejected push. Tell the user the branch diverged. Ask how to continue.

## Existing PR

If a PR exists:

1. Commit new changes.
2. Push the branch.
3. Write the body again from the full diff against the base, not only the new commits.
4. Run `gh pr edit --body "<updated body>"`.
5. Print the PR URL. Say that you updated the description.

## Title

Write a title of 72 characters or less. Use sentence case. Do not use a final period. Name the behavior, not the code.

Good: `Skip handoff when required support docs are not processed`

## Body

Use this structure. Remove an optional section that has no useful content.

```md
## Summary

<The behavior change in plain words. The problem. Why it matters.>

## Behavior change

<What is different after this PR. Include defaults and compatibility.>

## Implementation

<Important decisions and tradeoffs. Not every file.>

## Testing

<Tests, dry-runs, or manual checks.>

## Notes

<Optional: config examples, risks, rollout notes, follow-ups.>
```

## Body rules

<rules>
* Write the body in Simplified Technical English (ASD-STE100).
* Use the simplest correct word. Use one term for one thing.
* Use active voice and present tense. Name the actor.
* Keep each sentence to 25 words or less.
* Do not use idioms, jokes, or figures of speech.
* Keep the full body under 500 words.
* Give the problem before the solution.
* Keep the Summary to one or two short paragraphs.
* Use bullets. Avoid tables.
* Do not list every changed file.
* Do not write a commit list.
* Add a short config example when the PR adds config, flags, statuses, or state rules.
* Explain a meaningful tradeoff in plain words.
* Fold user-supplied context into Summary or Notes.
* Never name an AI tool, a review tool, a reviewer, or a scratch file.
* Never describe the process that made the change. Describe the change.
</rules>

## Prohibited actions

<rules>
* Do not force-push.
* Do not open a PR from the default branch to itself.
* Do not skip `/commit`.
* Do not use `--draft` unless the user asks.
* Do not mark ready for review or request reviewers unless the user asks.
</rules>
