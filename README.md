# rp5-os

Our own Linux OS and launcher for the Retroid Pocket 5 (Snapdragon 865 / SM8250):
a clean, console-like experience with better battery life than stock Android.

**Hard rule: the device must always be restorable to factory.** Nothing writes to
the RP5's internal storage until the safety gate in [`docs/safety-gate.md`](docs/safety-gate.md)
has passed.

## Layout

| Path | What it is |
| --- | --- |
| `gate/` | Step 1: safety gate scripts, run from the CachyOS laptop |
| `gate/device/` | Scripts that run on the RP5 itself (read-only) |
| `docs/` | Safety gate checklist, restore steps, battery baseline method |

Later steps (base OS image, Rust launcher and power manager) land in their own folders.
