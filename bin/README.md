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
| `aigent cockpit [N]` | several agents at once in one window — re-attach to one already up, pick a set, or take the `N` that most want you (`cockpit new` forces a fresh pick) |
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
| `AGENT_NOTIFY_AFTER` | `0` | seconds an agent must sit wanting you before the SwiftBar plugin says so — `0` speaks on the poll that sees it stop |

`aigent status` feeds a SwiftBar plugin
(`swiftbar/.config/swiftbar/plugins/agents.10s.sh`) that shows a menu-bar count
and announces each `working → stopped` edge once. Out of the box it speaks on the
poll that sees the stop, which means a session you are sat in front of announces
itself at the end of every reply — nothing can tell "you are watching this one"
apart from "you walked away". `AGENT_NOTIFY_AFTER` is the lever: raise it and an
agent has to sit there wanting you that long before it may say so, which silences
the one you are working with for free, because you reply and it goes back to
`working`.

### The cockpit

`aigent cockpit` puts several agents in one window. It's the third question the
script answers: the picker asks *what do I open here*, `aigent status` asks *who
wants me*, and this one is *watch four of them work, and answer whichever one
stops* — without leaving the window.

```bash
aigent cockpit      # re-attach to a cockpit already up, else pick from a list
aigent cockpit new  # ignore any running cockpit and pick a fresh set
aigent cockpit 4    # skip the picking: the 4 that most want you
```

The picker offers tab-to-select with a live preview of each agent's screen.

```
┌─ augur · claude · Add partner integration ─┬─ studio · claude · restructure exchange ───┐
│  Do you want to proceed?                   │  Editing internal/pkg/exchange…            │
│  ❯ 1. Yes                                  │  ⠂ Thinking…                               │
├─ foundry · claude · Improve observability ─┼─ scratch · antigravity ────────────────────┤
│  ✳ Wiring up OpenObserve                   │                                            │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

Panes are ordered the way the picker is — blocked, then idle, then working — so
the agent that wants you is top-left and the ones getting on with it sort to the
back. Each border reads `<dir> · <agent> · <what it's working on>` — the directory
`aigent` stamps on the pane, then the agent and task from the title the agent
publishes, which tmux carries up through the pane with nothing polling anything.
(A pane whose agent hasn't set a task yet shows just `<dir> · <agent>`, as the
`scratch` one above does.)

It's an ordinary tmux session, so the keys are the stock ones — and you can type
into any pane, which is the point: see a permission prompt, answer it in place.

| Key | Does |
|---|---|
| `C-b ←↑↓→` | move between agents |
| `C-b z` | zoom one agent full-screen |
| `C-b Space` | cycle the layout |
| `C-b d` | detach — the agents keep running |
| `C-b C-b s` | change which agent *this pane* shows — session tree |
| `C-b C-b )` / `(` | next / previous agent in this pane, no menu |

Those last two are the same trick twice, and the doubled prefix is not a typo. A
cockpit stacks **two tmux clients**: the one your terminal talks to (attached to
`cockpit`) and, inside each pane, one attached to an agent. The prefix only ever
reaches the outer one — so plain `C-b s` opens the *cockpit's* session chooser,
and picking an agent there switches your whole view to it full-screen. You've left
the grid. (Useful sometimes; `C-b L` comes back.)

Doubling it is what gets past. The second press is `send-prefix`, which writes a
literal prefix byte *into the pane* — and that pane's terminal is the inner
client, which reads it as its own prefix. So `s` lands there instead, and only
that pane moves. It's the standard nested-tmux idiom, not a cockpit invention; the
cockpit is just the one place you have clients stacked.

`C-Space C-Space` works the same, since both prefixes are live. tmux only ships
the `C-b` half (its binding names the default prefix rather than tracking whatever
you set), so `tmux.conf` adds the other — see *Two prefixes* in
[tmux/README.md](../tmux/README.md).

|  | acts on | result |
|---|---|---|
| `C-b s` | the cockpit | your whole view leaves the grid for one agent |
| `C-b C-b s` | one pane | that pane shows a different agent, grid intact |

The border relabels itself on arrival, and the agent you left keeps running with
nothing attached — the pane was only ever borrowing it. One thing to skip: both
inner routes can reach `cockpit` itself (the tree lists it, and `)` cycles every
session alphabetically), which gives you a cockpit inside the cockpit. Harmless
and recoverable with another `C-b C-b s` — just pointless.

Detaching leaves the cockpit up; bare `aigent cockpit` (or `tmux a -t cockpit`)
walks back into the same grid, and `aigent cockpit new` builds a fresh one over a
different set. Quit an agent and its pane closes and the rest re-tile; quit the
last one and the cockpit disposes of itself and drops you back where you came from.

**There is only ever one.** The session is always named `cockpit`, so `aigent
cockpit new` replaces the one you had rather than adding a second — and if another
window was sitting in that cockpit, it drops back to a shell when the session goes.
(Your agents don't notice; they never do.) That's deliberate. A cockpit holds no
state, so there's nothing to accumulate and nothing worth naming, and one fixed
name means bare `aigent cockpit` and `tmux a -t cockpit` both always find it. Scale
the panes instead: eight agents is `aigent cockpit 8`, not two cockpits of four.

**The cockpit owns nothing.** Every pane is a tmux client attached to a live
`aigent-<project>` session, so it borrows the view rather than taking the pane:
kill the cockpit, close the window, crash it, and every agent is exactly where it
was, still running, still attached to whatever else was viewing it. That is also
why building one (`aigent cockpit new`, or `cockpit N`) always builds fresh rather
than reconciling an old one — rebuilding is free when there is no state to keep. The session is named `cockpit`
rather than `aigent-cockpit` for the same reason: the `aigent-` prefix means "an
agent lives here", and a viewer that ended up under it would be reported by
`aigent status` and counted by the notifier as one more agent to watch.

**Whichever view you're typing in wins.** A tmux window has one grid, so a session
that two clients of different shapes are watching — a cockpit pane and a Zed
thread, say — cannot be drawn right for both. That isn't fixable, only aimable, so
`window-size` is left at tmux's default `latest`, which sizes a session to its most
recently *used* client. The view you're working in is therefore always the correct
one; the one you aren't touching draws small with `···` filler until you press a
key in it, which re-elects it instantly. Closing the cockpit restores everything.
(`-f ignore-size` is the other end of that lever — it would keep Zed pristine and
put the dead space in the cockpit pane instead. The script's comments say why it
isn't used.)

The other cost follows from the same re-flow: a resize is a screen change, so the
`aigent status` poll that straddles an attach reads those agents as `working` for
a cycle, and the SwiftBar plugin announces them once more as they settle back —
the one place a still screen can read as moving. `AGENT_NOTIFY_AFTER` is the dial
for that too.

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
