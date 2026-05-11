# AGENTS.md

Scope: `home/neovim/*`

## Source of truth

- `default.nix` installs Neovim and all Nix-managed editor tooling.
- `config/` is symlinked directly to `~/.config/nvim` via Home Manager.
- `config/lsp-registry.json` is the single source of truth for enabled LSP servers.

## LSP workflow

- Do **not** reintroduce Mason for installing LSP servers.
- LSP binaries are installed by Nix from `config/lsp-registry.json`.
- Do not add `nvim-treesitter` back unless you need functionality beyond Neovim's built-in tree-sitter support.
- Keep `config/init.lua` generic; do not hardcode a server list there.
- If you remove a plugin, remove it from both `config/init.lua` and `config/nvim-pack-lock.json`.
- For a simple LSP add/change, edit only `config/lsp-registry.json`.
- If a server needs custom settings, add `config/lua/lsp/overrides/<name>.lua` and set `"override": "<name>"` in the registry.
- If a server needs helper packages beyond the main LSP binary, add `extraPackageAttrPaths` in the registry.

## Registry conventions

- `packageAttrPath` and `extraPackageAttrPaths` are JSON arrays of Nix attr path segments.
  - Example: `["nodePackages", "typescript-language-server"]`
- Keep entries keyed by LSP server name.
- Put shared fields in the registry:
  - `cmd`
  - `filetypes`
  - `root_markers`
- Put nontrivial `settings` in override files, not inline in the registry.

## Validation

1. Stage the Neovim files you changed plus `home/wesbragagt.nix` if imports changed.
2. Rebuild with:
   - `rebuild build`
   - Use the `rebuild` shell alias so the current host is detected automatically.
3. Sanity check the registry shape with:
   - `jq . home/neovim/config/lsp-registry.json`
4. If needed, open Neovim and confirm the server attaches for the target filetype.
