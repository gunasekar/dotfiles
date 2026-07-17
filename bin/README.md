# bin

Personal scripts, stowed onto `PATH` at `~/.local/bin`.

| Script | What it does |
|---|---|
| `aigent` | fzf picker that runs coding agents (Claude Code, Cursor, …) inside persistent tmux sessions |
| `ssh-terminfo-sync` | ssh pre-connect hook that keeps `xterm-ghostty` terminfo present on remote hosts |

## Installation

```bash
cd ~/.dotfiles
stow bin
```

Symlinks both scripts into `~/.local/bin`. `ssh-terminfo-sync` is wired up from
`~/.ssh/config` (`Match exec`); `aigent` is run by hand and by Zed / Neovim as
their agent-terminal command.

## aigent

Runs the agent you pick inside a tmux session named `aigent-<project>`, so the
process outlives the terminal that started it — close the laptop, drop Wi-Fi, or
quit Ghostty and the conversation is still running when you come back. Every
frontend (a plain shell, a Zed thread, an nvim panel) goes through the same
script and lands on the same session; reattach from anywhere with
`tmux a -t aigent-<project>`.

Run with no argument and it shows what's already running for this project
alongside the agents you can start, sorted by what wants your attention first:

```
● [blocked · claude]          Rework the retry budget   ← asking you something
● [idle · cursor · #2]        Fix the flaky auth test   ← finished its turn, your move
● [working · claude · #3]     Migrate the schema        ← getting on with it
new     claude
new     cursor
…
```

| Command | Does |
|---|---|
| `aigent` | pick a running session to rejoin, or an agent to start |
| `aigent new` | skip the running sessions, start a fresh one |
| `aigent status` | every agent session on the box — a table on a terminal, TSV (state, session, agent, task) when piped, for a notifier |
| `ctrl-x` (in picker) | kill the highlighted session |

Add an agent by dropping one `name|command|args` line into the `AGENTS` table at
the top of the script — it drives the menu, the PATH filter and the launch.

`aigent` refuses to open an agent in `/` or `$HOME`: an agent treats the
directory you start it in as the project, and neither of those is ever what you
meant — but both are one stray `cd` away. Reporting is unaffected — `aigent
status` answers for the whole box and works from anywhere.

### The status column

Each row says whether the agent is `working`, `idle` (finished its turn) or
`blocked` (asking you something). There are no per-agent hooks — the signal is
the screen: every one of these TUIs animates while it works, so `aigent` hashes
each pane, waits `AGENT_SETTLE`, and hashes again. A changed screen is `working`;
an unchanged one whose bottom is asking a question is `blocked`; otherwise
`idle`. Screen-diffing is agent-agnostic, so Cursor, opencode and antigravity
get the same treatment Claude does.

| env | default | what it does |
|---|---|---|
| `AGENT_SETTLE` | `0.35` | gap between the two screen samples — raise for an agent that repaints slower than once a second |
| `AGENT_ASK_RE` | *(see script)* | regex meaning "this agent is asking you something" (`blocked` vs `idle`) |
| `AGENT_NOTIFY_AFTER` | `60` | seconds an agent must sit wanting you before the SwiftBar plugin says so |

`aigent status` feeds a SwiftBar plugin
(`swiftbar/.config/swiftbar/plugins/agents.10s.sh`) that shows a menu-bar count
and notifies only once an agent has sat wanting you past `AGENT_NOTIFY_AFTER` —
being in front of it silences the alert for free, because you reply and it goes
back to `working`.

The design rationale — why tmux, why screen-diffing beats hooks, the
one-agent-one-pane guards, and the `@agent` / `@agent_locked` user options — lives
in the script's own comments and in `tmux/README.md`.

## ssh-terminfo-sync

Pre-connect hook driven by `~/.ssh/config` `Match exec`. Ghostty sends
`TERM=xterm-ghostty`; a remote host without that terminfo entry gives zsh a
broken line editor, so `ls` echoes as `llsls`. The script compiles the entry
into `~/.terminfo` on the remote, and its exit status tells ssh which `TERM` to
send. See the script header for why it replaces Ghostty's own `ssh-terminfo`
integration and why it lives in `ssh_config` rather than a shell function.
