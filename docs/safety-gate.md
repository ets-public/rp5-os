# Step 1: safety gate

Nothing is written to the RP5's internal storage until **every box below is ticked**.
All scripts here are read-only on the device. The only internal write in the whole
project (flashing OpenABL in step 2) waits behind this gate.

## Checklist

- [ ] **Laptop tools** — `gate/00-setup-laptop.sh` (adb, fastboot, `edl` tool, udev rule)
- [ ] **Device seen** — `gate/01-check-device.sh` shows a Retroid Pocket 5, battery 80%+
- [ ] **Full partition backup on the device** — `gate/device/backup_partitions.sh` run as root
      ends with `DONE: all partitions backed up`
- [ ] **Backup on the laptop, checksums pass** — `gate/02-pull-backup.sh`, then copied to a
      second place (USB drive or cloud)
- [ ] **Factory firmware in hand** — Retroid's official RP5 firmware package, or written
      instructions from Retroid support on how to get and flash it
- [ ] **EDL read test passes** — `gate/03-edl-readtest.sh` reads `abl` over EDL and it matches
      the backup
- [ ] **Restore steps dry run** — read through "Factory restore" below with the real file
      names from your backup filled in
- [ ] **Battery baseline recorded** — see [battery-baseline.md](battery-baseline.md)

If the factory firmware or a working EDL loader can't be found, **stop here**. Nothing on the
device has been changed, and we decide together how to go on.

## Running each step

### 1. Laptop tools

```bash
git clone https://github.com/ets-public/rp5-os && cd rp5-os
./gate/00-setup-laptop.sh
```

### 2. Check the device

Plug the RP5 into the laptop, accept the USB debugging prompt on its screen, then:

```bash
./gate/01-check-device.sh
```

### 3. Back up every partition (on the RP5)

1. Copy the script to the RP5:
   ```bash
   adb shell mkdir -p /sdcard/rp5-gate
   adb push gate/device/backup_partitions.sh /sdcard/rp5-gate/
   ```
2. On the RP5: **Settings > Handheld Settings > Advanced > Run Script as Root**, pick
   `rp5-gate/backup_partitions.sh`.
3. Wait. `super` is several GB. Check progress from the laptop:
   ```bash
   adb shell tail -n 5 /sdcard/rp5-backup/backup.log
   ```

The script only reads partitions (`dd if=`). It skips `userdata` (your own files, and where the
backup is written).

### 4. Pull and verify

```bash
./gate/02-pull-backup.sh
```

Then copy the folder it prints to a second place. The device-unique partitions (`persist`,
`modemst1`, `modemst2`, `fsg`) can't come from any factory image, so these copies are the only ones.

### 5. Factory firmware

To do: find Retroid's official RP5 firmware. If there's no public download, ask Retroid support
for the factory image and their flashing instructions. Save it next to the backup.

### 6. EDL read test

EDL (Qualcomm emergency download mode) lives in the chip's boot ROM, so no flash can remove
it. It's the way back if a bootloader flash ever fails.

To confirm: how to enter EDL on the RP5 (a button combo while plugging in, or
`adb reboot edl`), and a firehose loader that works with the RP5. The `edl` tool ships
loaders for many SM8250 devices, and may find one by itself.

```bash
adb reboot edl              # try this first; lsusb should show 05c6:9008
BACKUP=~/rp5-backup/partitions-YYYYMMDD-HHMM ./gate/03-edl-readtest.sh
# with a specific loader:
LOADER=/path/to/loader.elf BACKUP=... ./gate/03-edl-readtest.sh
```

## Factory restore

Use this to undo step 2 (OpenABL) and return the RP5 to factory.

**If Android still boots** (normal case):

1. Remove the SD card.
2. Push the saved stock ABL for the active slot and write it back as root:
   ```bash
   adb push ~/rp5-backup/partitions-.../abl_X.img /sdcard/rp5-gate/
   ```
   On the RP5, run as root: `dd if=/sdcard/rp5-gate/abl_X.img of=/dev/block/by-name/abl_X`
   (`X` = the slot in `getprop.txt`). We'll add a checked restore script for this in step 2.
3. Reboot. The device starts Android as normal.

**If the device won't boot**:

1. Enter EDL mode (method confirmed in the gate above).
2. Write the saved ABL back over EDL:
   ```bash
   ~/rp5-tools/edl-venv/bin/edl w abl_X ~/rp5-backup/partitions-.../abl_X.img
   ```
3. If that's not enough, flash Retroid's factory firmware over EDL using their instructions.

Only ever restore your own backup to your own device.
