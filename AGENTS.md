# Agent Guidelines

Guidelines for AI assistants working on this personal dotfiles repository.

## Project Overview

Personal dotfiles repository managing cross-platform development environment
configurations using GNU Stow.

**Stack**: Zsh, Neovim (15 LSP servers), Ghostty, Homebrew, Git
**Platforms**: macOS (ARM/Intel), Linux
**Current Version**: Neovim 0.11.5

## Core Principles

1. **Official documentation first**: fetch current official docs before changing
   tool configuration.
2. **Security first**: never commit secrets such as `.aws/credentials`, SSH
   private keys, API tokens, or machine-local credentials.
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

## Neovim Review Gate

The `nvim-review-flow` skill is staged at
`agent-skills/nvim-review-flow/SKILL.md` until it moves to the separate
`agent-skills` repository.

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

## Workflow

1. **Research**: fetch official documentation for changed tools.
2. **Review**: identify likely bugs, drift, and simplification opportunities.
3. **Implement**: follow existing patterns and keep the change scoped.
4. **Validate**: run targeted checks.
5. **Document**: update relevant docs for behavior/setup changes.
6. **Report**: summarize what changed, what passed, and what remains.

## Commit Format

```text
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`.

Examples:

- `feat(nvim): add telescope-file-browser extension`
- `fix(zsh): correct PATH detection for ARM Macs`
- `docs(readme): update installation instructions`

## Critical Rules

### Do

- Fetch official documentation before implementing.
- Check for API deprecations.
- Test all changes before committing.
- Update documentation with every user-facing change.
- Use `pass` for credential management.

### Do Not

- Use outdated blog posts as the only source.
- Commit secrets or credentials.
- Skip testing or documentation.
- Use deprecated APIs without checking.
- Hardcode platform-specific paths.

## Key Resources

- Neovim: <https://neovim.io/doc/>
- lazy.nvim: <https://lazy.folke.io/>
- Telescope: <https://github.com/nvim-telescope/telescope.nvim>
- Homebrew: <https://docs.brew.sh/>
- Ghostty: <https://ghostty.org/docs>
