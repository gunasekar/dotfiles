# bin

Personal scripts, stowed onto `PATH` at `~/.local/bin`. The coding-agent picker
that used to live here is [trails](https://github.com/gunasekar/trails), installed
by the Brewfile.

| Script | What it does |
|---|---|
| `keepawake` | hold off idle sleep for a set stretch, from a command line — the thing Amphetamine could not do over ssh |
| `netcheck` | internet speed test that also checks the router hop and the Wi-Fi link, to say which hop is slow |

## Installation

```bash
cd ~/.dotfiles
stow bin
```

Symlinks `keepawake` and `netcheck` into `~/.local/bin`. It is run by hand
and by the `keepawake.1m.sh` SwiftBar plugin.

## keepawake

Holds off idle sleep for a set stretch, from a command line — what Amphetamine did
from the menu bar, minus the part where you have to be sitting in front of it.
Amphetamine is a GUI app: its triggers live in the logged-in session, and at a lock
screen even `osascript` reaching for System Events times out. This works over ssh
with the lid open and the screen locked, which is the only reason it exists.

| Command | Does |
|---|---|
| `keepawake` | who is holding this Mac awake right now |
| `keepawake 6h` | hold it awake for six hours, replacing any hold already up |
| `keepawake 30m` / `45` / `90s` | hours, minutes, seconds — a bare number is minutes |
| `keepawake on` | hold it awake until something says otherwise |
| `keepawake off` | drop our hold |
| `keepawake status` | a sentence on a terminal, TSV when piped |

```console
$ keepawake 6h
awake — 6h 00m left of a 6h hold
awake — held by claude (pid 82625)
```

One hold at a time, always replacing: two overlapping caffeinates is two things to
remember to cancel and a menu bar that can only offer to stop one of them. Holders
that are *not* ours — Claude Code mid-turn, a Time Machine run — are read out of
`pmset -g assertions` and reported alongside, named for what they are holding the
machine awake *for* rather than for `caffeinate`, which they all are.

It asserts `-i -m -s` and deliberately not `-d` or `-u`. `-i` is the one that
matters; `-d` would light a panel nobody is looking at, and `-u` is worse than
absent — it turns the display *on*, so a "keep the box up" sent from a phone would
wake a screen in an empty room.

**It cannot beat a closed lid.** Clamshell sleep is a separate path that ignores
assertions entirely, and the only lever on it is `sudo pmset -a disablesleep 1` —
machine-wide, permanent, and so not something this script reaches for on your
behalf.

`keepawake status` feeds a SwiftBar plugin
(`swiftbar/.config/swiftbar/plugins/keepawake.1m.sh`) that draws a filled cup while
we hold it, a hollow one while something else does, `zzz` when the Mac is free to
drop off, and offers 30m / 1h / 6h / 12h / open-ended from the menu.

## netcheck

An internet speed test that also says which hop is to blame. It measures against
`speed.cloudflare.com` the way fast.com and Ookla do: several streams for a fixed
time, the TCP ramp-up discarded, and latency probed again while the line is loaded.
Before that it pings the router and reads the Wi-Fi link, because a speed test alone
cannot tell a bad Wi-Fi hop from a slow ISP. Python standard library only, so it runs
as is on macOS and on a plain Debian box.

| Command | Does |
|---|---|
| `netcheck` | full test: local network, latency, download, upload (~30 s, ~300 MB) |
| `netcheck -d 20` | 20 seconds per direction instead of 10 |
| `netcheck -s 8` | 8 parallel streams instead of 4 |
| `netcheck --no-upload` | skip the upload test |
| `netcheck --json` | the result as JSON, for logging |

```console
$ netcheck
netcheck  speed.cloudflare.com via Chennai (MAA)

Connection
  ISP        Broad Band Internet Service Provider, India (AS24309)
  Public IP  2406:7400:… (IPv6, HTTP/1.1)
  Location   Bengaluru, Karnataka IN

Local network
  Router     192.168.0.1 via wlxe4fac4fb7a5a: 2.3 ms ±0.3 ms, 0% loss
  Wi-Fi      5 GHz ch 44 80 MHz · signal -40 dBm · rate rx 117 / tx 650 Mbps · power save off

Internet
  Latency    8.7 ms idle, jitter 0.7 ms   (TCP handshake to Cloudflare)
  Loss       0%   (ICMP to 1.1.1.1, 2.4 ms)
  Download    106.2 Mbps  p90 110.5 Mbps · loaded latency 26.8 ms (+18.1 ms) · bufferbloat A
  Upload      115.2 Mbps  p90 126.7 Mbps · loaded latency 11.7 ms (+3.0 ms) · bufferbloat A+
  Responsiveness  2241 RPM   (round trips a minute under load)
  Data used  292 MB

Diagnosis    healthy
```

- **Download / Upload** is the steady rate after a 2 s ramp-up, across all streams;
  **p90** is the 90th percentile of 1-second windows, the figure Cloudflare's page leads with.
- **Loaded latency** and the **bufferbloat** grade (Waveform's A+…F scale) show how much
  the router's queues add while the line is full. **RPM** is the same thing the way
  macOS `networkQuality` reports it: round trips a minute under load.
- **Latency** is a TCP handshake to the Cloudflare edge — one network round trip with
  no server time in it. **Loss** comes from ICMP to 1.1.1.1.
- Wi-Fi details come from `system_profiler` on macOS and `iw` on Linux (`apt install iw`;
  without it the line just says connected). A Mac's own Wi-Fi power saving makes its
  router pings read 20–60 ms at idle; that is normal there, and the diagnosis only
  blames the local network past 100 ms or 2% loss.
- `speed.cloudflare.com`'s endpoints are undocumented. If Cloudflare changes them,
  netcheck exits with an error rather than reporting a wrong number.
