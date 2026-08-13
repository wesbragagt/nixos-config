---
name: handoff
description: Hand off the current task to a fresh background agent running in its own workmux worktree, passing a self-contained prompt synthesized from this conversation's context. Use when the user wants to outsource, delegate, or "hand off" implementation work to a separate agent session (e.g. "handoff this fix", "outsource it to a ccd agent", "spin up an agent to do X").
argument-hint: "[task focus or branch name] (optional — inferred from conversation if omitted)"
---

# Handoff

Package everything learned in this conversation into a **self-contained prompt**,
create a new workmux **session worktree** off the base branch, and launch a `ccd`
agent in it fed that prompt. The new agent has **none** of this conversation's
context — the prompt is the only thing it sees, so it must stand alone.

`ccd` is the user's alias for `claude --dangerously-skip-permissions`.

## Step 1 — Synthesize the handoff prompt

Write a complete brief to a temp file (`/tmp/handoff-<slug>.md`). It MUST contain,
in this order:

1. **Context** — what the work is and where it lives (repo, package, paths). Name
   the exact files involved.
2. **Findings / root cause** — everything diagnosed so far (don't make the agent
   re-investigate). Include concrete evidence: error messages, commands run,
   what was ruled out.
3. **Goal & success criteria** — verifiable outcomes, not "make it work".
4. **Step-by-step plan** — numbered, each step naming the file(s) to edit and what
   changes. Mark optional steps as optional.
5. **Tests & verification** — exact commands to run and what "green" means.
6. **Constraints** — carry over the house rules that apply: no `terragrunt apply`
   / no cluster mutation, no AI attribution in commits, never commit `prd/`/`prds/`,
   stay surgical, match existing style. Whether to open a PR when done.

Keep it surgical and unambiguous. A senior engineer with zero prior context should
be able to execute it top to bottom.

## Step 2 — Pick a branch name

- If the user gave one in `$ARGUMENTS`, use it.
- Otherwise derive a short kebab-case name from the task (e.g.
  `fix-docs-site-webhook-500`). Store it as `<branch>`.

## Step 3 — Create the worktree (background, no agent flag)

```sh
workmux add <branch> -P /tmp/handoff-<slug>.md -b
```

- `-P` copies the prompt to `<worktree>/.workmux/PROMPT-<branch>.md`.
- `-b` keeps the new tmux window/session in the background (don't steal focus).
- **Do NOT rely on `-a ccd`.** When the repo's `.workmux.yaml` defines plain
  `zsh` panes (no `<agent>` placeholder), `-a` has nowhere to inject and the
  agent never launches. Launch it explicitly in Step 4 instead.

## Step 4 — Launch the `ccd` agent in the pane

Find the tmux target (workmux `mode: session` → session named `<window_prefix><branch>`,
commonly `stack/<branch>`; `window_prefix` comes from `.workmux.yaml`):

```sh
TARGET=$(tmux list-windows -a -F '#{session_name}:#{window_index}' 2>/dev/null | grep -m1 '<branch>')
tmux send-keys -t "$TARGET" 'ccd "$(cat .workmux/PROMPT-<branch>.md)"' Enter
```

The pane's CWD is the worktree root, so the relative `.workmux/PROMPT-<branch>.md`
path resolves. `ccd` is an interactive-shell alias and resolves inside the tmux
pane's zsh.

## Step 5 — Verify and report

Wait a few seconds, then confirm the agent picked up the prompt:

```sh
sleep 8
tmux capture-pane -t "$TARGET" -p | tail -25
```

Report to the user:
- The worktree path (`workmux path <branch>`) and tmux session (`<window_prefix><branch>`).
- That the `ccd` agent is running and has the brief.
- How to follow it: `tmux attach -t '<window_prefix><branch>'`, `workmux dashboard`,
  or `workmux capture <branch>`.

## Notes

- This is a **read-of-context, write-of-worktree** operation — it does not modify
  the current working tree. The agent works on its own branch off the base.
- If `workmux capture <branch>` later errors with "No agent running", Step 4's
  launch didn't take — re-send the `tmux send-keys` line.
- Loops/monitors should use Sonnet, but a one-shot handoff agent uses `ccd`
  (the user's default Claude alias) unless the user says otherwise.
