# bin

Personal scripts, stowed onto `PATH` at `~/.local/bin`.

| Script | What it does |
|---|---|
| `aigent` | fzf picker that runs coding agents (Claude Code, Cursor, …) inside persistent tmux sessions |
| `keepawake` | hold off idle sleep for a set stretch, from a command line — the thing Amphetamine could not do over ssh |

## Installation

```bash
cd ~/.dotfiles
stow bin
```

Symlinks `aigent` and `keepawake` into `~/.local/bin`. `aigent` is run by hand and
by Zed / Neovim as their agent-terminal command; `keepawake` is run by hand and by
the `keepawake.1m.sh` SwiftBar plugin.

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
| `aigent ls` | every agent session on the box — a table on a terminal, TSV (state, session, agent, task) when piped, for a notifier |
| `aigent cockpit [N]` | several agents at once in one window — re-attach to one already up, pick a set, or take the `N` that most want you (`cockpit new` forces a fresh pick) |
| `aigent restore` | bring back every session that died with tmux, each resuming its conversation, detached (`-n` lists them instead) |
| `tab` (in picker) | arm the highlighted agent for YOLO — run everything unconfirmed |
| `ctrl-a` (in picker) | arm the highlighted row to hold this Mac awake for as long as that session lives |
| `ctrl-x` (in picker) | kill the highlighted session, or forget a `↻` row |

Add an agent by dropping one `name|command|args|yolo|pin|resume|idform` line into the
`AGENTS` table at the top of the script — it drives the menu, the PATH filter and the
launch. Leave the last three empty if the agent can't be restored (see below).

`aigent` refuses to open an agent in `/`: an agent treats the directory you
start it in as the project, and the filesystem root is never what you meant —
but a `cd` with an unset variable lands there. `$HOME` is allowed, for a
general-purpose session that isn't tied to one project. Reporting is unaffected —
`aigent ls` answers for the whole box and works from anywhere.

### Keeping the Mac awake

`ctrl-a` in the picker arms the highlighted row to hold this Mac awake for as long
as that session lives, drawn as a cyan `(awake)` badge next to the row. It is
orthogonal to `tab`, so a row can be both YOLO and awake.

It exists because a laptop is not a server. This box idle-sleeps a minute after
the display does (`pmset -g custom` says `sleep 1`), so an agent left working
overnight — a long cloud run, a migration, anything you start and walk away from
— finds itself in `Maintenance Sleep` instead. Claude Code does hold its own
`caffeinate -i -t 300` while it is *working*, which is exactly the wrong window:
the assertion lapses while the agent sits waiting on the thing you left it doing.

Per-launch and opt-in on purpose. Most agent sessions are you sat in front of the
machine, where sleep never comes up and an assertion is just a warmer laptop; only
you know, at the moment you press Enter, which run is the walk-away one.

A new session is started *under* caffeinate (`caffeinate -ims claude …`), which is
the documented idiom and means the assertion's lifetime is the agent's by
construction — nothing to reap, no way to leave the Mac pinned awake by an agent
that died an hour ago. Attaching to a session that already exists takes the same
lifetime from the other end, with `caffeinate -ims -w <pane pid>`.

Worth knowing about the process tree, because it is the reverse of what it looks
like: caffeinate does not fork the agent off as a child. It forks a *helper* that
holds the assertion and execs the agent in the original process, so it adds no
process of its own between the agent and the restore wrapper (see below).

```console
$ ps -eo pid,ppid,comm
94161 78117 claude       <- the agent, child of the restore wrapper
95208 94161 caffeinate   <- its child, holding the assertion
```

These holds are deliberately *not* routed through `keepawake`: that owns one
manual timed hold, and an agent silently cancelling your six-hour hold by
attaching would be a bad surprise. `keepawake status` reports them as separate
holders, named for the agent rather than for caffeinate.

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
| `AGENT_NOTIFY_AFTER` | `30` | seconds an agent must sit wanting you before the SwiftBar plugin says so — `0` speaks on the poll that sees it stop |

