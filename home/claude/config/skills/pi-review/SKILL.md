---
name: pi-review
description: Delegate a code review to pi (`pi /skill:review`) running in a tmux window, then dispatch subagents to fix each finding and check it off the review file. Use when the user wants an automated review-and-fix loop over their current changes.
argument-hint: "[optional review target — PR, branch, or files]"
---

# pi-review

Run an external review with `pi`, then act on it. The flow is:

1. Launch `pi /skill:review` in a tmux window (it writes findings to `reviews/review-*.md`).
2. Read the findings the review wrote.
3. Dispatch one subagent per actionable finding to implement the fix.
4. Check off `- [ ]` → `- [x]` in the review file as each fix lands.

You (the main agent) orchestrate. pi does the reviewing; subagents do the fixing.

## Step 1 — Launch pi in a tmux window

Work from the repo's current directory. The pi `review` skill writes to `reviews/review-YYYYMMDD-HHMMSS.md`, so record which files already exist before launching to identify the new one afterward.

```bash
mkdir -p reviews
ls reviews/ > /tmp/pi-review-before.txt 2>/dev/null || : > /tmp/pi-review-before.txt

# Run pi INTERACTIVELY so its live TUI (tool calls, progress, findings) streams
# into the pane. Do NOT use -p: print mode emits only the final assistant message,
# so the pane stays blank for the minutes the review is actually running.
tmux new-window -d -n pi-review -c "$PWD" \
  'pi "/skill:review '"$ARGUMENTS"'"'
```

- `$ARGUMENTS` carries an optional target (PR number, branch, file paths). When empty, pi infers the target from the workspace (staged → unstaged → branch diff).
- Interactive pi runs the review autonomously (tools auto-approve) and, when done, returns to an idle prompt rather than exiting — so the window stays alive and capturable on its own. Detect completion by the new `reviews/` file, not by process exit.
- To watch live, the user can `tmux select-window -t pi-review` (or attach the session). You (the orchestrator) poll with `capture-pane` instead of attaching.

## Step 2 — Wait for completion

Poll the pane; do not attach. pi review can take a few minutes on a large diff.

```bash
# New review file that appeared since launch:
comm -13 <(sort /tmp/pi-review-before.txt) <(ls reviews/ | sort)

# And confirm pi is idle (the "Working..." spinner is gone):
tmux capture-pane -t pi-review -p -S -200
```

Completion signal: a new `reviews/review-*.md` file exists **and** the pane shows pi back at an idle prompt (no `Working...` spinner). Take the newest matching file as the review file.

If the pane shows an error (auth, missing skill, no reviewable target) or pi is blocked waiting on a prompt instead of progressing, surface it to the user and stop — don't guess.

## Step 3 — Read and parse findings

Read the review file. Actionable findings are Markdown task items, each tagged with severity and confidence:

```
- [ ] [must-fix][high] <description tied to a file/line>
- [ ] [should-fix][medium] ...
- [ ] [optional][low] ...
```

Collect every `- [ ]` line with its category heading (Architecture, Potential bugs, Coverage gaps, Refactor suggestions). Skip `Strengths` and any already-checked `- [x]` items.

Default scope: address `must-fix` and `should-fix`. Treat `optional` as opt-in — list them and ask the user before spending effort, unless they already said "fix everything."

## Step 4 — Dispatch subagents per finding

For each in-scope finding, launch a subagent to implement the fix. Independent findings go out in parallel (multiple Agent calls in one message); findings that touch the same files should be sequenced to avoid clobbering edits.

Use `code-writer-simple` for localized changes, `code-writer-complex` for multi-file or architectural ones.

Give each subagent:
- the exact finding text (severity, category, description),
- the file/line evidence from the review,
- an instruction to make the minimal change that resolves it and to follow existing code style,
- an instruction to report back what it changed (and to flag if it disagrees with the finding rather than forcing a bad change).

A finding that's wrong or out of scope is a valid outcome — record it, don't fabricate a fix.

## Step 5 — Check off the review file

After a subagent confirms a fix, flip that item in the review file from `- [ ]` to `- [x]` (Edit the exact line). Keep the file as the source of truth for progress so a re-run resumes cleanly.

For findings deliberately skipped or rejected, leave them unchecked and add a brief trailing note, e.g. `- [ ] ... — skipped: <reason>`.

## Step 6 — Report

Summarize for the user:
- review file path,
- counts: fixed / skipped / rejected,
- one line per fix (what changed, where),
- anything that needs their decision (optional items, disagreements with the review).

Do not commit unless the user asks — defer to the `commit` skill.

## Notes

- Never `tmux kill-server`. Clean up only the `pi-review` window you created (`tmux kill-window -t pi-review`) once you've read the file — interactive pi won't exit on its own, so this window must be killed explicitly.
- The review file is the contract between pi and the subagents — read it from disk, don't rely on scraping the tmux pane for findings (the pane is only for live progress and the idle/error completion signal).
- If pi isn't installed or the `review` skill isn't discoverable (`pi list`), say so and stop.
