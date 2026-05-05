#!/usr/bin/env bash

# live-grep via ripgrep + fzf, opens nvim at the matched line
set -e

RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case"

selected=$(
  FZF_DEFAULT_COMMAND="$RG_PREFIX ''" \
  fzf --ansi \
      --disabled \
      --bind "change:reload:$RG_PREFIX {q} || true" \
      --bind 'ctrl-t:toggle-all' \
      --delimiter ':' \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
)

if [[ -n "$selected" ]]; then
  file=$(echo "$selected" | cut -d: -f1)
  line=$(echo "$selected" | cut -d: -f2)
  nvim "+${line}" "$file"
fi
