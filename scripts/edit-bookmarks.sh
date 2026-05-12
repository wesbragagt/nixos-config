#!/usr/bin/env bash
set -euo pipefail

bookmarks_dir="$HOME/notes-live-sync/areas/bookmarks"
bookmarks_file="$bookmarks_dir/bookmarks.md"

if [[ ! -d "$bookmarks_dir" ]]; then
  notify-send "Bookmarks" "Directory not found: $bookmarks_dir"
  exit 0
fi

exec foot --app-id bookmark-editor -e nvim "$bookmarks_file"
