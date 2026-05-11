# Secrets

This repo uses `sops-nix` with `age` recipients.

## Layout

- `.sops.yaml` — recipient list and creation rules
- `secrets/secrets.yaml` — optional repo-shared secrets file used by both NixOS and Home Manager

If that file does not exist, the config still evaluates.

## Installed support

- `modules/sops.nix`
  - enables `services.pcscd`
  - imports host SSH keys as age identities via `sops.age.sshKeyPaths`
  - enables `age-plugin-yubikey` for `sops-nix`
  - exposes `exa_api_key` at `/run/secrets/exa_api_key` for NixOS hosts, owned by `wesbragagt`
- `home/sops/default.nix`
  - installs `age`, `ssh-to-age`, `age-plugin-yubikey`, `yubikey-manager`
  - installs `sops` wrapped with the YubiKey age plugin
  - points home-manager `sops` at `~/.config/sops/age/keys.txt`

## Recommended recipients

Because this repo uses a single shared GitOps secrets file, include every recipient that should be able to decrypt it:

- every NixOS host recipient for unattended machine decryption and rebuilds
- one or more YubiKey recipients for admin access
- optional software age backup recipient

## Get recipients

### Host recipient

```bash
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

### Software age backup recipient

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/backup.txt
age-keygen -y ~/.config/sops/age/backup.txt
cat ~/.config/sops/age/backup.txt >> ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/backup.txt ~/.config/sops/age/keys.txt
```

### YubiKey recipient(s)

```bash
age-plugin-yubikey
age-plugin-yubikey --list
```

`age-plugin-yubikey` creates an identity file locally and stores the private key
material on the YubiKey. Append the generated identity file(s) to
`~/.config/sops/age/keys.txt` so local `sops` commands can use them.

## Configure `.sops.yaml`

Add all recipients that should be able to decrypt the shared GitOps file.

```yaml
keys:
  - &nixos_hp age1...
  - &wes_yk1 age1yubikey1...
  - &wes_yk2 age1yubikey1...
  - &backup age1...

creation_rules:
  - path_regex: ^secrets/secrets\.yaml$
    age:
      - *nixos_hp
      - *wes_yk1
      - *wes_yk2
      - *backup
```

## Create the shared secrets file

```bash
mkdir -p secrets
sops secrets/secrets.yaml
```

Example contents:

```yaml
example-token: replace-me
```

## Consume a secret in NixOS

`modules/sops.nix` and `home/sops/default.nix` both set
`defaultSopsFile` automatically when `secrets/secrets.yaml` exists. Declare
secrets near the consuming service/module, for example:

```nix
{
  sops.secrets.example-token = { };

  systemd.services.example = {
    serviceConfig.EnvironmentFile = config.sops.secrets.example-token.path;
  };
}
```

## Add another YubiKey or age key later

1. Add its public recipient to `.sops.yaml`
2. Re-wrap existing encrypted files:

```bash
sops-updatekeys-all
```

Equivalent one-off command:

```bash
find secrets -type f -name '*.yaml' -exec sops updatekeys -y {} \;
```

Any listed recipient can decrypt after `updatekeys` completes.
