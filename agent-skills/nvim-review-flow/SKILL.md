---
name: nvim-review-flow
description: Review and validate Neovim configuration, plugins, LSP/tooling, keymaps, lazy-loading, formatter/linter ownership, and related docs. Use when changing or reviewing Neovim config, Neovim plugin specs, brew/python tooling for Neovim, or when the user asks to review Neovim configuration and plugins.
---

# Neovim Review Flow

Use this skill before finishing any Neovim-related change.

## Scope

Apply this workflow when touching:

- `nvim/.config/nvim/**`
- `nvim/README.md`
- `nvim/QUICK_REFERENCE.md`
- `nvim/REVIEW_FLOW.md`
- `brew/.Brewfile`
- `python/requirements.txt`
- Any change that affects Neovim startup, plugins, LSP, completion, formatters,
  linters, keymaps, or editor documentation.

## Review Checklist

Before editing or finalizing, check:

- Runtime behavior: startup order, user commands, health checks, and plugin setup.
- Lazy-loading: avoid top-level `require()` in plugin specs when it eager-loads
  dependencies.
- LSP/completion: confirm server commands, root markers, capabilities, and
  completion integration.
- Tool ownership: global CLIs go in `brew/.Brewfile`, Python tools go in
  `python/requirements.txt`, and project-specific Node plugins stay in the
  project that uses them.
- Format/lint wiring: keep formatter config, linter config, and tool verification
  aligned.
- Keymaps: check for conflicts, stale references, and missing descriptions.
- Public sharing: call out local commands, forks, terminal assumptions, and
  security-sensitive flags.
- Docs: keep setup, quick reference, and review docs aligned with actual
  behavior.

## Validation

Run targeted checks when relevant:

```bash
nvim --headless '+checkhealth' '+qa'
nvim --headless '+MasonVerify' '+qa'
pre-commit run --files <changed-files>
markdownlint nvim/QUICK_REFERENCE.md nvim/REVIEW_FLOW.md
```

Also syntax-check all Lua files under `nvim/.config/nvim/lua/**/*.lua`.

For full repo validation, use:

```bash
pre-commit run --all-files
```

Report unrelated failures separately instead of changing unrelated files.

## Output

When reporting back, include:

- Bugs or risks found.
- Refactors or simplifications performed or deferred.
- Tool ownership changes.
- Validation commands run and their result.
- Remaining warnings or unrelated repo failures.
