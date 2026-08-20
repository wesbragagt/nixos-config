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

## Local HTTPS reverse proxy

`icebox` runs Caddy as the shared local reverse-proxy service.
The better-ccflare route is:

```text
https://ccflare.localhost  →  127.0.0.1:35550
```

Use these client endpoints:

```text
Dashboard: https://ccflare.localhost/
Health:    https://ccflare.localhost/health
API base:  https://ccflare.localhost/v1
```

Caddy uses `tls internal` for local HTTPS.
Trust Caddy's local root certificate to remove browser warnings.
Use `curl --insecure` only for local testing before installing that certificate.

Test the route:

```bash
curl --insecure --fail https://ccflare.localhost/health
```

An HTTP `503` response with `accounts: 0` means Caddy reached better-ccflare,
but no provider accounts are configured yet.

## Account pool

Configure provider accounts from:

```text
https://ccflare.localhost/accounts
```

Account credentials are stored in `/var/lib/better-ccflare`.
Do not add provider tokens or OAuth data to this repository.

ccflare selects the highest-priority active account that supports the request.
Pause personal accounts if they must not receive routed requests.
Set a work or shared account to the highest priority.

Use the Accounts page to:

- Add or re-authenticate an OAuth account.
- Set account priority.
- Pause or resume an account.
- Configure provider model mappings.
- Refresh provider usage data.

## OMP routing

OMP uses the ccflare Anthropic Messages API.
The configuration is in `home/omp/config/models.yml`.
Home Manager links it to `~/.omp/agent/models.yml`.

The current provider definition is:

```yaml
providers:
  ccflare:
    baseUrl: http://127.0.0.1:35550
    apiKey: ccflare-local
    api: anthropic-messages
```

The trailing `/v1` is not included here.
OMP adds the Anthropic Messages API path.

OMP only shows model IDs listed in `models.yml`.
The active Codex OAuth account cannot provide a model catalog.
Keep the model list explicit and test each new model before adding it.

The configured model IDs are:

- `claude-opus-4-8`
- `claude-sonnet-5`
- `claude-haiku-4-5`
- `gpt-5.6-luna`
- `gpt-5.6-terra`
- `gpt-5.6-sol`

Check the configured OMP models:

```bash
omp models ccflare --json
```

Test the default OMP route:

```bash
omp --print --no-session "Reply with exactly: ccflare verified"
```

The OMP `usage` status segment does not report ccflare usage.
It reports local OMP provider credentials.
Do not enable it when ccflare is the active route.

## Adding local services

Keep local services behind the same Caddy instance.
Add another virtual host to `modules/caddy.nix`:

```nix
services.caddy.virtualHosts = {
  "https://ccflare.localhost".extraConfig = ''
    tls internal
    reverse_proxy 127.0.0.1:35550
  '';

  "https://grafana.localhost".extraConfig = ''
    tls internal
    reverse_proxy 127.0.0.1:3000
  '';
};
```

Each service must use a unique `.localhost` hostname and an unused local upstream port.
Do not expose the upstream port publicly.
Apply route changes with `rebuild build` followed by `rebuild`.
