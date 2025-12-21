# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) for modular configuration across macOS and Linux systems.

## Features

- **Modular Structure**: Each application has its own directory, managed independently via Stow
- **Cross-Platform**: Supports both macOS (ARM/Intel) and Linux
- **Shell Configuration**: Zsh with Oh My Zsh, custom functions, and environment setup
- **Developer Tools**: Pre-configured for Go, Python, Java, Node.js, and more
- **AWS Utilities**: 90+ functions for ECS, S3, SSM, CloudWatch, and more
- **Security-First**: Credentials managed via environment variables or `pass`, never committed to git

## Quick Start

### Prerequisites

```bash
# macOS
xcode-select --install

# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Linux
sudo apt-get install git stow  # Debian/Ubuntu
sudo dnf install git stow      # Fedora/RHEL
```

### Installation

1. **Clone this repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Install packages via Homebrew**
   ```bash
   brew bundle --file=brew/.Brewfile
   ```

3. **Deploy configurations with Stow**
   ```bash
   # Deploy all configurations
   stow */

   # Or deploy specific configurations
   stow zsh git brew ssh

   # Note: Use --no-folding if needed to prevent symlinking entire directories
   stow --no-folding <directory>
   ```

4. **Reload your shell**
   ```bash
   exec $SHELL -l
   # Or use the alias: refreSH
   ```

## Repository Structure

```
.dotfiles/
├── zsh/              # Zsh configuration (.zshrc, .zshenv)
├── git/              # Git config with workspace-specific settings
├── sources/          # Shell function libraries
│   ├── general/      # Cross-platform utilities
│   │   ├── dev.sh           # Development tools (Go, Python, Java, NVM)
│   │   ├── aws.sh           # AWS CLI utilities (90+ functions)
│   │   ├── docker.sh        # Docker helpers
│   │   ├── media.sh         # Media download/playback utilities
│   │   ├── file.sh          # File operations
│   │   ├── ssh.sh           # SSH key management
│   │   ├── network.sh       # Network utilities
│   │   ├── jenkins.sh       # Jenkins CLI utilities
│   │   ├── utils.sh         # General utility functions
│   │   └── linux.sh         # Linux-specific utilities
├── brew/             # Homebrew packages (see brew/README.md)
├── python/           # Python dev tools (see python/README.md)
├── nodejs/           # Node.js guidelines (see nodejs/README.md)
├── nvim/             # Neovim IDE setup (15 LSP servers, 9 linters, Neo-tree)
├── ghostty/          # Ghostty terminal (see ghostty/README.md)
├── aws/              # AWS CLI configuration
├── ssh/              # SSH client configuration
├── gnupg/            # GPG configuration
├── mpv/              # mpv player configuration
├── mycli/            # MySQL CLI configuration
├── pgcli/            # PostgreSQL CLI configuration
├── ranger/           # Ranger file manager configuration
├── jenkins/          # Jenkins CLI configuration
├── macos/            # macOS-specific setup scripts
├── linux/            # Linux-specific setup scripts
├── claude/           # Claude Code configuration
├── xbar/             # xbar menu bar plugins (macOS)
└── ...
```

**Note:** Each major component has its own README with detailed setup instructions.

## Secrets Management

**IMPORTANT**: Never commit secrets to version control!

Use `pass` (password manager, already in Brewfile):
```bash
# Initialize pass
pass init your-gpg-key-id

# Store secrets
pass insert llm/deepseek
pass insert llm/groq
pass insert llm/openrouter

# Use in shell scripts or aliases:
export API_KEY=$(pass llm/deepseek)
```

## Development Tools & Linters

### Homebrew Packages
System-wide tools including linters for Shell, Dockerfile, Lua, YAML, Markdown, and Go.
```bash
cd brew && brew bundle
```
See: [brew/README.md](brew/README.md)

### Python Tools
Linters and formatters for Python development.
```bash
cd python && ./install.sh
```
See: [python/README.md](python/README.md)

### Node.js Tools
JavaScript/TypeScript tools (installed per-project).
See: [nodejs/README.md](nodejs/README.md)

### Neovim Integration
All linters are integrated with Neovim's LSP and lint plugin.
See: [nvim/README.md](nvim/README.md)

## Language & Tool Setup

### Go
- Auto-configures GOROOT and GOPATH
- Helper functions: `go-build-linux-arm64`, `go-build-linux-amd64`, `go-test-coverage`
- Linter: `golangci-lint` (via brew)

### Python
- Uses pyenv for version management
- Aliases: `python` → `python3`, `pip` → `pip3`
- Linters: `pylint`, `flake8`, `bandit` (via pip)

### Java
- Switch versions with `jdk <version>` (e.g., `jdk 17`)

### Node.js
- NVM configured (works on both ARM and Intel Macs)
- Auto-loads completion
- Linters: `eslint_d` (per-project)

