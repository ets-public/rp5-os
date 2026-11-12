#!/usr/bin/env bash
# Step 1, on the CachyOS laptop: install the tools the safety gate needs.
# Changes only the laptop. Nothing is sent to the RP5.
set -euo pipefail

TOOLS="${TOOLS:-$HOME/rp5-tools}"

echo "== Installing adb/fastboot and build basics (sudo needed)"
sudo pacman -S --needed android-tools git python python-pip libusb

echo "== Installing the open-source Qualcomm EDL tool into $TOOLS/edl"
mkdir -p "$TOOLS"
if [ ! -d "$TOOLS/edl" ]; then
  git clone --recursive https://github.com/bkerler/edl "$TOOLS/edl"
fi
python -m venv "$TOOLS/edl-venv"
"$TOOLS/edl-venv/bin/pip" install --upgrade pip
"$TOOLS/edl-venv/bin/pip" install -r "$TOOLS/edl/requirements.txt"
"$TOOLS/edl-venv/bin/pip" install "$TOOLS/edl"

echo "== USB permissions for Qualcomm EDL (05c6:9008)"
RULE=/etc/udev/rules.d/51-qcom-edl.rules
if [ ! -f "$RULE" ]; then
  echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="05c6", ATTR{idProduct}=="9008", MODE="0666"' | sudo tee "$RULE" >/dev/null
  sudo udevadm control --reload-rules
fi

echo
echo "Done. Check with:"
echo "  adb version"
echo "  $TOOLS/edl-venv/bin/edl --help"
