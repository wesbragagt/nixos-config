# AGENTS.md

Operational checklist for this repo.

## Daily workflow (do this every time)

1. Make changes in the right place (`hosts/`, `modules/`, `home/`, `scripts/`, etc.).
2. Stage everything: `git add -A`.
3. Rebuild:
   - Host switch: `sudo nixos-rebuild switch --flake .#nixos-hp`
   - Dry run: `sudo nixos-rebuild build --flake .#nixos-hp`
4. If it fails, scroll to the **last `error:`** line first.

## High-value reminders

- **Flake only sees git-tracked/staged content**. Untracked edits are invisible.
- **Do not edit** `hosts/*/hardware-configuration.nix` manually.
- **No secrets in repo** (public keys only). Add `agenix` or `sops-nix` when needed.
- Prefer **NixOS/Home Manager modules** over raw packages when available.
- Put packages in the right scope:
  - System-wide: `common.nix` / `modules/*.nix`
  - User-only: `home/programs.nix` (`home.packages`)

## Repo map (where to change what)

- `flake.nix` — host entries + standalone HM output
- `common.nix` — shared base (user, ssh, sudo, locale, core packages)
- `modules/*.nix` — system features (graphics/audio/fonts/hyprland/login/keyboard/tailscale)
- `hosts/<host>/default.nix` — host-specific settings
- `home/wesbragagt.nix` — HM entrypoint
- `home/hyprland.nix` — WM behavior/keybinds/exec
- `home/waybar.nix` — bar config + CSS
- `home/programs.nix` — user programs, rofi wiring, ssh config
- `scripts/` + `rofi/` — launcher scripts and themes

## Common action items

### Add a new host

1. Create `hosts/<newhost>/`
2. Copy machine-generated `hardware-configuration.nix` there
3. Copy `hosts/nixos-hp/default.nix` → `hosts/<newhost>/default.nix`, update `networking.hostName`
4. Add `nixosConfigurations.<newhost>` in `flake.nix`
5. `git add -A && sudo nixos-rebuild switch --flake .#<newhost>`

### Add a package

- User package first: `home/programs.nix`
- System package only when system integration is needed

### Use flake inputs in `home/`

- Ensure module args include `inputs`:
  `{ pkgs, config, inputs, ... }:`
- Reference package via:
  `inputs.<name>.packages.${pkgs.stdenv.hostPlatform.system}.default`

## Desktop iteration shortcuts

- Reload Hyprland: `hyprctl reload`
- Restart Waybar: `pkill waybar && hyprctl dispatch exec waybar`
- Restart dock: `pkill nwg-dock && hyprctl dispatch exec "nwg-dock-hyprland ..."`
- Cursor changes: `hyprctl setcursor <theme> <size>`

## Environment-specific notes

- Host currently configured: `nixos-hp`
- `allowUnfree = true` is enabled
- Passwordless sudo for `wheel` is enabled
- SSH authorized key for `wesbragagt` is pinned in `common.nix`
- DHCP IP may change; update SSH host alias/known_hosts as needed
