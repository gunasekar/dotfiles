# AI Assistant Guidelines

Guidelines for AI assistants working on this personal dotfiles repository.

## Project Overview

Personal dotfiles repository managing cross-platform development environment configurations using GNU Stow.

**Stack**: Zsh, Neovim (15 LSP servers, 9 linters), Ghostty, Homebrew, Git
**Platforms**: macOS (ARM/Intel), Linux
**Current Version**: Neovim 0.11.5

## Core Principles

1. **Official Documentation First**: Always fetch latest official docs using WebFetch before implementing
2. **Security First**: Never commit secrets (`.aws/credentials`, SSH keys, API tokens)
3. **Test Before Commit**: Run `nvim --headless`, `shellcheck`, `pre-commit run --all-files`
4. **Follow Patterns**: Use existing patterns in the codebase
5. **Document Changes**: Update relevant README.md and QUICK_REFERENCE.md

## Configuration Patterns

### Neovim Plugins
- Use lazy.nvim plugin manager
- One file per plugin in `nvim/.config/nvim/lua/plugins/`
- Use `config` function, not top-level `require()`
- Avoid deprecated APIs: `vim.loop` → `vim.uv`, `vim.lsp.buf.formatting()` → `vim.lsp.buf.format()`

### Linters
- System-wide: Add to `brew/.Brewfile`
- Python: Add to `python/requirements.txt`
- Always update `nvim/.config/nvim/lua/plugins/lint.lua`

### Shell Scripts
- Location: `sources/general/*.sh`
- Must pass `shellcheck` before committing
- Detect architecture dynamically (ARM vs Intel)

## Workflow

1. **Research**: Fetch official documentation
2. **Implement**: Follow official docs and existing patterns
3. **Test**: Verify functionality (`nvim --headless`, `shellcheck`)
4. **Document**: Update relevant READMEs
5. **Commit**: Use conventional commits format

## Commit Format

```
<type>(<scope>): <description>
```

**Types**: `feat`, `fix`, `docs`, `refactor`, `chore`

**Examples**:
- `feat(nvim): add telescope-file-browser extension`
- `fix(zsh): correct PATH detection for ARM Macs`
- `docs(readme): update installation instructions`

## Critical Rules

### ✅ DO
- Fetch official documentation before implementing
- Check for API deprecations
- Test all changes before committing
- Update documentation with every change
- Use `pass` for credential management

### ❌ DON'T
- Use outdated blog posts or Stack Overflow
- Commit secrets or credentials
- Skip testing or documentation
- Use deprecated APIs without checking
- Hardcode platform-specific paths

## Key Resources

- **Neovim**: https://neovim.io/doc/
- **Lazy.nvim**: https://lazy.folke.io/
- **Telescope**: https://github.com/nvim-telescope/telescope.nvim
- **Homebrew**: https://docs.brew.sh/
- **Ghostty**: https://ghostty.org/docs
