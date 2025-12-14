# Python Development Tools

Python linters, formatters, and development tools managed via pip.

## Quick Start

```bash
# Install all tools
./install.sh

# Or manually
pip3 install --user -r requirements.txt
```

## Included Tools

### Linting & Quality
- **pylint** - Comprehensive Python linter (used by nvim)
- **flake8** - Style guide enforcement (PEP 8)
- **bandit** - Security vulnerability scanner
- **pydocstyle** - Docstring style checker

### Formatting
- **black** - Opinionated code formatter
- **isort** - Import statement organizer

### Type Checking
- **mypy** - Static type checker

### Other
- **yamllint** - YAML linter (also available via brew)

## Neovim Integration

The nvim configuration uses **pylint** for Python linting.
See: `nvim/.config/nvim/lua/plugins/lint.lua`

## Updating

Update all tools to latest versions:

```bash
pip3 install --user --upgrade -r requirements.txt
```

## Version Management

Lock current versions:

```bash
pip3 freeze --user | grep -f <(cut -d'=' -f1 requirements.txt) > requirements.txt
```

## Per-Project Tools

For project-specific tools, use virtual environments:

```bash
# Create venv
python3 -m venv .venv
source .venv/bin/activate

# Install project tools
pip install pylint black mypy
```
