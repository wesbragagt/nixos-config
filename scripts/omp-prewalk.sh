#!/usr/bin/env bash
# Start OMP with Opus 4.8 for planning and a fuzzy-selected model for implementation.
set -euo pipefail

planner_model="ccflare/claude-opus-4-8"

if ! command -v omp >/dev/null 2>&1; then
  echo "omp is not available" >&2
  exit 127
fi

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf is not available" >&2
  exit 127
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not available" >&2
  exit 127
fi

models="$(omp models --json)"

selection="$(
  jq -r --arg planner "$planner_model" '
    .models[]
    | select(.selector != $planner)
    | [
        .selector,
        ((.contextWindow / 1000 | floor | tostring) + "K context"),
        ((.maxTokens / 1000 | floor | tostring) + "K output"),
        ("$" + (.cost.input | tostring) + "/$" + (.cost.output | tostring) + " per MTok")
      ]
    | @tsv
  ' <<<"$models" \
    | fzf \
      --height=40% \
      --layout=reverse \
      --border \
      --prompt="Prewalk into: " \
      --header="Plan: ${planner_model}  •  Select implementation model" \
      --with-nth=1,2,3,4 \
      --delimiter=$'\t'
)" || exit 0

target_model="${selection%%$'\t'*}"

exec omp \
  --model "$planner_model" \
  --prewalk \
  --prewalk-into "$target_model" \
  "$@"
