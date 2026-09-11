#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -gt 0 ]; then
  exec glow-review "$@"
fi

mapfile -t selected < <(
  fd \
    --type file \
    --extension md \
    --extension markdown \
    --extension mdown \
    --extension mkdn \
    --extension mkd \
    --hidden \
    --follow \
    --exclude .git \
    --exclude .obsidian \
    --exclude .direnv \
    --exclude .venv \
    --exclude node_modules \
    --exclude dist \
    --exclude .terraform \
    --exclude .terragrunt-cache \
  | fzf --multi --preview 'glow --width 100 {}' --preview-window 'right,60%,wrap'
) || exit 0

[ "${#selected[@]}" -gt 0 ] || exit 0

review_dir="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/markdown-review.XXXXXX")"
trap 'rm -rf "$review_dir"' EXIT

for file in "${selected[@]}"; do
  target="$review_dir/$file"
  mkdir -p "$(dirname -- "$target")"
  ln -s "$(realpath -- "$file")" "$target"
done

glow-review "$review_dir"
