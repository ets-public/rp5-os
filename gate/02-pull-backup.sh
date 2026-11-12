#!/usr/bin/env bash
# Step 1: copy the on-device backup to the laptop and verify every checksum.
# Read-only on the RP5: only adb pull.
#
# Run AFTER gate/device/backup_partitions.sh has finished on the RP5
# and its log ends with "DONE: all partitions backed up".
set -euo pipefail

DEST="${DEST:-$HOME/rp5-backup/partitions-$(date +%Y%m%d-%H%M)}"
mkdir -p "$DEST"

if ! adb shell 'grep -q "^DONE: all partitions" /sdcard/rp5-backup/backup.log' 2>/dev/null; then
  echo "The on-device backup isn't marked complete. Check /sdcard/rp5-backup/backup.log on the RP5."
  exit 1
fi

echo "== Pulling backup to $DEST (super is large, this takes a while)"
adb pull /sdcard/rp5-backup/. "$DEST/"

echo "== Verifying checksums"
(cd "$DEST" && sha256sum -c SHA256SUMS)

echo "== Must-have partitions"
missing=0
for want in abl xbl persist modemst1 modemst2 fsg; do
  if [ -e "$DEST/$want.img" ] || [ -e "$DEST/${want}_a.img" ] || [ -e "$DEST/${want}_b.img" ]; then
    echo "  ok      $want"
  else
    echo "  MISSING $want (may be named differently; check partition-map.txt)"
    missing=1
  fi
done

echo
echo "Backup verified in $DEST"
echo "Now copy it to a second place (USB drive or cloud) before going further:"
echo "  rsync -a \"$DEST\" /run/media/\$USER/<drive>/"
[ "$missing" = 0 ] || exit 2
