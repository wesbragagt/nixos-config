# nixos-config

NixOS + home-manager flake. Per-host system configs under `hosts/`, shared base in `common.nix`, user/dotfiles in `home/`.

## Layout

```
flake.nix                  # nixosConfigurations + homeConfigurations
common.nix                 # shared NixOS base (user, locale, packages, services)
modules/                   # NixOS system modules (graphics, audio, hyprland, ...)
home/                      # home-manager (wesbragagt.nix entry, programs, hyprland, waybar)
hosts/
  nixos-hp/
    default.nix            # host-specific (hostname, boot, hardware import)
    hardware-configuration.nix
rofi/                      # rasi themes wired via xdg.configFile
scripts/                   # rofi-freq frequency-sorted launcher
```

## Bootstrap a new NixOS machine

From the live ISO, after partitioning and mounting to `/mnt`:

```bash
sudo nixos-generate-config --root /mnt
nix-shell -p git
git clone https://github.com/wesbragagt/nixos-config /mnt/etc/nixos
mkdir -p /mnt/etc/nixos/hosts/<newhost>
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hosts/<newhost>/
# Copy hosts/nixos-hp/default.nix -> hosts/<newhost>/default.nix and adjust hostName
# Add nixosConfigurations.<newhost> to flake.nix mirroring nixos-hp
sudo nixos-install --flake /mnt/etc/nixos#<newhost>
```

After install, on the running system:
```bash
sudo nixos-rebuild switch --flake ~/nixos-config#<newhost>
```

## Apply on an existing NixOS box

```bash
cd ~/nixos-config
git add -A   # flake reads from the git tree; untracked files are invisible
sudo nixos-rebuild switch --flake .#nixos-hp
```

## Use on non-NixOS Linux (home-manager standalone)

CLI/dotfile parts of `home/` work on Ubuntu/Arch/etc. System-level pieces (Hyprland, waybar, Thunar) require NixOS.

```bash
nix run home-manager/master -- switch --flake github:wesbragagt/nixos-config#wesbragagt
```

## Per-host SSH

The mac uses `~/.ssh/config`:
```
Host nixos-hp
  HostName <ip>
  User wesbragagt
  IdentityFile ~/.ssh/nixos-hp.key
```
Private key lives in the Bitwarden SSH agent; the matching public key is pinned declaratively in `common.nix` via `users.users.wesbragagt.openssh.authorizedKeys.keys`.

Passwordless sudo for `wheel` is set in `common.nix`.

## Secrets

None committed. When needed, add `agenix` (simple) or `sops-nix` (multi-recipient).
