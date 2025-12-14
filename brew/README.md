# Homebrew Packages

System-wide tools and applications managed via Homebrew.

## Quick Start

```bash
# Install all packages
brew bundle

# Install from dotfiles directory
cd ~/.dotfiles/brew
brew bundle
```

## What's Included

### Development Tools
- **neovim** - Modern Vim-based text editor
- **git-delta** - Syntax-highlighting pager for git
- **lazygit**, **gitui** - Terminal Git UIs
- **ripgrep**, **fd** - Fast search tools
- **fzf** - Fuzzy finder
- **jq**, **yq** - JSON/YAML processors

### Language Runtimes
- **go** - Go programming language
- **node** - Node.js runtime
- **python@3.13** - Python 3.13
- **openjdk@17**, **openjdk@21** - Java runtimes

### Linters & Formatters
- **shellcheck** - Shell script linter
- **hadolint** - Dockerfile linter
- **luacheck** - Lua linter
- **yamllint** - YAML linter
- **markdownlint-cli** - Markdown linter
- **golangci-lint** - Go linter

### Infrastructure Tools
- **docker**, **docker-buildx** - Container tools
- **colima** - Container runtime
- **terraform** - Infrastructure as code
- **kubectl** - Kubernetes CLI
- **awscli** - AWS command line

### Utilities
- **bat** - Better cat with syntax highlighting
- **htop** - Interactive process viewer
- **stow** - Dotfiles manager
- **watch** - Execute commands periodically

## Updating

Update all packages:

```bash
brew update
brew upgrade
```

Update Brewfile from current installations:

```bash
brew bundle dump --force
```

## Neovim Integration

These linters are used by nvim's lint plugin:
- shellcheck (shell scripts)
- hadolint (Dockerfiles)
- luacheck (Lua files)
- yamllint (YAML files)
- markdownlint-cli (Markdown files)
- golangci-lint (Go files)

See: `nvim/.config/nvim/lua/plugins/lint.lua`

## Adding New Packages

```bash
# Install a package
brew install package-name

# Update Brewfile
brew bundle dump --force
```

## Cleanup

Remove unused packages:

```bash
brew autoremove
brew cleanup
```
