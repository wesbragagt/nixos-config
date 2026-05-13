#!/usr/bin/env bash
set -euo pipefail

host="${NIXOS_HOST:-}"
do_switch=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      host="$2"
      shift 2
      ;;
    --switch)
      do_switch=1
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/validate-config.sh [--host <name>] [--switch]

Stages flake-visible changes, builds the explicitly selected NixOS host config,
and builds the standalone Home Manager config. Pass --switch for final
activation. If no host is provided, the script asks interactively.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$host" ]]; then
  if [[ ! -t 0 ]]; then
    echo "Error: no host selected. Pass --host <name> or set NIXOS_HOST." >&2
    echo "Refusing to guess a NixOS host because activating the wrong host can be destructive." >&2
    exit 1
  fi

  current_host="$(hostname 2>/dev/null || true)"
  if [[ -n "$current_host" ]]; then
    read -r -p "No NixOS host selected. Enter host to build/switch [${current_host}]: " host
    host="${host:-$current_host}"
  else
    read -r -p "No NixOS host selected. Enter host to build/switch: " host
  fi

  if [[ -z "$host" ]]; then
    echo "Error: no host selected; aborting." >&2
    exit 1
  fi
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo ">>> Staging flake-visible changes"
git add -A

echo ">>> Building NixOS configuration for $host"
sudo nixos-rebuild build --flake ".#$host"

echo ">>> Building standalone Home Manager configuration"
nix build .#homeConfigurations.wesbragagt.activationPackage

if [[ "$do_switch" -eq 1 ]]; then
  echo ">>> Switching NixOS configuration for $host"
  sudo nixos-rebuild switch --flake ".#$host"
fi

echo ">>> Validation complete"
