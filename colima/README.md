# Colima Configuration

Container runtime config for [Colima](https://github.com/abiosoft/colima) (Docker without Docker Desktop).

Only the `default` profile's `colima.yaml` is version-controlled. The VM disk,
sockets, and lima state are runtime data and stay out of git.

## Why this package exists

Colima historically stored everything under `~/.colima`. When `$XDG_CONFIG_HOME`
is set, it warns on every command:

```
found ~/.colima, ignoring $XDG_CONFIG_HOME...
```

This package moves Colima's home to the XDG path and pins it so the warning is gone
and the config lives in the dotfiles repo.

## How it works

- `sources/docker.sh` exports `COLIMA_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/colima"`
  so Colima always uses `~/.config/colima` deterministically (and `DOCKER_HOST`
  points at the socket under it).
- `install.sh` stows this package with `--no-folding` — Colima writes VM state into
  `~/.config/colima`, so only `default/colima.yaml` is symlinked, not the whole dir.
- Per-instance `colima.yaml` is **not** regenerated on `colima start`, so the symlink
  is stable.

## Autostart at login

`Library/LaunchAgents/com.guna.colima.plist` runs `colima start -f` at login.
`brew services start colima` is **not** used because its generated plist only sets
`PATH` — launchd would not see `COLIMA_HOME`, so Colima would fall back to the legacy
`~/.colima` instead of this XDG profile. The custom agent pins `COLIMA_HOME` explicitly.
No `KeepAlive`, so `colima stop` is not fought.

```bash
# load now (install.sh does this automatically)
launchctl bootstrap gui/"$(id -u)" ~/Library/LaunchAgents/com.guna.colima.plist
# disable autostart
launchctl bootout gui/"$(id -u)" ~/Library/LaunchAgents/com.guna.colima.plist
```

Logs: `~/Library/Logs/colima.log`.

## Installation

```bash
cd ~/.dotfiles
mkdir -p ~/.config/colima/default
stow -v --no-folding colima
launchctl bootstrap gui/"$(id -u)" ~/Library/LaunchAgents/com.guna.colima.plist
```

Creates: `~/.config/colima/default/colima.yaml` → `~/.dotfiles/colima/.config/colima/default/colima.yaml`
and `~/Library/LaunchAgents/com.guna.colima.plist` → the tracked plist.

## Migrating from a legacy `~/.colima`

If you still have the old directory, move it once (stop Colima first):

```bash
colima stop            # if running
mv ~/.colima ~/.config/colima
```

## Resources

- [Colima](https://github.com/abiosoft/colima)
- [Colima FAQ](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md)
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
