---
name: markdown-review
description: Open local Markdown files for the user to review in a centered tmux Glow popup. Use when the user asks to review, read, inspect, or edit Markdown documents in the terminal.
argument-hint: "[path-to-markdown-file ...]"
---

# Markdown review

Open local Markdown files in the user's terminal with `glow-review` or `mk`.

`glow-review` opens one Markdown file or a directory. The command opens a centered tmux popup. Glow wraps the document at 100 columns. Glow watches opened files and reloads them after edits.

## Review one file

Run this command from the file's directory or use an absolute path:

```bash
glow-review path/to/document.md
```

The command requires a readable Markdown file.

## Review selected files

Run `mk` with no arguments to select one or more Markdown files with `fzf`:

```bash
mk
```

Use Tab to select files. Press Enter to open Glow's file list in the popup. Glow then lets the user select and move between the chosen documents.

`mk path/to/document.md` opens that one file directly.

The temporary file list is deleted when Glow exits.

## Edit the document

While Glow displays a local document, the user can press `e`.

Glow starts `nvim` from `$EDITOR` for the same file. When the user exits Neovim, Glow returns and reloads the document.

Do not send `e` automatically. The user must choose to edit.

## Agent rules

- Use `glow-review` for one local Markdown file or directory.
- Use `mk` when the user must choose or review multiple local Markdown files.
- Do not use `tmux attach`.
- Do not capture the popup to verify appearance. Tmux popup contents are outside pane scrollback.
- Do not kill a user session, window, pane, or popup.
- Tell the user that `e` opens the file in Neovim.

## Example

```bash
glow-review docs/implementation-plan.md
```
