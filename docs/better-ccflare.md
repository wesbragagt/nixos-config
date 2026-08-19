# Machine feature toggles

Machine-local feature flags live at `/etc/nixos/features.yaml`.
The file is not stored in this repository. A repository copy such as `config/features.yaml` is gitignored.

Missing files disable optional features by default.
This allows server bootstrapping without desktop or user-tool modules.

Example:

```yaml
features:
  better-ccflare: true
  claude-code: true
  omp: true
```

Feature names are parsed from lines with this form:

```yaml
  feature-name: true
```

Set a feature to `false`, or remove the line, to disable it.

## Available features

- `better-ccflare` enables the Podman service on `icebox`.
- `claude-code` enables the Claude Code Home Manager module.
- `omp` enables the Open Model Platform (OMP) Home Manager module.

The default for all listed features is disabled.
Host-specific profile settings still control hardware, desktop, and secret behavior.

Apply changes with:

```bash
rebuild build
rebuild
```

## better-ccflare

When enabled, better-ccflare uses Podman and listens at:

```text
Dashboard: http://127.0.0.1:35550/
Health:    http://127.0.0.1:35550/health
API base:  http://127.0.0.1:35550/v1
```

The service persists `/var/lib/better-ccflare:/data`.
The host directory uses `root:root` ownership and mode `0700`.
