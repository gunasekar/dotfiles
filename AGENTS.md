# Agent Guidelines

Guidelines for AI assistants working on this personal dotfiles repository.

## Project Overview

Personal dotfiles repository managing cross-platform development environment
configurations using GNU Stow.

**Stack**: Zsh, Neovim (15 LSP servers), Terminal.app (default, macOS), kitty (alternate), Homebrew, Git
**Platforms**: macOS (ARM/Intel), Linux
**Neovim**: Verify the installed version with `nvim --version`.

## Core Principles

1. **Official documentation first**: fetch current official docs before changing
   tool configuration and check for deprecations — never rely on outdated blog
   posts alone.
2. **Security first**: never commit secrets such as `.aws/credentials`, SSH
   private keys, API tokens, or machine-local credentials. Use `pass` for
   credential management.
3. **Review before changing**: look for runtime bugs, tool ownership drift,
   keymap conflicts, lazy-loading issues, and documentation drift.
4. **Follow local patterns**: prefer existing repo structure and helper APIs.
5. **Validate changes**: run focused checks for touched areas and report any
   remaining failures.
6. **Document user-facing changes**: update relevant README and quick reference
   files when behavior, setup, or commands change.

## Configuration Patterns

### Neovim Plugins

- Use lazy.nvim.
- Keep plugin specs under `nvim/.config/nvim/lua/plugins/`.
- Prefer `opts` when the plugin supports `setup(opts)`.
- Use `config` when setup needs custom callbacks, generated keymaps, or module
  calls that must run after plugin load.
- Avoid top-level `require()` in plugin spec files when it causes eager loading.
  Use `opts = function()` or `config` instead.
- Avoid deprecated APIs such as `vim.loop` and
  `vim.lsp.buf.formatting()`.

### Tool Ownership

- Global CLI tools: add to `brew/.Brewfile`.
- Python tools: add to `python/requirements.txt`.
- Project-specific JavaScript/TypeScript plugins: keep in the project that uses
  them.
- Neovim LSP/tool verification: update
  `nvim/.config/nvim/lua/config/mason-verify.lua`.
- Neovim linter wiring: update
  `nvim/.config/nvim/lua/plugins/quality/lint.lua`.
- Neovim formatter wiring: update
  `nvim/.config/nvim/lua/plugins/quality/formatters.lua`.

### Shell Scripts

- Shell function libraries live in `sources/*.sh`.
- Scripts must pass `shellcheck` before commit.
- Detect architecture dynamically instead of hardcoding platform paths.

### Launch Agents

- Label is `local.guna.<job>`. `.local` is a reserved TLD, so the label claims
  no domain, and `guna` keeps it from colliding with other `local.*` agents.
- `<job>` uses lowercase letters, digits and hyphens, and names the tool or
  task (`colima`, `print-to-pdf`). Add a dotted sub-segment only to tell apart
  several jobs for one tool (`local.guna.backup.daily`).
- Filename is the label plus `.plist`.
- The plist lives in its tool's stow package at `<pkg>/Library/LaunchAgents/`,
  in `.dotfiles-private` when it holds anything private. Stow it with
  `--no-folding`.
- Agents a tool installs itself (`homebrew.mxcl.*`, `sh.brew.*`) keep that
  tool's label.

## Neovim Review Gate

The `nvim-review-flow` skill lives at `.agents/skills/nvim-review-flow/SKILL.md`
— scoped to this repo only, not installed globally to `~/.agents/skills/`.

Before finishing any Neovim-related change, use that skill when it is available,
or explicitly apply the same review flow:

- Review runtime behavior, lazy-loading, LSP/completion, formatter/linter
  ownership, keymaps, public-sharing assumptions, and docs drift.
- Validate with `nvim --headless '+checkhealth' '+qa'` and
  `nvim --headless '+MasonVerify' '+qa'`.
- Syntax-check Neovim Lua files under `nvim/.config/nvim/lua/**/*.lua`.
- Run scoped `pre-commit run --files <changed-files>`.
- Run `markdownlint nvim/QUICK_REFERENCE.md nvim/REVIEW_FLOW.md` when those docs
  are changed.
- Report unrelated failures separately.

## Commit Format

```text
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`.

Examples:

- `feat(nvim): add telescope-file-browser extension`
- `fix(zsh): correct PATH detection for ARM Macs`
- `docs(readme): update installation instructions`

## Key Resources

- Neovim: <https://neovim.io/doc/>
- lazy.nvim: <https://lazy.folke.io/>
- Telescope: <https://github.com/nvim-telescope/telescope.nvim>
- Homebrew: <https://docs.brew.sh/>
- kitty: <https://sw.kovidgoyal.net/kitty/>
