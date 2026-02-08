#!/usr/bin/env bash
# Tools — master installer
# Usage: git clone <repo> ~/Tools && ~/Tools/install.sh
#
# Runs all tool installers in order.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================="
echo "  Tools — Full Setup"
echo "========================================="
echo ""

# 1. Shell first — installs CLI tools, symlinks shell configs
echo "--- Shell Setup ---"
"$SCRIPT_DIR/Shell/install.sh"
echo ""

# 2. Tmux second — needs shell configs in place for PATH
echo "--- Tmux Setup ---"
"$SCRIPT_DIR/Tmux/install.sh"
echo ""

echo "========================================="
echo "  All tools installed!"
echo "  Restart your shell to pick up changes."
echo "========================================="