### LLM API Keys
- Run `setup-llm-keys` to load API keys from `pass`
- Supports: DeepSeek, Groq, OpenRouter

## AWS Utilities

90+ functions for AWS operations:

```bash
# ECS
ecs-clusters                                  # List clusters
ecs-services <cluster>                        # List services
ecs-metrics <cluster> <service> all -120M -0S 60  # Get metrics

# S3
s3-buckets                                    # List buckets
s3-cat <bucket> <key>                         # View file
s3-dl <bucket> <key> [local_path]            # Download

# SSM
ssm-params <name_filter>                      # List parameters
ssm-get-param <name>                          # Get value
```

See `sources/general/aws.sh` for the complete list.

## Docker Helpers

All destructive operations include safety confirmations:

```bash
docker-stop-all          # Stop all containers
docker-rm-all-containers # Remove all containers (with confirmation)
docker-rm-all-images     # Remove all images (with confirmation)
docker-ips               # Show container IP addresses
```

## SSH Key Generation

Modern, secure key generation:

```bash
ssh-keygen-ed25519 "email@example.com"  # RECOMMENDED
ssh-keygen-rsa "email@example.com"       # 4096-bit RSA
ssh-keygen-ecdsa "email@example.com"     # ECDSA 521-bit
# ssh-keygen-dsa is deprecated (shows error)
```

## Platform Compatibility

### macOS
- ✅ ARM Macs (M1/M2/M3) - `/opt/homebrew`
- ✅ Intel Macs - `/usr/local`
- Auto-detects architecture and adjusts paths

### Linux
- ✅ Ubuntu/Debian
- ✅ Fedora/RHEL
- Includes Linux-specific utilities in `sources/general/linux.sh`

## Git Configuration

Includes conditional configurations for different projects:

```gitconfig
[includeIf "gitdir:~/workspace/acme/"]
    path = ~/.dotfiles/git/workspace/acme/.acme.gitconfig

[includeIf "gitdir:~/workspace/techcorp/"]
    path = ~/.dotfiles/git/workspace/techcorp/.techcorp.gitconfig
```

Each workspace can have its own email, signing key, etc.

## xbar Plugins

Menu bar utilities (macOS only):

- **worldclock.30s.sh**: World clock with multiple timezones
- **mmi.5m.sh**: Market Mood Index tracker
- **toolbox.12h.sh**: Developer utilities (UUID, hash generators, etc.)
- **totp.20s.sh**: TOTP/2FA token generator

## Maintenance

### Update Homebrew packages
```bash
brew update
brew upgrade
brew bundle dump --file=brew/.Brewfile --force  # Update Brewfile
```

### Update Oh My Zsh
```bash
omz update
```

### Validate shell scripts

Pre-commit hooks are configured to automatically check scripts before commits:

```bash
# Hooks are installed automatically after cloning
# They run on git commit

# Manually run all hooks on all files
pre-commit run --all-files

# Run only shellcheck
pre-commit run shellcheck --all-files

# Skip hooks for a specific commit (not recommended)
git commit --no-verify
```

You can also manually check scripts:
```bash
# Install shellcheck (already in Brewfile)
brew install shellcheck

# Check all scripts
shellcheck sources/general/*.sh

# Check specific script
shellcheck sources/general/dev.sh
```

## Troubleshooting

### "command not found" after installation
```bash
# Make sure you've deployed with stow
cd ~/.dotfiles
stow zsh

# Reload shell
exec $SHELL -l
```

### NVM not loading
```bash
# Ensure NVM is installed via Homebrew
brew install nvm

# Reload shell
refreSH
```

### AWS functions not working
```bash
# Install AWS CLI
brew install awscli

# Configure AWS
aws configure sso
```

## Security Notes

⚠️ **Security Best Practices**:

1. **Never commit** `.aws/credentials` or SSH private keys (gitignored by default)
2. **Rotate credentials** if accidentally exposed
3. **Use `pass`** for credential management instead of plain environment variables
4. **Avoid** `set-sudo-wo-pwd` on production/shared systems
5. **Review** permissions before running scripts with elevated privileges

## For AI Assistants

If you're Claude or another AI assistant working on this repository, please read **[CLAUDE.md](CLAUDE.md)** for:
- Project structure and philosophy
- Guidelines for using official documentation
- Configuration best practices
- Common pitfalls to avoid
- Workflow and commit standards

## Contributing

This is a personal dotfiles repository, but feel free to:
- Fork it and adapt for your own use
- Report issues or security concerns
- Suggest improvements via issues

## License

MIT License - Feel free to use and modify as needed.

## Acknowledgments

- [GNU Stow](https://www.gnu.org/software/stow/) for dotfile management
- [Oh My Zsh](https://ohmyz.sh/) for Zsh framework
- [Homebrew](https://brew.sh/) for package management
- Community dotfiles repos for inspiration
