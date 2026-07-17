# tmux Configuration

Session persistence for remote and agent work. The tmux server runs on the
remote host, so a dropped ssh link, a closed laptop, or quitting Ghostty leaves
your work running — Ghostty is only the viewer.

Tuned for long-running coding-agent sessions (Claude Code) and for Neovim, not
copied from a starter gist. Every non-obvious line in `tmux.conf` says why it's
there.

## Installation

tmux is already declared in `brew/.Brewfile`. `install.sh` stows it, or by hand:

```bash
cd ~/.dotfiles
stow tmux
```

This creates `~/.config/tmux/tmux.conf` → `~/.dotfiles/tmux/.config/tmux/tmux.conf`.

On a remote host, deploy the dotfiles there the same way — don't hand-edit a
`~/.tmux.conf` on the box. To remove: `stow -D tmux`.

A running server does **not** re-read the config. After editing: `prefix + r`,
or `tmux kill-server` for a clean slate.

## Daily Commands

Prefix is `Ctrl+b` **or** `Alt+Space` — press either, release, then the key.
Both are always live; the tables below show `Ctrl+b`.

| Action | Command |
|--------|---------|
| Start or re-attach a session | `tmux new -A -s my_project` |
| Detach (leaves it running) | `Ctrl+b` `d` |
| List sessions | `tmux ls` |
| Attach to a named session | `tmux a -t my_project` |
| Kill a session | `tmux kill-session -t my_project` |

`new -A -s` is the idiom worth learning: attach if it exists, create if it
doesn't. It's the whole `new`-or-`attach` dance in one command.

## Keybindings

| Keybinding | Action |
|------------|--------|
| `Ctrl+b` `\|` | Split pane right (inherits current directory) |
| `Ctrl+b` `-` | Split pane down (inherits current directory) |
| `Ctrl+b` `g` | Lazygit in a popup over the current pane |
| `Ctrl+b` `m` | Toggle the 60s silence alert for this window |
| `Ctrl+b` `r` | Reload `tmux.conf` |
| `Ctrl+b` `s` | Session switcher (`choose-tree`, built in) |
| `Ctrl+b` `z` | Zoom the current pane |
| `Ctrl+b` `[` | Enter copy-mode; `v` select, `y` copy, `q` quit |

Windows and panes number from 1 and renumber themselves when one closes.

## Agent Sessions

`tmux.conf` is tuned for long-running coding-agent panes (Claude Code and
friends). The launcher that actually creates and manages those sessions — the
fzf picker, the `working`/`idle`/`blocked` status view, the one-agent-one-pane
enforcement — is a separate script, `bin/.local/bin/aigent`, documented with its
own source. This section covers only the settings that live here.

**Scrollback** is 20k lines. tmux's 2k default buries the start of an agent run,
but scrollback is the one part of tmux that costs real memory: measured at
~3.9KB per line of wide truecolor output, so a pane holding tmux-sensible's
50k lines of agent output reaches ~190MB. 20k is ~78MB, and you only pay for
lines actually produced — idle panes are free.

**Bell notifications.** Claude Code rings the terminal bell when it finishes or
wants input. `monitor-bell` + `bell-action any` + `visual-bell off` keep that a
real bell, so it reaches Ghostty instead of being swallowed into a tmux status
line. It's Claude-only, though — the other three agents never ring.

**Silence alerts.** `Ctrl+b` `m` arms `monitor-silence` on the current window: no
output for 60s and the window is flagged in the status bar. Off by default.
`#{window_silence_flag}` is sticky alert bookkeeping rather than a live "is this
pane producing output" bit — it stays set while a pane is actively painting — so
it's a rough "did that build stop" flag for ordinary windows, nothing more.

**Pane labels.** `pane-border-status top` labels every pane with its running
command, so a grid of panes tells you which is `claude` and which is a shell.

**Tab title.** `set-titles-string` gives Ghostty's tab `claude · <task>` when a
session carries an `@agent` user option, and the default `#S:#W ·
#{pane_current_command}` otherwise. `@agent` exists because the command name
alone lies — Claude Code reports `claude.exe` (a Bun single-file executable),
cursor-agent reports bare `node` (a Node wrapper) — so whatever launches the
agent records what it started. The task half is the agent's own title:
`pane_title`, an OSC 2 string Claude Code fills with its `/resume` summary. Two
guards on it — tmux seeds `pane_title` with the hostname, so a title-less program
falls back to the project directory, and Claude Code leads with an animated
spinner glyph, so the first word is stripped.

