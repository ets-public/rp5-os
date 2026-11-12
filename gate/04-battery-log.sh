#!/usr/bin/env bash
# Battery baseline: log the RP5's battery every minute over adb while a
# test game runs, so we can compare stock Android with our OS later.
# Read-only on the device (dumpsys battery). See docs/battery-baseline.md.
#
# Usage: LABEL=stock-snes gate/04-battery-log.sh
# Stop with Ctrl+C. Use Wi-Fi adb (adb tcpip) so USB isn't charging the device.
set -euo pipefail

LABEL="${LABEL:-stock}"
CSV="${CSV:-$HOME/rp5-backup/battery-$LABEL-$(date +%Y%m%d-%H%M).csv}"
INTERVAL="${INTERVAL:-60}"
mkdir -p "$(dirname "$CSV")"

echo "time,level_pct,voltage_mv,temp_c,status" > "$CSV"
echo "Logging to $CSV every ${INTERVAL}s. Ctrl+C to stop."

while true; do
  d=$(adb shell dumpsys battery 2>/dev/null | tr -d '\r') || { echo "adb lost, retrying"; sleep "$INTERVAL"; continue; }
  level=$(awk -F': ' '/ level:/ {print $2; exit}' <<<"$d")
  volt=$(awk -F': ' '/ voltage:/ {print $2; exit}' <<<"$d")
  temp=$(awk -F': ' '/ temperature:/ {printf "%.1f", $2/10; exit}' <<<"$d")
  status=$(awk -F': ' '/ status:/ {print $2; exit}' <<<"$d")
  echo "$(date -Iseconds),$level,$volt,$temp,$status" | tee -a "$CSV"
  if [ "$status" = "2" ]; then echo "  note: device reports charging; results won't be valid"; fi
  sleep "$INTERVAL"
done
