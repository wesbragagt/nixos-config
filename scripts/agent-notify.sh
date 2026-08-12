#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_RUNTIME_DIR:-/tmp}/agent-notify"
state_file="$state_dir/latest.env"

focus_target() {
  local target_session="${1:-no-tmux}"
  local target_window="${2:-no-window}"
  local target_pane="${3:-}"
  local target_terminal_address="${4:-}"

  if command -v hyprctl >/dev/null 2>&1; then
    if [ -n "$target_terminal_address" ]; then
      hyprctl dispatch focuswindow "address:${target_terminal_address}" >/dev/null 2>&1 || true
    else
      hyprctl dispatch focuswindow "class:^(foot)$" >/dev/null 2>&1 || true
    fi
  fi

  if [ "$target_session" != "no-tmux" ] && [ "$target_window" != "no-window" ] && command -v tmux >/dev/null 2>&1; then
    tmux switch-client -t "${target_session}:${target_window}" >/dev/null 2>&1 || true
    if [ -n "$target_pane" ]; then
      tmux select-pane -t "$target_pane" >/dev/null 2>&1 || true
    fi
  fi
}

if [ "${1:-}" = "--open-latest" ]; then
  if [ ! -f "$state_file" ]; then
    notify-send --app-name="Agent" "🤖 No agent target" "No notification target is stored yet." || true
    exit 0
  fi

  # shellcheck disable=SC1090
  source "$state_file"
  focus_target "${session:-no-tmux}" "${window:-no-window}" "${pane:-}" "${terminal_address:-}"
  exit 0
fi

status="${1:-Done}"
message="${2:-Task finished.}"

session="${AGENT_NOTIFY_TMUX_SESSION:-}"
window="${AGENT_NOTIFY_TMUX_WINDOW:-}"
pane="${AGENT_NOTIFY_TMUX_PANE:-${TMUX_PANE:-}}"
terminal_address="${AGENT_NOTIFY_TERMINAL_ADDRESS:-}"

if [ -z "$session" ] && [ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1; then
  session="$(tmux display-message -p '#S' 2>/dev/null || true)"
fi

if [ -z "$window" ] && [ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1; then
  window="$(tmux display-message -p '#W' 2>/dev/null || true)"
fi

if [ -z "$terminal_address" ] && command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  terminal_address="$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty' 2>/dev/null || true)"
fi

session="${session:-no-tmux}"
window="${window:-no-window}"

mkdir -p "$state_dir"
{
  printf 'session=%q\n' "$session"
  printf 'window=%q\n' "$window"
  printf 'pane=%q\n' "$pane"
  printf 'terminal_address=%q\n' "$terminal_address"
} > "$state_file"

action="$(notify-send \
  --app-name="Agent" \
  --action="open=Open terminal" \
  "🤖 ${status}: ${session}:${window}" \
  "$message" || true)"

if [ "$action" = "open" ]; then
  focus_target "$session" "$window" "$pane" "$terminal_address"
fi