**One agent, one pane.** The split and new-window keys (`|`, `-`, `"`, `%`, `c`)
are guarded by `if -F '#{@agent_locked}'`, so a session carrying that user option
refuses to split rather than let a second pane confuse tools that treat the
session as a single view:

```tmux
bind | if -F '#{@agent_locked}' 'display "agent session: one agent, one pane"' \
                                'split-window -h -c "#{pane_current_path}"'
```

A hook can't enforce this — **every tmux hook is `after-*`**, there is no
`before-split-window`, so a hook could only create the pane and then kill it.
Refusing the key is strictly better: no pane is born, nothing is destroyed. The
binding is server-global (every tmux binding is) but reads `@agent_locked` from
whichever session the key was pressed in, so a session you started yourself
splits exactly as before.

Both `@agent` and `@agent_locked` are user options that something else sets —
`aigent`, here — so on a session you launched by hand neither is present, and
every setting above falls back to its default form.

**Nested clients.** `aigent cockpit` shows several agent sessions in one window by
giving each pane a nested tmux client (`env -u TMUX tmux attach -t <session>` —
tmux sets `$TMUX` in every pane it creates and refuses to nest while it is set).
It needs nothing added here, but it makes four of the settings above load-bearing
in a second way:

- `set-titles-string` becomes a **pane border** as well as a Ghostty tab. The
  inner client emits the title to its terminal — which *is* the cockpit's pane —
  so the cockpit reads `claude · <task>` straight off `#{pane_title}` with nothing
  polling. The hostname and spinner-glyph guards come along for free.
- **Truecolor survives the nest** with no `terminal-features` entry for
  `tmux-256color`, which declares neither `Tc` nor `RGB` in its terminfo. tmux
  negotiates RGB with the outer tmux at runtime instead of trusting the entry, so
  the nested agent keeps its colours. (Verified by diffing the escape a nested
  pane emits: `38;2;255;0;0`, not a downsampled `38;5;196`.)
- **CSI-u survives it too**, because `extended-keys` is a *server* option (`set -s`,
  not `set -g`) — it is already true of the inner client, so Shift+Enter reaches
  the agent through two tmuxes.
- `window-size` stays at its default `latest`, which sizes a window to its most
  recently *used* client — not the newest one. That is what makes an agent re-flow
  to whichever client you last typed in, so the view you are working in is always
  the right one. A window has one grid, so two clients of different shapes viewing
  one session cannot both be right: the one you are not touching draws small with
  `···` filler until you press a key in it, which re-elects it.
- **Keys go to the outermost client first**, so `C-b` in a cockpit is the cockpit's
  prefix and the inner client never sees it. `C-b C-b` is the way through — the
  stock `bind-key -T prefix C-b send-prefix` passes a literal `C-b` into the pane,
  where the inner client reads it as its own prefix. That is what makes
  `C-b C-b s` (choose-tree) re-point a single cockpit pane at a different agent.

## Notes

### No plugins, deliberately

tmux already survives ssh drops, Wi-Fi loss, and quitting Ghostty on its own.
The popular plugins mostly buy things this config covers natively:

- **tmux-yank** → superseded by `set-clipboard on` and OSC 52 (see below).
- **tmux-sensible** → its useful options are inlined in `tmux.conf`.
- **sesh / tmux-sessionx** → `choose-tree` (`prefix + s`) is built in.
- **tmux-resurrect / continuum** → the one real gap: they restore sessions after
  a **reboot of the host**. Worth adding *only* if that starts happening; the
  cost is bootstrapping a plugin manager on every machine you ssh into.

### Clipboard over ssh

`set -s set-clipboard on` lets Neovim (or an agent) on a remote box push a yank
to the local macOS clipboard via OSC 52. The default `external` is **not**
enough — it lets tmux set the clipboard but forbids applications inside from
doing so. Ghostty advertises the `Ms` capability, so tmux has somewhere to send
it.

### Truecolor needs no configuration

Ghostty sets `TERM=xterm-ghostty`, whose terminfo declares `Tc` — tmux's own
truecolor flag — so tmux derives RGB support on its own. Verified via
`#{client_termfeatures}`, which lists `RGB` with no color options set at all.
Both lines the tutorials tell you to paste are dead config here:

