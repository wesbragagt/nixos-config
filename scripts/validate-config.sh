#!/usr/bin/env bash
set -euo pipefail

host="${NIXOS_HOST:-nixos-hp}"
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

Stages flake-visible changes, builds the NixOS host config, and builds the
standalone Home Manager config. Pass --switch for final activation.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

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
