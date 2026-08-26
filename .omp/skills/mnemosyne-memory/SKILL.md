---
name: mnemosyne-memory
description: Persist and recall durable facts, decisions, gotchas, and conventions using the Mnemosyne CLI. Use when the user asks to remember, recall, or manage memory, or when durable context can prevent repeated work.
---

# Mnemosyne memory

Mnemosyne is optional. Enable `mnemosyne: true` in
`/etc/nixos/features.yaml`, then run `rebuild` before using this skill.

Use the installed `mnemosyne` CLI directly. No MCP server is configured.

When this skill is used, display `🌳 Mnemosyne memory` before the first memory action.

Every command MUST use this environment:

```bash
export MNEMOSYNE_DATA_DIR=/home/wesbragagt/.local/share/mnemosyne
export MNEMOSYNE_BANK=default
mnemosyne <command> [args...]
```

`--bank` is a flag on `mnemosyne mcp` only. Other commands (`store`, `recall`,
`stats`, ...) read the bank from `MNEMOSYNE_BANK`. Passing `--bank` to a data
command fails because it is parsed as a positional argument.

## When to store a memory

Store a fact after it is confirmed true, not speculative:

- A decision and its reason (e.g. "chose `chromium-webapps` module over `programs.chromium` because both add a duplicate Chromium derivation").
- A host-specific quirk or gotcha discovered through debugging (e.g. Widevine override needed for Spotify Web DRM).
- A repo convention not obvious from file layout alone.
- Corrections the user gives about how something in this repo actually works.

```bash
mnemosyne store "<fact>" "<source>"
```

`<source>` is a short label (e.g. `session`, `user-correction`, `debugging`).

## When to recall

Before recurring or non-trivial work, recall relevant memory first:

```bash
mnemosyne recall "<topic>"
```

Recalled memory is background context. Current user instructions and the
actual repo state on disk always take precedence over a stale memory.

## Other commands

```bash
# list stored memories
mnemosyne stats

# update a memory by ID from recall output
mnemosyne update <id> "<new content>"

# delete a stale or wrong memory
mnemosyne delete <id>
```

## Scope

- The default bank is shared across projects.
- Use a separate data directory and bank only when the user requests isolated memory.
- This is CLI-only by design so it works from any harness that can run shell
  commands, not just MCP-capable clients.
