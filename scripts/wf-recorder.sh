#!/bin/env bash

stateFile="$HOME/.cache/wf-recorder-last-file"

if pgrep -x wf-recorder >/dev/null; then
  pkill -INT -x wf-recorder
  while pgrep -x wf-recorder >/dev/null; do
    sleep 0.2
  done
  notify-send -h string:wf-recorder:record -t 1000 'Finished Recording'
  if [ -f "$stateFile" ]; then
    mpv "$(cat "$stateFile")" >/dev/null 2>&1 &
    disown
  fi
  exit 0
fi

notify-send -h string:wf-recorder:record -t 1000 'Recording in:' "<span color='#90a4f4' font='26px'><i><b>3</b></i></span>"
sleep 1
notify-send -h string:wf-recorder:record -t 1000 'Recording in:' "<span color='#90a4f4' font='26px'><i><b>2</b></i></span>"
sleep 1
notify-send -h string:wf-recorder:record -t 950 'Recording in:' "<span color='#90a4f4' font='26px'><i><b>1</b></i></span>"
sleep 1
if [ "$1" = "region" ]; then
  geometry=$(slurp) || exit 1
  dateTime=$(date +%m-%d-%Y-%H:%M:%S)
  outFile="$HOME/Videos/$dateTime.mp4"
  echo "$outFile" > "$stateFile"
  wf-recorder --bframes max_b_frames -a -g "$geometry" -p color_range=pc -p colorspace=bt709 -p color_primaries=bt709 -p color_trc=bt709 -f "$outFile"
else
  dateTime=$(date +%m-%d-%Y-%H:%M:%S)
  outFile="$HOME/Videos/$dateTime.mp4"
  echo "$outFile" > "$stateFile"
  wf-recorder --bframes max_b_frames -a -p color_range=pc -p colorspace=bt709 -p color_primaries=bt709 -p color_trc=bt709 -f "$outFile"
fi
