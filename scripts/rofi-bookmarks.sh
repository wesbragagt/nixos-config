#!/usr/bin/env bash
set -euo pipefail

bookmarks_json="${XDG_CONFIG_HOME:-$HOME/.config}/zen/bookmarks.json"

if [[ ! -f "$bookmarks_json" ]]; then
  echo "Bookmarks file not found: $bookmarks_json" >&2
  exit 1
fi

entries="$(${JQ:-jq} -r '
  def flatten($path):
    .[] |
    if (.url? != null) then
      [($path + [.name] | join(" / ")), .url] | @tsv
    else
      (.bookmarks // []) | flatten($path + [.name])
    end;
  flatten([])
' "$bookmarks_json")"

[[ -n "$entries" ]] || exit 0

selection="$(printf '%s\n' "$entries" | rofi -dmenu -i -p 'Bookmarks')"
[[ -n "$selection" ]] || exit 0

url="$(printf '%s\n' "$selection" | awk -F '\t' '{print $2}')"
[[ -n "$url" ]] || exit 1

exec zen-beta "$url"
