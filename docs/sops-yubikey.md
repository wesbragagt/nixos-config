---
title: Add a YubiKey as a SOPS age Recipient
date: 2026-05-06
status: active
tags:
  - type/how-to
  - nix
  - nixos
  - sops
  - yubikey
---

# Add a YubiKey as a SOPS age Recipient

This repo uses `sops-nix` with optional secrets files, so builds still work when no secrets exist yet.

## Prerequisites

Apply the current config so the tools are installed:

```bash
sudo nixos-rebuild switch --flake .#nixos-hp
```

## 1. Create the YubiKey age identity

```bash
age-plugin-yubikey
```

Follow the prompts. This stores the secret material on the YubiKey and creates a local identity file. Home Manager creates `~/.config/sops/age/keys.txt` automatically on activation.

## 2. Add the identity to `keys.txt`

Append the generated identity file to the SOPS age identities file:

```bash
cat age-yubikey-identity-*.txt >> ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

## 3. Get the public recipient

```bash
age-plugin-yubikey --list
```

Copy the `age1yubikey...` value.

## 4. Add it to `.sops.yaml`

Example:

```yaml
keys:
  - &nixos_hp age1...
  - &wes_yk1 age1yubikey1...

creation_rules:
  - path_regex: ^secrets/secrets\.yaml$
    age:
      - *nixos_hp
      - *wes_yk1
```

Recommended pattern for the shared GitOps file:
- keep the **host recipient** for unattended system decryption
- add one or more **YubiKey recipients** for admin access
- optionally add a **backup software age key**

Get the host recipient with:

```bash
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

## 5. Create or update secrets

Create the shared secret file:

```bash
mkdir -p secrets
sops secrets/secrets.yaml
```

If secrets already exist, re-wrap them after changing recipients:

```bash
sops-updatekeys-all
```

Equivalent one-off command:

```bash
find secrets -type f -name '*.yaml' -exec sops updatekeys -y {} \;
```

## 6. Test decryption

```bash
sops -d secrets/secrets.yaml
```

## FAQ

### What is the host SSH recipient for?

The host SSH recipient lets the machine decrypt `secrets/secrets.yaml` automatically via `sops-nix`. It is for unattended system-side decryption during activation/runtime, not mainly for convenient user-shell `sops` usage.

Get it with:

```bash
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

### Why does `sops -d secrets/secrets.yaml` still need the YubiKey inserted?

Manual CLI use in your normal user shell typically decrypts via the YubiKey recipient. The host recipient is mainly consumed by NixOS/`sops-nix`. So local `sops` commands usually still need the YubiKey present unless you add a software age key too.

### How does local `sops` find my YubiKey identity?

The local identity stub lives in:

```bash
~/.config/sops/age/keys.txt
```

Home Manager creates that file automatically and exports:

```bash
SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt
```

when the file exists.

### Will I be asked for a PIN or touch every time?

Often yes for manual `sops` commands. The exact behavior depends on the PIN and touch policy on the YubiKey identity.

- `pin-policy once` asks for the PIN once per session
- `pin-policy never` removes the PIN requirement
- `touch-policy always` requires a touch every decrypt
- `touch-policy cached` briefly caches touch approval

### Can I make the YubiKey touch-only with no PIN?

Yes. Generate a new YubiKey identity and migrate recipients:

```bash
age-plugin-yubikey --generate --pin-policy never --touch-policy always
```

Then:
1. append the new `age-yubikey-identity-*.txt` to `~/.config/sops/age/keys.txt`
2. replace the old `age1yubikey...` recipient in `.sops.yaml`
3. run `sops-updatekeys-all`

### Can I make local `sops` work without the YubiKey inserted?

Yes, by adding a software age key as another recipient. That is more convenient, but weaker than requiring the hardware key for admin access.

Create one with:

```bash
age-keygen -o ~/.config/sops/age/backup.txt
cat ~/.config/sops/age/backup.txt >> ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/backup.txt ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/backup.txt
```

Then add the resulting public recipient to `.sops.yaml` and run:

```bash
sops-updatekeys-all
```

## YubiKey command cheat sheet

### Inspect connected YubiKey age recipients

```bash
age-plugin-yubikey --list
```

### Create a default YubiKey age identity

```bash
age-plugin-yubikey
```

### Create a touch-only identity with no PIN

```bash
age-plugin-yubikey --generate --pin-policy never --touch-policy always
```

### Create a touch-cached identity with no PIN

```bash
age-plugin-yubikey --generate --pin-policy never --touch-policy cached
```

### Add the generated identity stub to local SOPS identities

```bash
cat age-yubikey-identity-*.txt >> ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

### Add another YubiKey to this repo

1. plug in the new YubiKey
2. generate/configure it with `age-plugin-yubikey`
3. append its `age-yubikey-identity-*.txt` to `~/.config/sops/age/keys.txt`
4. run `age-plugin-yubikey --list` and copy the new `age1yubikey...` recipient
5. add that recipient to `.sops.yaml`
6. re-wrap secrets:

```bash
sops-updatekeys-all
```

### If the PIV applet needs to be reset

```bash
ykman piv reset
```

### If `age-plugin-yubikey` complains about the management key format

```bash
ykman piv access change-management-key -a TDES --protect
```

## Add more YubiKeys later

Repeat the same process for each new key:
1. generate/configure with `age-plugin-yubikey`
2. append its identity file to `~/.config/sops/age/keys.txt`
3. add its `age1yubikey...` recipient to `.sops.yaml`
4. run `sops-updatekeys-all` on existing secrets
