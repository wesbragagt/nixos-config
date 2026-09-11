#!/usr/bin/env bash
set -euo pipefail

inside_popup=false

if [ "${1:-}" = "--inside-popup" ]; then
  inside_popup=true
  shift
fi

if [ "$#" -ne 1 ]; then
  printf 'Usage: glow-review FILE_OR_DIRECTORY\n' >&2
  exit 64
fi

if [ ! -r "$1" ]; then
  printf 'glow-review: cannot read %s\n' "$1" >&2
  exit 66
fi

source="$(realpath -- "$1")"

if [ -f "$source" ] && [ "${source##*.}" != "md" ] && [ "${source##*.}" != "markdown" ] && [ "${source##*.}" != "mdown" ] && [ "${source##*.}" != "mkdn" ] && [ "${source##*.}" != "mkd" ]; then
  printf 'glow-review: expected a Markdown file or directory: %s\n' "$1" >&2
  exit 65
fi

if "$inside_popup"; then
  # Glow 2.1.1 renders a file before its TUI has a terminal width. Reloading
  # after its first size event applies its configured word-wrap width.
  (sleep 1; printf 'r' > /dev/tty) &
  exec glow --tui --width 100 "$source"
fi

printf -v quoted_file '%q' "$source"
printf -v quoted_script '%q' "$(realpath -- "$0")"

if [ -n "${TMUX:-}" ]; then
  tmux display-popup -E -w 112 -h 90% -T "Markdown review" -d "$(dirname -- "$source")" "exec $quoted_script --inside-popup $quoted_file"
else
  (sleep 1; printf 'r' > /dev/tty) &
  exec glow --tui --width 100 "$source"
fi
