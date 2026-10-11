# bin

Personal scripts, stowed onto `PATH` at `~/.local/bin`. The coding-agent picker
that used to live here is [trails](https://github.com/gunasekar/trails), installed
by the Brewfile.

| Script | What it does |
|---|---|
| `keepawake` | hold off idle sleep for a set stretch, from a command line — the thing Amphetamine could not do over ssh |

## Installation

```bash
cd ~/.dotfiles
stow bin
```

Symlinks `keepawake` into `~/.local/bin`. It is run by hand
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
that are *not* ours — an agent launched with `trails`' `ctrl-a`, Claude Code
mid-turn, a Time Machine run — are read out of `pmset -g assertions` and reported
alongside, named for what they are holding the machine awake *for* rather than for
`caffeinate`, which they all are.

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
