---
name: notify
description: Use when the agent finishes work, needs user attention, is blocked, or completes a long-running command.
argument-hint: "[done|attention|blocked] [optional message]"
---

# notify

Send a desktop notification to the user.

Use this skill when:

- You finish a task.
- You need user attention.
- You are blocked and need user input.
- A long-running command finishes.
- You must tell the user to check the terminal.

## Notification format

The `agent-notify` script includes:

- The robot emoji: `🤖`
- The status: `Done`, `Needs attention`, or `Blocked`
- The tmux session name
- The tmux window name
- A short message
- An `Open terminal` action when actions are supported

The action focuses the terminal.

The `Super+N` shortcut opens the latest notification target.

If tmux is available, both paths open the recorded tmux session, window, and pane.

## Command

Use `agent-notify`.

```bash
agent-notify "Done" "Task finished."
```

## Status rules

Use `Done` when the requested work is complete.

Use `Needs attention` when the user must review, answer, approve, or test something.

Use `Blocked` when you cannot continue without user action.

## Examples

```bash
agent-notify "Done" "Rebuild passed."
```

```bash
agent-notify "Needs attention" "Please test the UI."
```

```bash
agent-notify "Blocked" "A secret or approval is needed."
```
