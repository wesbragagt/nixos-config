#!/usr/bin/env bash

BAT=/sys/class/power_supply/BAT0
STATE=/tmp/battery-estimate.state

read_bat() {
  local name=$1
  [[ -f "$BAT/$name" ]] && cat "$BAT/$name"
}

status=$(read_bat status)
charge_now=$(read_bat charge_now)
charge_full=$(read_bat charge_full)
capacity=$(read_bat capacity)
now=$(date +%s)

format_time() {
  local seconds=$1
  local h=$(( seconds / 3600 ))
  local m=$(( (seconds % 3600) / 60 ))
  (( h > 0 )) && printf '%sh %sm' "$h" "$m" || printf '%sm' "$m"
}

icon_for_capacity() {
  local pct=$1
  if (( pct <= 15 )); then
    printf '🪫'
  else
    printf '🔋'
  fi
}

rate_calc() {
  awk -v d="$1" -v e="$2" 'BEGIN { if (e > 0) printf "%.8f", d / e }'
}

rate_smooth() {
  awk -v p="$1" -v n="$2" 'BEGIN { printf "%.8f", (p * 0.7) + (n * 0.3) }'
}

seconds_from_rate() {
  awk -v c="$1" -v r="$2" 'BEGIN { if (r > 0) printf "%d", c / r }'
}

text="$(icon_for_capacity "$capacity") $capacity%"
class=""
tooltip="$status\nCalculating…"
rate=""

case "$status" in
  Charging)
    text="⚡ $capacity%"
    class="charging"
    ;;
  Full)
    text="🔌 $capacity%"
    tooltip="Full"
    ;;
  "Not charging")
    text="🔌 $capacity%"
    tooltip="Not charging"
    ;;
esac

if (( capacity <= 15 )); then
  class="critical"
elif (( capacity <= 30 )) && [[ "$status" != "Charging" ]]; then
  class="warning"
fi

prev_status=""
prev_charge=""
prev_time=""
prev_rate=""
ref_charge=""
ref_time=""

if [[ -f "$STATE" ]]; then
  prev_status=$(awk 'NR==1' "$STATE")
  prev_charge=$(awk 'NR==2' "$STATE")
  prev_time=$(awk 'NR==3' "$STATE")
  prev_rate=$(awk 'NR==4' "$STATE")
  ref_charge=$(awk 'NR==5' "$STATE")
  ref_time=$(awk 'NR==6' "$STATE")
fi

if [[ -z "$ref_charge" || -z "$ref_time" ]]; then
  if [[ "$status" == "$prev_status" && -n "$prev_charge" && -n "$prev_time" ]]; then
    ref_charge="$prev_charge"
    ref_time="$prev_time"
  else
    ref_charge="$charge_now"
    ref_time="$now"
  fi
fi

if [[ "$status" != "$prev_status" ]]; then
  ref_charge="$charge_now"
  ref_time="$now"
else
  case "$status" in
    Discharging)
      if (( charge_now < ref_charge )); then
        delta=$(( ref_charge - charge_now ))
        elapsed=$(( now - ref_time ))
        if (( elapsed > 0 && delta > 0 )); then
          new_rate=$(rate_calc "$delta" "$elapsed")
          if [[ -n "$prev_rate" ]]; then
            rate=$(rate_smooth "$prev_rate" "$new_rate")
          else
            rate="$new_rate"
          fi
          ref_charge="$charge_now"
          ref_time="$now"
        fi
      else
        rate="$prev_rate"
      fi
      ;;
    Charging)
      if (( charge_now > ref_charge )); then
        delta=$(( charge_now - ref_charge ))
        elapsed=$(( now - ref_time ))
        if (( elapsed > 0 && delta > 0 )); then
          new_rate=$(rate_calc "$delta" "$elapsed")
          if [[ -n "$prev_rate" ]]; then
            rate=$(rate_smooth "$prev_rate" "$new_rate")
          else
            rate="$new_rate"
          fi
          ref_charge="$charge_now"
          ref_time="$now"
        fi
      else
        rate="$prev_rate"
      fi
      ;;
    *)
      rate=""
      ;;
  esac
fi

case "$status" in
  Discharging)
    if [[ -n "$rate" && "$rate" != "0" ]]; then
      seconds_left=$(seconds_from_rate "$charge_now" "$rate")
      if [[ -n "$seconds_left" && $seconds_left -gt 0 ]]; then
        tooltip="Discharging\n$(format_time "$seconds_left") remaining"
      fi
    fi
    ;;
  Charging)
    if [[ -n "$rate" && "$rate" != "0" ]]; then
      remaining=$(( charge_full - charge_now ))
      seconds_left=$(seconds_from_rate "$remaining" "$rate")
      if [[ -n "$seconds_left" && $seconds_left -gt 0 ]]; then
        tooltip="Charging\nFull in $(format_time "$seconds_left")"
      fi
    fi
    ;;
  Full)
    rate=""
    ref_charge="$charge_now"
    ref_time="$now"
    ;;
  "Not charging")
    rate=""
    ref_charge="$charge_now"
    ref_time="$now"
    ;;
  *)
    rate=""
    ref_charge="$charge_now"
    ref_time="$now"
    ;;
esac

printf '%s\n%s\n%s\n%s\n%s\n%s\n' \
  "$status" "$charge_now" "$now" "$rate" "$ref_charge" "$ref_time" > "$STATE"
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
