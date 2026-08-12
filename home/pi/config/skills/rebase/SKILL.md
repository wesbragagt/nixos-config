---
name: rebase
description: "Rebase the current branch onto a target branch with careful conflict resolution. Use when the user asks to rebase their branch onto another branch."
---

# Rebase

Rebase the current branch.

## Arguments

Optional target branch.

Behavior:
- No arguments: fetch origin, determine the default branch, and rebase onto it
- `origin`: fetch origin, determine the default branch, and rebase onto it
- `origin/branch`: fetch origin and rebase onto the local `branch`
- `branch`: fetch origin and rebase onto the local `branch`

## Steps

1. Determine the default branch:
   ```bash
   git remote show origin | awk '/HEAD branch/ {print $NF}'
   ```
2. Parse arguments:
   - no args → target branch is the default branch
   - contains `/` (for example `origin/develop`) → use the part after `/`
   - `origin` → target branch is the default branch
   - anything else → target branch is the argument
3. Run:
   ```bash
   git fetch origin
   ```
4. Rebase onto the local branch:
   ```bash
   git rebase <branch>
   ```
5. If conflicts occur, handle them carefully
6. Continue until the rebase is complete

## Handling conflicts

- Before resolving a conflict, understand what changed on the target branch
- For each conflicting file, inspect recent target-branch changes:
  ```bash
  git log -p -n 3 <target> -- <file>
  ```
- Preserve both the target branch changes and the current branch changes where appropriate
- After resolving a conflict, stage the file and continue with:
  ```bash
  git rebase --continue
  ```
- If a conflict is too complex or unclear, ask the user for guidance before proceeding

## Output

When complete, return a compact summary in this format:

```text
Rebased N commits onto <target>
[If conflicts:]
  - <file>: <one line describing resolution>
  - <file>: <one line describing resolution>
```
