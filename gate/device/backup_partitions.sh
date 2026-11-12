#!/system/bin/sh
# RP5 partition backup. Runs ON THE DEVICE as root, via
#   Settings > Handheld Settings > Advanced > Run Script as Root
#
# READ-ONLY on internal partitions: every block device is only ever used as
# dd's input (if=). The only writes go to /sdcard/rp5-backup/.
#
# Skipped: userdata (it's where the backup is written, and it holds your
# own files, not firmware). super is backed up because a factory restore
# may need it; it is several GB.

OUT=/sdcard/rp5-backup
LOG="$OUT/backup.log"

# Find the by-name directory (differs between Qualcomm builds)
BYNAME=""
for d in /dev/block/by-name /dev/block/bootdevice/by-name /dev/block/platform/*/by-name; do
  if [ -d "$d" ]; then BYNAME="$d"; break; fi
done

mkdir -p "$OUT" || exit 1
: > "$LOG"
log() { echo "$*" | tee -a "$LOG"; }

if [ -z "$BYNAME" ]; then
  log "ERROR: no by-name partition directory found. Nothing was backed up."
  exit 1
fi

log "rp5-os partition backup  $(date)"
log "by-name dir: $BYNAME"
log "model: $(getprop ro.product.model)  build: $(getprop ro.build.fingerprint)"
log "current slot: $(getprop ro.boot.slot_suffix)"

# Record the partition map and device info so restore steps can be checked later
ls -l "$BYNAME" > "$OUT/partition-map.txt"
getprop > "$OUT/getprop.txt"
cat /proc/partitions > "$OUT/proc-partitions.txt"

# Rough space check: need the sum of all partitions (except userdata) free.
# Android 13 has no awk, so sizes come from sysfs (512-byte sectors).
need_kb=0
for p in "$BYNAME"/*; do
  name=$(basename "$p")
  [ "$name" = "userdata" ] && continue
  dev=$(basename "$(readlink -f "$p")")
  if [ -r "/sys/class/block/$dev/size" ]; then
    sectors=$(cat "/sys/class/block/$dev/size")
    need_kb=$((need_kb + sectors / 2))
  fi
done
# shellcheck disable=SC2046  # split df columns on purpose
set -- $(df -k "$OUT" | tail -n 1)
free_kb=$4
log "need ~${need_kb} KB, free ${free_kb} KB"
if [ -n "$free_kb" ] && [ "$free_kb" -lt "$need_kb" ]; then
  log "ERROR: not enough free space on internal storage. Free some space and run again."
  exit 1
fi

fail=0
: > "$OUT/SHA256SUMS"
for p in "$BYNAME"/*; do
  name=$(basename "$p")
  [ "$name" = "userdata" ] && { log "skip  $name"; continue; }
  if dd if="$p" of="$OUT/$name.img" bs=4M 2>>"$LOG"; then
    (cd "$OUT" && sha256sum "$name.img" >> SHA256SUMS)
    log "ok    $name"
  else
    log "FAIL  $name"
    fail=1
  fi
done

if [ "$fail" = 0 ]; then
  log "DONE: all partitions backed up to $OUT"
else
  log "DONE WITH ERRORS: check $LOG before going any further"
fi
