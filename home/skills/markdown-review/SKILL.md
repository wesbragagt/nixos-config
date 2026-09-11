---
name: markdown-review
description: Open a local Markdown file for the user to review in a centered tmux Glow popup. Use when the user asks to review, read, inspect, or edit a Markdown document in the terminal.
argument-hint: "<path-to-markdown-file>"
---

# Markdown review

Open a local Markdown file in the user's terminal with `glow-review`.

Use this skill when the user needs to read or review a Markdown file. The command opens a centered tmux popup. Glow wraps the document at 100 columns. Glow watches the file and reloads it after edits.

## Command

Run this command from the file's directory or use an absolute path:

```bash
glow-review path/to/document.md
```

The command requires a readable file. Give the user the exact error if it fails.

## Edit the document

While Glow displays a local document, the user can press `e`.

Glow starts `nvim` from `$EDITOR` for the same file. When the user exits Neovim, Glow returns and reloads the document.

Do not send `e` automatically. The user must choose to edit.

## Agent rules

- Use `glow-review` only for local Markdown files.
- Do not use `tmux attach`.
- Do not capture the popup to verify appearance. Tmux popup contents are outside pane scrollback.
- Do not kill a user session, window, pane, or popup.
- Tell the user that `e` opens the file in Neovim.

## Example

```bash
glow-review docs/implementation-plan.md
```
