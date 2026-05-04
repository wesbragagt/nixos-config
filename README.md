# nixos-config

NixOS + home-manager flake. Per-host system configs under `hosts/`, shared base in `common.nix`, user/dotfiles in `home/`.

## Quick start: new NixOS system

From the live ISO, after disks are partitioned, formatted, and mounted at `/mnt`:

```bash
# 1. Network
sudo systemctl start NetworkManager   # or `wpa_supplicant` / `iwctl` for wifi

# 2. Generate hardware config for THIS machine
sudo nixos-generate-config --root /mnt

# 3. Pull this repo
nix-shell -p git --run 'git clone https://github.com/wesbragagt/nixos-config /mnt/etc/nixos'

# 4. Carve out a host directory and move the generated hardware file in
HOST=<newhost>
sudo mkdir -p /mnt/etc/nixos/hosts/$HOST
sudo mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hosts/$HOST/

# 5. Create the host's default.nix (copy nixos-hp's, change hostName)
sudo cp /mnt/etc/nixos/hosts/nixos-hp/default.nix /mnt/etc/nixos/hosts/$HOST/default.nix
sudo sed -i "s/nixos-hp/$HOST/" /mnt/etc/nixos/hosts/$HOST/default.nix

# 6. Register the host in flake.nix (add a sibling to nixosConfigurations.nixos-hp)
#    nixosConfigurations.$HOST = nixpkgs.lib.nixosSystem { ... modules = [ ./hosts/$HOST ... ]; };

# 7. Install
sudo nixos-install --flake /mnt/etc/nixos#$HOST --root /mnt

# 8. Reboot, log in, then on the running system:
git clone https://github.com/wesbragagt/nixos-config ~/nixos-config
sudo nixos-rebuild switch --flake ~/nixos-config#$HOST
```

After the first switch, `home-manager` activates automatically (it's wired in as a NixOS module). Add your SSH public key to `users.users.<you>.openssh.authorizedKeys.keys` in `common.nix` (or per-host) before the next push so passwordless SSH from your other machines works.

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
