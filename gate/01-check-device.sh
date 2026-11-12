#!/usr/bin/env bash
# Step 1: confirm the laptop can talk to the RP5 over adb and record what it is.
# Read-only: only runs getprop/ls on the device.
#
# On the RP5 first: Settings > About > tap Build number 7 times,
# then Developer options > USB debugging on. Accept the prompt on screen.
set -euo pipefail

OUT="${OUT:-$HOME/rp5-backup/device-info}"
mkdir -p "$OUT"

adb start-server >/dev/null
state=$(adb get-state 2>/dev/null || true)
if [ "$state" != "device" ]; then
  echo "RP5 not found over adb (state: ${state:-none})."
  echo "Check the cable, USB debugging, and accept the prompt on the RP5 screen."
  exit 1
fi

adb shell getprop > "$OUT/getprop.txt"
model=$(adb shell getprop ro.product.model | tr -d '\r')
build=$(adb shell getprop ro.build.fingerprint | tr -d '\r')
slot=$(adb shell getprop ro.boot.slot_suffix | tr -d '\r')
battery=$(adb shell dumpsys battery | tr -d '\r' | awk -F': ' '/level/ {print $2; exit}')

echo "Model:         $model"
echo "Build:         $build"
echo "Active slot:   ${slot:-unknown}"
echo "Battery:       ${battery:-?}%"

if adb shell 'ls /dev/block/by-name' > "$OUT/partitions.txt" 2>/dev/null && [ -s "$OUT/partitions.txt" ]; then
  echo "Partitions:    $(wc -l < "$OUT/partitions.txt") listed (saved to $OUT/partitions.txt)"
else
  echo "Partitions:    not listable without root (normal; the backup script runs as root)"
fi

case "$model" in
  *"Pocket 5"*|*RP5*) ;;
  *) echo; echo "WARNING: model doesn't look like a Retroid Pocket 5. Stop and check before going on." ;;
esac

if [ -n "$battery" ] && [ "$battery" -lt 80 ]; then
  echo; echo "Charge to 80% or more before the backup."
fi

echo; echo "Saved device info to $OUT"
