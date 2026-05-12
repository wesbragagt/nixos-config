#!/usr/bin/env bash
set -euo pipefail

bookmarks_file="$HOME/notes-live-sync/areas/bookmarks/bookmarks.md"

if [[ ! -f "$bookmarks_file" ]]; then
  notify-send "Bookmarks" "File not found: $bookmarks_file"
  exit 0
fi

entries="$(awk -F '|' '
  /^[[:space:]]*$/ { next }
  {
    url = $1
    label = $2
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", url)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", label)
    if (url ~ /^https?:\/\// && label != "") {
      print label "\t" url
    }
  }
' "$bookmarks_file")"

[[ -n "$entries" ]] || exit 0

selection="$(printf '%s\n' "$entries" | rofi -dmenu -i -p 'Bookmarks')"
[[ -n "$selection" ]] || exit 0

url="$(printf '%s\n' "$selection" | awk -F '\t' '{print $2}')"
[[ -n "$url" ]] || exit 0

exec xdg-open "$url"
