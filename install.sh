#!/usr/bin/env bash
# Tools — master installer
#
# Purpose:
#   Run one or more tool-specific installers from this repo.
#
# Usage:
#   ./install.sh             # install every tool in the default order
#   ./install.sh Shell       # install only Shell
#   ./install.sh Nvim Tmux   # install only Nvim and Tmux, in that order
#
# Portability:
#   This script resolves the repo path from its own location. The repo can be
#   cloned under any folder name; do not hardcode the top-level folder name.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Default install order. Shell goes first because it prepares common CLI tools
# and PATH conventions used by other tool setups.
DEFAULT_TOOLS=(Shell Nvim Tmux)

usage() {
    echo "Usage: $0 [tool ...]"
    echo ""
    echo "Available tools:"
    for tool in "${DEFAULT_TOOLS[@]}"; do
        echo "  $tool"
    done
}

run_tool_installer() {
    local tool="$1"
    local installer="$SCRIPT_DIR/$tool/install.sh"

    if [ ! -x "$installer" ]; then
        echo "ERROR: installer not found or not executable: $installer" >&2
        exit 1
    fi

    echo "--- $tool Setup ---"
    "$installer"
    echo ""
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

TOOLS_TO_INSTALL=("${@:-}")
if [ "$#" -eq 0 ]; then
    TOOLS_TO_INSTALL=("${DEFAULT_TOOLS[@]}")
fi

echo "========================================="
echo "  Tools — Setup"
echo "========================================="
echo ""
echo "  Repo: $SCRIPT_DIR"
echo "  Tools: ${TOOLS_TO_INSTALL[*]}"
echo ""

for tool in "${TOOLS_TO_INSTALL[@]}"; do
    run_tool_installer "$tool"
done

echo "========================================="
echo "  Requested tools installed!"
echo "  Restart your shell to pick up changes."
echo "========================================="
