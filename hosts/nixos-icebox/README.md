# nixos-icebox

Starter desktop host based on `nixos-hp`, using the same `wesbragagt` user and shared base config, but without laptop-only/wireless profile features.

Before installing or building this host, generate the machine-specific hardware config on nixos-icebox:

```bash
sudo nixos-generate-config --show-hardware-config > hosts/nixos-icebox/hardware-configuration.nix
```

Do not copy `hosts/nixos-hp/hardware-configuration.nix`; it contains HP-specific disk UUIDs and CPU modules.

For secrets, add this host's SSH age recipient to `.sops.yaml` and re-wrap secrets:

```bash
nix-shell -p ssh-to-age --run 'ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub'
sops-updatekeys-all
```
