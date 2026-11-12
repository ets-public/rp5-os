#!/usr/bin/env bash
# Step 1: prove the laptop can reach the RP5 in Qualcomm EDL mode.
# READ-ONLY: only `printgpt` and a read (`r`) of one partition, compared
# against the adb backup. Nothing is written to the device.
#
# EDL is the chip's boot-ROM recovery mode. It's the route back if a
# bootloader flash ever fails, so we prove it works before flashing anything.
#
# Needs:
#   - gate/00-setup-laptop.sh done
#   - a verified backup from gate/02-pull-backup.sh (BACKUP=path)
#   - a firehose loader for the RP5 (LOADER=path) if the edl tool can't
#     find one by itself. Finding a loader is part of this step.
#   - the RP5 in EDL mode (USB id 05c6:9008). The button combo for the RP5
#     is still to be confirmed; see docs/safety-gate.md.
set -euo pipefail

TOOLS="${TOOLS:-$HOME/rp5-tools}"
EDL="$TOOLS/edl-venv/bin/edl"
BACKUP="${BACKUP:?Set BACKUP to the verified backup folder from 02-pull-backup.sh}"
OUT="${OUT:-$HOME/rp5-backup/edl-readtest}"
mkdir -p "$OUT"

if ! lsusb | grep -q '05c6:9008'; then
  echo "RP5 is not in EDL mode (no 05c6:9008 USB device). See docs/safety-gate.md."
  exit 1
fi

LOADER_ARGS=()
[ -n "${LOADER:-}" ] && LOADER_ARGS=(--loader="$LOADER")

echo "== Reading the partition table over EDL"
"$EDL" printgpt "${LOADER_ARGS[@]}" | tee "$OUT/gpt.txt"

# Pick the active slot's abl from the backup's recorded slot
slot=$(grep -o 'ro.boot.slot_suffix\]: \[_[ab]' "$BACKUP/getprop.txt" | tail -c 3 || true)
part="abl${slot}"
echo "== Reading $part over EDL and comparing with the adb backup"
"$EDL" r "$part" "$OUT/$part.edl.img" "${LOADER_ARGS[@]}"

a=$(sha256sum "$OUT/$part.edl.img" | cut -d' ' -f1)
b=$(sha256sum "$BACKUP/$part.img" | cut -d' ' -f1)
if [ "$a" = "$b" ]; then
  echo "PASS: EDL read of $part matches the backup. The EDL restore route works."
else
  echo "MISMATCH: EDL read of $part differs from the backup. Stop and investigate."
  exit 1
fi

echo "Reboot the RP5 normally with: $EDL reset ${LOADER_ARGS[*]}"