```tmux
set -ag terminal-overrides ",xterm-256color:Tc"   # keys off a TERM we never send
set -as terminal-features ",xterm-ghostty:RGB"    # re-states what Tc already said
```

This relies on the `xterm-ghostty` terminfo entry existing on the remote, which
the `Match exec` hook in `~/.ssh/config` handles (see `~/.local/bin/ssh-terminfo-sync`).

### Extended keys, or half your Neovim bindings die

`set -s extended-keys on` is not optional here. Legacy terminal input can only
encode a couple of dozen control keys; anything outside that set has no byte
representation at all and silently never reaches the application inside tmux.
That covers much of the Neovim agent workflow:

| Key | Binding | Works without extended-keys? |
|---|---|---|
| `<C-\>` | toggle right panel | yes — `0x1c` is a real control code |
| `` <C-`> `` | toggle bottom panel | **no** |
| `<C-S-\>` | new agent session | **no** |
| `<C-S-]>` / `<C-S-[>` | cycle agent sessions | **no** |
| `<C-S-.>` | send context to agent | **no** |
| `<C-Esc>` | agent panel | **no** |

`Ctrl+Shift+<punct>`, `Ctrl+backtick` and `Ctrl+Esc` exist only under CSI-u.
Three settings are all required, and this is the one place Ghostty's terminfo
is **not** enough (unlike `Tc` and `Smulx`):

```tmux
set -s extended-keys always
set -s extended-keys-format csi-u
set -as terminal-features "xterm-ghostty:extkeys"
```

- **`extkeys`** — tmux requests extended keys from the terminal only *if it
  believes the terminal supports them*, and it decides that from terminfo.
  `xterm-ghostty` doesn't advertise `extkeys`, so without this tmux never asks
  Ghostty, and the keys never arrive at all.
- **`always`** — with `on`, tmux forwards only to apps that ask via tmux's own
  `modifyOtherKeys` handshake. Neovim asks via the **Kitty** protocol, which
  tmux doesn't implement ([tmux#3335](https://github.com/tmux/tmux/issues/3335)),
  so `on` forwards nothing to it.
- **`csi-u`** — the default format is `xterm` (`^[[27;6;92~`); Neovim and Claude
  Code expect `^[[92;6u`.

**These take effect when a client attaches, so `prefix + r` is not enough** —
run `tmux kill-server` and start a fresh session.

#### Shifted punctuation arrives under a different name inside tmux

Even wired up correctly, `Ctrl+Shift+<punctuation>` is reported *differently*
inside tmux, and this is not fixable in config. Bare Ghostty speaks the **Kitty**
keyboard protocol to Neovim, which reports the **base** key — `Ctrl+Shift+\` is
`<C-S-\>`. tmux doesn't implement that protocol
([tmux#3335](https://github.com/tmux/tmux/issues/3335), closed unimplemented) and
negotiates xterm's older `modifyOtherKeys`, which reports the **shifted
character** — so the same keypress arrives as `<C-S-|>`.

| Key | Outside tmux | Inside tmux |
|---|---|---|
| `Ctrl+Shift+\` | `<C-S-\>` | `<C-S-\|>` |
| `Ctrl+Shift+]` | `<C-S-]>` | `<C-S-}>` |
| `Ctrl+Shift+[` | `<C-S-[>` | `<C-S-{>` |
| `Ctrl+Shift+.` | `<C-S-.>` | `<C-S->>` |
| ``Ctrl+Shift+` `` | ``<C-S-`>`` | `<C-S-~>` |
| `Ctrl+Shift+L` | `<C-S-L>` | `<C-S-L>` — letters are fine |

So `plugins/agents.lua` and `plugins/editor/snacks.lua` bind **both spellings**
to the same action. Zellij is the only multiplexer that speaks the Kitty
protocol natively, if this ever becomes worth switching for.

To check the wiring: run `cat -v` in a pane and press `Ctrl+Shift+\`. You should
see `^[[92;6u`. Nothing at all means the negotiation isn't happening.

### Images need allow-passthrough

`set -g allow-passthrough on` is required by `image.nvim` / `diagram.nvim` —
without it, tmux swallows the Kitty graphics escapes and diagrams render
nothing. See `nvim/.config/nvim/lua/plugins/diagram.lua`.

### No custom colours

tmux and the terminal supply their own colours; nothing here overrides them. The only
styling left is the status bar's **content** — session name on the left, clock on the
right — and a transparent background (`bg=default`, the absence of a colour, so it's
the terminal's own rather than tmux's default green slab). Borders, the window list,
copy-mode selection and messages all use tmux's stock styling.

This started life as a hand-picked Ayu palette to match Ghostty, then as ANSI-palette
references so it would track any theme. Both were upkeep for little gain — the status
bar is off in agent sessions anyway, so the styling only ever showed in manual tmux
sessions. Removed rather than maintained.

One consequence worth knowing: copy-mode selection is now tmux's default highlight,
and either way it's a solid fill — the terminal draws *its* selection as a translucent
overlay that tints the text underneath. For that exact look, bypass tmux's mouse
capture with the terminal's own selection modifier (Shift-drag in Ghostty).

### Two prefixes: Ctrl+b and Alt+Space

Both are live (`prefix` and `prefix2`). `Ctrl+b` stays primary so every
cheatsheet, guide and remote host behaves as documented; `Alt+Space` is the
comfortable one to actually reach for.

The two prefixes people usually reach for are both taken here: `Ctrl+a` (the
classic Screen rebind) shadows readline **beginning-of-line** in zsh, and
`Ctrl+Space` shadows **blink.cmp's force-completion key**
(`nvim/.config/nvim/lua/plugins/lsp/completion.lua`). `Alt+Space` is free across
zsh, Neovim (only `<A-j>`/`<A-k>` are bound) and Ghostty.

### Mouse mode is on

Click a pane to focus it, wheel to scroll history, drag a border to resize,
click a window name in the status line to switch.

The usual warning against this doesn't apply. tmux runs on the **alternate
screen** (it emits `smcup` on attach), so Ghostty's scrollback receives no pane
output at all — there is no native scrollback to trade away, and with the mouse
off the wheel does nothing whatsoever. Pane history lives only inside tmux.

The one real trade is selection: a drag belongs to tmux now. That's mostly fine,
because tmux's drag-select copies to the macOS clipboard anyway via
`set-clipboard`. Mouse release uses `copy-selection-no-clear` rather than the
default `copy-pipe-and-cancel`, so a selection copies **without** jumping back
to the live cursor — you stay scrolled with the highlight still visible.

A single click then clears the highlight, and whether it also *leaves* copy mode
depends on where you are — which is what keeps a stray click from throwing away
your place in a long agent response:

| Where | A click does | Why |
| --- | --- | --- |
| Scrolled up | Clears the highlight, stays put | Leaving would snap the viewport back down to the prompt. Leave with `q`, or scroll to the bottom — that exits on its own (`copy-mode -e`). |
| At the bottom | Leaves copy mode | Nothing to lose, and it's how you dismiss a double-clicked word — that path enters with `copy-mode -H`, so staying would mean an *invisible* copy mode eating your keystrokes. |

So while reading history, clicking around is inert: the first click drops the
highlight and every one after it does nothing. `Escape` clears the highlight
without leaving if you want another selection; `q` leaves.

The **highlight looks different** from a native selection, and can't not. The
terminal draws selection as a *translucent overlay* — `selection-background` with
alpha, tinting the text so it stays readable underneath, which is what makes it look
mild. tmux only speaks solid SGR colours, no alpha, so its selection is a solid
block (bright blue, `mode-style` above) rather than a tint. When you want the
terminal's *own* selection — its exact look, or to span pane borders — bypass tmux's
mouse capture and drag with the terminal's modifier: in Ghostty hold **Shift**
(`mouse-shift-capture` defaults to `false`); Zed's terminal uses its own binding.

### Ghostty splits vs. tmux panes

Ghostty binds `Ctrl+H/J/K/L` to `goto_split` as `performable:`, so those keys
only reach tmux/Neovim when no Ghostty split exists in that direction. Locally,
prefer Ghostty's splits (`Cmd+D`, `Cmd+Shift+T`); use tmux panes on remotes,
where Ghostty has none. This is also why `vim-tmux-navigator` isn't installed —
it would put three layers in contention for the same four keys.

## Resources

- [tmux manual](https://man.openbsd.org/tmux)
- [tmux FAQ](https://github.com/tmux/tmux/wiki/FAQ) — terminfo and RGB
- [tmux Clipboard wiki](https://github.com/tmux/tmux/wiki/Clipboard) — `set-clipboard` semantics
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
