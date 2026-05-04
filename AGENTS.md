# AGENTS.md

Short operating guide for this repo. Read before making changes.

## What this is

A flake-based NixOS + home-manager configuration. One host so far (`nixos-hp`); structured to add more.

## Layout

- `flake.nix` — `nixosConfigurations.<host>` for full systems, `homeConfigurations.wesbragagt` for non-NixOS Linux (CLI/dotfile parts only).
- `common.nix` — shared NixOS base: user, locale, packages everyone gets, openssh, sudo. Imported by every host.
- `modules/` — system modules toggled in `common.nix` (graphics, audio, fonts, hyprland, login, keyboard).
- `home/` — home-manager. `wesbragagt.nix` is the entry; it imports `hyprland.nix`, `waybar.nix`, `programs.nix`.
- `hosts/<name>/` — per-machine: `default.nix` sets hostname, boot, imports `common.nix`; `hardware-configuration.nix` is auto-generated.
- `rofi/` — rasi theme files wired in via `xdg.configFile` in `home/programs.nix`.
- `scripts/` — shell wrappers packaged via `pkgs.writeShellScriptBin` in home-manager.

## Build / switch loop

```bash
cd ~/nixos-config
git add -A                                    # flake reads from the git tree; untracked = invisible
sudo nixos-rebuild switch --flake .#<host>    # default host: nixos-hp
```

If activation fails, the **last `error:` line** in the noisy stack is the actual cause.

For dry-runs use `nixos-rebuild build` (no activation).

## Adding a new host

1. `mkdir hosts/<newhost>`
2. Boot the target machine; copy its `/etc/nixos/hardware-configuration.nix` into `hosts/<newhost>/`.
3. Copy `hosts/nixos-hp/default.nix` to `hosts/<newhost>/default.nix`; change `networking.hostName`.
4. Add `nixosConfigurations.<newhost>` in `flake.nix`, mirroring `nixos-hp`.
5. `git add -A && sudo nixos-rebuild switch --flake .#<newhost>`.

Per-host overrides go in `hosts/<host>/default.nix`. If something is universal, push it down to `common.nix` or a `modules/*.nix`.

## Adding a package

- **System-wide** (everyone, root included) — `environment.systemPackages` in `common.nix` or a relevant `modules/*.nix`.
- **User-only** (CLI tools, GUI apps) — `home.packages` in `home/programs.nix`. This is the default place; only escalate to system if the package needs setuid/system services/PAM hooks.

For services with NixOS modules (e.g. `programs.thunar`, `services.openssh`), prefer the module over raw packages.

## Conventions

- **Live in git, not in disk**: edits invisible to `nix flake build` until staged. Always `git add -A` before rebuild.
- **No secrets in tree**: only public keys are referenced (e.g. authorized_keys). When secrets are needed, add `agenix` (simpler) or `sops-nix`.
- **`allowUnfree = true`** is set in `common.nix`. The `homeConfigurations` output also passes `config.allowUnfree = true` because some packages (e.g. `apple-cursor`) require it.
- **Inputs flow through `extraSpecialArgs`** — to use a flake input from inside `home/`, add `inputs` to the function args (`{ pkgs, config, inputs, ... }:`) and reference `inputs.<name>.packages.${pkgs.stdenv.hostPlatform.system}.default`.
- **Don't edit generated files**. `hardware-configuration.nix` is the only one — leave it alone.

## Common files when changing the desktop

- Hyprland WM config (keybinds, animations, exec-once, env): `home/hyprland.nix`.
- Hyprland NixOS module (xdg portals, polkit, dbus, programs.hyprland): `modules/hyprland.nix`.
- Top bar: `home/waybar.nix` — settings + GTK CSS in one file.
- Bottom dock (`nwg-dock-hyprland`): exec-once flags in `home/hyprland.nix`; CSS at `~/.config/nwg-dock-hyprland/style.css` (not yet declarative).
- App launcher (`rofi-freq`): script at `scripts/rofi-freq.sh`, theme at `rofi/launchers/type-2/style-1.rasi` (verbatim from adi1090x/rofi), palette at `rofi/colors/catppuccin.rasi`.

## SSH / sudo

- Public key for the `wesbragagt` user is pinned in `common.nix` at `users.users.wesbragagt.openssh.authorizedKeys.keys`.
- Passwordless sudo for `wheel` is set in `common.nix`.
- For git over SSH: `home/programs.nix` configures `programs.ssh.matchBlocks."github.com"` to use the Bitwarden SSH agent (`~/.bitwarden-ssh-agent.sock`), with the public key file at `~/.ssh/github_key.pub`.

## Live-applying changes without re-login

- Hyprland reload after editing `home/hyprland.nix`:
  `hyprctl reload`
- Restart waybar / dock after CSS or settings change:
  `pkill waybar && hyprctl dispatch exec waybar`
  `pkill nwg-dock && hyprctl dispatch exec "nwg-dock-hyprland ..."`
- Cursor theme switch:
  `hyprctl setcursor <theme> <size>` (the standard `hyprctl reload` does **not** re-init cursors).

## Out of band

- DHCP IP can change. The mac's `~/.ssh/config` host alias `nixos-hp` may need its `HostName` updated. Refresh `known_hosts` when the IP changes.
- The pre-flake `configuration.nix` is gone; everything imports through the flake.
