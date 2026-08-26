---
name: mnemosyne-memory
description: Persist and recall durable project facts (decisions, host quirks, gotchas, conventions) for this nixos-config repo using the Mnemosyne CLI. Use when the user says to remember/recall something, when starting work on a recurring task, or before repeating investigation already done in a prior session.
---

# Mnemosyne project memory

This repo has a dedicated Mnemosyne memory bank, isolated from every other
project. Use the CLI directly — no MCP server is configured.

Every command MUST use this exact environment:

```bash
export MNEMOSYNE_DATA_DIR=/home/wesbragagt/.local/share/mnemosyne/nixos-config
export MNEMOSYNE_BANK=nixos-config
uvx --from 'mnemosyne-memory[mcp]' mnemosyne <command> [args...]
```

`--bank` is a flag on `mnemosyne mcp` only; every other command (`store`,
`recall`, `stats`, ...) reads the bank from `MNEMOSYNE_BANK`. Passing
`--bank` to a data command fails — it is parsed as a positional argument.

## When to store a memory

Store a fact after it is confirmed true, not speculative:

- A decision and its reason (e.g. "chose `chromium-webapps` module over `programs.chromium` because both add a duplicate Chromium derivation").
- A host-specific quirk or gotcha discovered through debugging (e.g. Widevine override needed for Spotify Web DRM).
- A repo convention not obvious from file layout alone.
- Corrections the user gives about how something in this repo actually works.

```bash
uvx --from 'mnemosyne-memory[mcp]' mnemosyne store "<fact>" "<source>"
```

`<source>` is a short label (e.g. `session`, `user-correction`, `debugging`).

## When to recall

Before starting non-trivial work in this repo (new host setup, module
refactor, recurring debugging), recall relevant memory first:

```bash
uvx --from 'mnemosyne-memory[mcp]' mnemosyne recall "<topic>"
```

Recalled memory is background context. Current user instructions and the
actual repo state on disk always take precedence over a stale memory.

## Other commands

```bash
# list what is stored
uvx --from 'mnemosyne-memory[mcp]' mnemosyne stats

# fix/update an existing memory by id (id comes from recall output)
uvx --from 'mnemosyne-memory[mcp]' mnemosyne update <id> "<new content>"

# remove a stale/wrong memory
uvx --from 'mnemosyne-memory[mcp]' mnemosyne delete <id>
```

## Scope

- `MNEMOSYNE_DATA_DIR` and `MNEMOSYNE_BANK=nixos-config` together pin this to
  one project-local store. Never point these at a different directory/bank
  for this repo's memories.
- This is CLI-only by design so it works from any harness that can run shell
  commands, not just MCP-capable clients.
