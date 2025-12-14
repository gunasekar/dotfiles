#!/usr/bin/env bash
# Install Python development tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Python development tools..."
python3 -m pip install --user -r "$SCRIPT_DIR/requirements.txt"

echo "✓ Python tools installed successfully"
