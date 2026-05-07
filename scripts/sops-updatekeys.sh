#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sops-updatekeys-all [repo-root]

Re-wrap every YAML secret under secrets/ using the current recipients from
.sops.yaml. If no repo root is provided, the script first looks upward from the
current directory for a repo containing .sops.yaml and secrets/, then falls back
to ~/nixos-config.
EOF
}

find_repo_root() {
  local dir="$PWD"

  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.sops.yaml" && -d "$dir/secrets" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi

    dir="$(dirname "$dir")"
  done

  return 1
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 1
fi

repo_root="${1:-}"

if [[ -z "$repo_root" ]]; then
  repo_root="$(find_repo_root || true)"
fi

repo_root="${repo_root:-$HOME/nixos-config}"
repo_root="$(cd "$repo_root" && pwd)"
secrets_dir="$repo_root/secrets"

if [[ ! -f "$repo_root/.sops.yaml" ]]; then
  echo "Missing .sops.yaml in repo root: $repo_root" >&2
  exit 1
fi

if [[ ! -d "$secrets_dir" ]]; then
  echo "Missing secrets directory: $secrets_dir" >&2
  exit 1
fi

cd "$repo_root"

count=0
while IFS= read -r -d '' file; do
  rel_path="${file#"$repo_root/"}"
  echo ">>> Updating recipients for $rel_path"
  sops updatekeys -y "$rel_path"
  count=$((count + 1))
done < <(find "$secrets_dir" -type f -name '*.yaml' -print0 | sort -z)

if [[ "$count" -eq 0 ]]; then
  echo ">>> No YAML secret files found under $secrets_dir"
  exit 0
fi

echo ">>> Updated recipients for $count file(s)"