`aigent ls` feeds a SwiftBar plugin
(`swiftbar/.config/swiftbar/plugins/agents.10s.sh`) that shows a brain in the menu
bar — red when an agent is asking you something, yellow when one finished its turn,
plain while they all work — with a superscript count of how many want you, and announces each `working → stopped` edge once — but not instantly: by default an
agent must sit stopped for 30 seconds first. That silences the session you are sat
in front of for free, because you reply within the wait and it goes back to
`working`, while one you walked away from still speaks. Nothing can tell "you are
watching this one" apart from "you walked away", so time is the only lever —
`AGENT_NOTIFY_AFTER` tunes it: `0` speaks on the poll that sees the stop, higher
trades latency for quiet.

### Surviving a tmux restart

Every agent lives inside the tmux server, so a reboot, a crash or `tmux kill-server`
takes them all down. The conversations survive, since each CLI keeps its transcripts on
disk. What gets lost is which conversation belonged to which session. So `aigent` writes that
down outside tmux, in one small file per session under `~/.local/state/aigent/sessions/`
(agent, directory, conversation ID, YOLO, last known task), and brings sessions back
from it:

```console
$ aigent ls
● idle  _dotfiles  claude  Fixing the flaky test
↻ 2 sessions can be restored — aigent restore -n
$ aigent restore -n          # what would come back
$ aigent restore             # bring them all back, detached, then attach as usual
```

In the picker the same sessions show as `↻ [restore · claude]` rows for the directory
you're in: enter brings one back and attaches, ctrl-x forgets it. A restored session
gets its old name back and resumes the same conversation.

This works because `aigent` chooses each conversation's ID up front and passes it to
the agent (`claude --session-id`, `opencode --session`), then resumes by that ID
(`--resume`, `--session`). `--continue` wouldn't do: it means "the latest conversation in
this directory", so two sessions in one project would both resume the same one. Claude
and opencode are covered. cursor-agent could be, but only by asking `cursor-agent
create-chat` for an ID before every launch, so it isn't yet.

A record is deleted when its session ends on purpose: you quit the agent, or ctrl-x
it. It's kept when tmux takes the session down. Telling those two apart is the hard
part. tmux's own hooks can't do it: `session-closed` also fires partway through
`kill-server`, and `pane-exited` reports the wrong session. So the agent runs under a
tiny `sh` wrapper that deletes the record when the agent exits. When tmux dies, it hangs
up on the wrapper along with the agent, so the delete never runs.

Things worth knowing:

- Only sessions started after this feature shipped have records.
- A dead session keeps its name reserved, so a fresh agent started in that project
  lands on `-2` and can't overwrite the record you meant to come back to.
- An agent you opened and never typed into has no conversation to resume (claude says
  `No conversation found`). Restoring it starts a fresh one in its place.
- If the agent can't start at all (a bad token, say), the record is kept for next time.
- Restoring brings back the conversation, not whatever was in flight. A half-run
  command is gone, and you tell the agent to carry on.

### The cockpit

`aigent cockpit` puts several agents in one window. It's the third question the
script answers: the picker asks *what do I open here*, `aigent ls` asks *who
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

To add an agent without rebuilding, split a shell off the cockpit (`C-b |` or
`C-b -`) and run `aigent` there. Start or pick a session as usual: it gets its own
`aigent-<project>` session like anywhere else, and the shell pane turns into a view
of it, so the split you made becomes the new cell. (Run anywhere else inside tmux,
`aigent` still runs the agent bare in the current pane.)

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
`aigent ls` and counted by the notifier as one more agent to watch.

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
`aigent ls` poll that straddles an attach reads those agents as `working` for
a cycle, and the SwiftBar plugin announces them once more as they settle back —
the one place a still screen can read as moving. `AGENT_NOTIFY_AFTER` is the dial
for that too.

The design rationale — why tmux, why screen-diffing beats hooks, the
one-agent-one-pane guards, and the `@agent` / `@agent_locked` user options — lives
in the script's own comments and in `tmux/README.md`.

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
that are *not* ours — an agent launched with `aigent`'s `ctrl-a`, Claude Code
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
