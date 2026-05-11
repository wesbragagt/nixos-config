---
title: Add another machine to this NixOS config
date: 2026-05-06
status: active
tags:
  - type/how-to
  - nix
  - nixos
  - multi-host
  - sops
---

# Add another machine to this NixOS config

This repo is already structured for multiple hosts. The main things to do are:

1. create a new `hosts/<hostname>/` entry
2. add the host to `flake.nix`
3. add the new machine's SSH host key as a SOPS recipient if it should decrypt shared secrets
4. build and switch that host

This guide assumes:
- the new machine will run NixOS
- you want it managed by this flake
- it should be able to decrypt `secrets/secrets.yaml`

## 1. Pick the new hostname

Example in this guide:

```bash
newhost="nixos-desktop"
```

Use your real hostname instead.

## 2. Create the host directory

From the repo root:

```bash
mkdir -p hosts/$newhost
```

## 3. Generate or copy the hardware config from the new machine

Do this on the new machine.

If the machine already has a generated hardware config, copy:

```bash
/etc/nixos/hardware-configuration.nix
```

into:

```bash
hosts/$newhost/hardware-configuration.nix
```

A convenient way from the repo root on the new machine is:

```bash
sudo nixos-generate-config --show-hardware-config > hosts/$newhost/hardware-configuration.nix
```

Do not hand-edit hardware detection details unless you know exactly why.

## 4. Create `hosts/$newhost/default.nix`

Copy the existing host as a starting point:

```bash
cp hosts/nixos-hp/default.nix hosts/$newhost/default.nix
```

Then edit:

```bash
nvim hosts/$newhost/default.nix
```

At minimum, change:

```nix
networking.hostName = "nixos-desktop";
```

For a desktop/non-laptop host, also remove laptop-only settings from the copied file, especially:

```nix
services.logind.settings.Login = {
  HandleLidSwitch = "suspend";
  HandleLidSwitchExternalPower = "suspend";
  HandleLidSwitchDocked = "ignore";
};
```

Adjust any host-specific boot, kernel, suspend, or hardware choices as needed.

## 5. Add the host to `flake.nix`

Add a sibling entry under `nixosConfigurations` using the shared `mkHost` helper.

For a desktop with no Wi-Fi UI and no battery/backlight/lid handling:

```nix
nixosConfigurations = {
  nixos-hp = mkHost { ... };

  nixos-desktop = mkHost {
    name = "nixos-desktop";
    hostProfile = {
      isLaptop = false;
      hasWireless = false;
      graphics = "generic"; # use "intel" only for Intel VA-API/iHD hosts
    };
  };
};
```

The profile controls shared laptop/desktop behavior:

- `isLaptop = true` enables battery Waybar config, `battery-estimate`, brightness keys, and laptop Hyprland config.
- `hasWireless = true` installs Wi-Fi tray/UI helpers and launches `nm-applet` from the laptop Hyprland config.
- `graphics = "intel"` enables Intel VA-API packages and `LIBVA_DRIVER_NAME=iHD`; leave desktops as `"generic"` unless you know they need Intel-specific acceleration.

## 6. Add this machine as a SOPS recipient

For this repo's NixOS hosts, treat this as required. The shared config declares `exa_api_key` as a system-side `sops-nix` secret and Home Manager reads it from `/run/secrets/exa_api_key`, so the new machine's host SSH key must be able to decrypt `secrets/secrets.yaml` for unattended rebuilds.

You can still use the YubiKey to edit/re-wrap secrets during setup, but the host recipient is what makes future `nixos-rebuild switch` work without depending on the YubiKey being present.

## 7. Get the new machine's host recipient

On an already-running NixOS machine, run:

```bash
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

During a fresh ISO install, pre-generate the target host key before `nixos-install` so the recipient is known before the first activation tries to decrypt secrets:

```bash
sudo install -d -m 0755 /mnt/etc/ssh
sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
nix-shell -p ssh-to-age --run 'ssh-to-age < /mnt/etc/ssh/ssh_host_ed25519_key.pub'
```

Copy the resulting `age1...` recipient.

This recipient is for the machine itself, so `sops-nix` can decrypt secrets automatically during activation/runtime.

## 8. Add the new host recipient to `.sops.yaml`

Edit:

```bash
nvim .sops.yaml
```

Add a new key anchor for the host, then include it in the shared secrets rule.

Example:

```yaml
keys:
  - &nixos_hp age1...
  - &nixos_desktop age1...
  - &wes_yk1 age1yubikey1...

creation_rules:
  - path_regex: ^secrets/secrets\.yaml$
    age:
      - *nixos_hp
      - *nixos_desktop
      - *wes_yk1
```

If you have more YubiKeys or backup keys, keep them in the same rule.

## 9. Re-wrap existing secrets

After changing recipients, re-wrap the encrypted files:

```bash
sops-updatekeys-all
```

That updates `secrets/secrets.yaml` so the new host can decrypt it.

## 10. Validate the config

From the repo root:

```bash
git add -A
sudo nixos-rebuild build --flake .#$newhost
nix build .#homeConfigurations.wesbragagt.activationPackage
```

Or use the repo helper:

```bash
./scripts/validate-config.sh --host $newhost
```

If it fails, look at the last `error:` line first.

## 11. Switch the new machine

On the new machine:

```bash
sudo nixos-rebuild switch --flake .#$newhost
```

## 12. Verify host-side secret decryption

To test that the machine can decrypt with its host key:

```bash
sudo SOPS_AGE_SSH_PRIVATE_KEY_FILE=/etc/ssh/ssh_host_ed25519_key sops -d secrets/secrets.yaml
```

That checks the host recipient path directly.

## 13. Commit the host addition

This repo is GitOps-oriented, so commit the host addition after validation:

```bash
git add -A
git commit -m "Add $newhost host"
```

## Files you will usually touch

- `hosts/$newhost/hardware-configuration.nix`
- `hosts/$newhost/default.nix`
- `flake.nix`
- `.sops.yaml` if the machine should decrypt secrets
- `secrets/secrets.yaml` after `sops-updatekeys-all`

## Common pitfalls

### The host builds, but secrets do not decrypt

Usually one of these:
- the new host recipient was not added to `.sops.yaml`
- `sops-updatekeys-all` was not run after editing recipients
- you copied the wrong host public key
- the machine is not using `/etc/ssh/ssh_host_ed25519_key`

Check the configured identity path in `modules/sops.nix`:

```nix
sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
```

### I only want Home Manager on a non-NixOS machine

This repo also exposes:

```bash
nix run home-manager/master -- switch --flake .#wesbragagt
```

That is for standalone Home Manager and is separate from adding a new NixOS host.

### I need another YubiKey too

See:
- `docs/sops-yubikey.md`
- `secrets/README.md`

Those cover YubiKey enrollment, recipient updates, and re-wrapping secrets.
