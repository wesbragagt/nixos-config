#!/usr/bin/env bash

# pipes fzf selection to open vim on selected file
set -e

files_excluded=(
  node_modules
  .git
  .obsidian
  .terragrunt-cache
  .terraform
  .venv
  .direnv
  dist
)

EXCLUDES=`echo ${files_excluded[@]} | xargs -n1 | awk '{print "--exclude=" $1}' | xargs`
FZF_DEFAULT_COMMAND="fd --type=file --hidden --follow ${EXCLUDES}"
FZF_DEFAULT_OPTS="-m --bind ctrl-t:toggle-all --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'"

if [[ $# -eq 1 ]]; then
    selected=$1
else
    if command -v bat &> /dev/null; then
      selected=`fzf -m --preview 'bat --style=numbers --color=always --line-range :500 {}'`
    else
      selected=`fzf`
    fi
fi

if [[ -n "$selected" ]]; then
    nvim "$selected"
fi
