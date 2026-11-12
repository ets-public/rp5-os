# Battery baseline

We measure stock Android first, so every change in our OS can be compared with real numbers.

## Test setup (keep it the same every run)

| Setting | Value |
| --- | --- |
| Start charge | 100%, unplugged |
| Brightness | 50% |
| Wi-Fi | On (needed for logging), Bluetooth off |
| Volume | 50%, speakers |
| Fan / performance mode | Default (note what it is) |
| Run length | Until 20% or 2 hours, whichever comes first |

Run each test game the same way. Suggested set:

1. **Light**: a SNES game in RetroArch
2. **Medium**: a PS1 game in DuckStation
3. **Heavy**: a PS2 or GameCube game (AetherSX2/NetherSX2 or Dolphin)

## Logging

Use adb over Wi-Fi, so USB isn't charging the device during the test:

```bash
adb tcpip 5555
adb connect <rp5-ip>:5555      # IP from Settings > Wi-Fi
# unplug USB, start the game, then:
LABEL=stock-snes ./gate/04-battery-log.sh
```

Stop with Ctrl+C. Each run saves a CSV in `~/rp5-backup/`. The result to record is
**percent per hour**: (start level − end level) ÷ hours.

| Game | System | %/hour (stock) | %/hour (rp5-os) |
| --- | --- | --- | --- |
| | SNES | | |
| | PS1 | | |
| | PS2/GC | | |
