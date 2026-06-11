#!/usr/bin/env bash
# Tools — master uninstaller
#
# Purpose:
#   Run one or more tool-specific uninstallers from this repo.
#
# Usage:
#   ./uninstall.sh             # uninstall every tool in reverse default order
#   ./uninstall.sh Nvim        # uninstall only Nvim
#   ./uninstall.sh Tmux Shell  # uninstall only Tmux and Shell, in that order
#
# Safety:
#   Tool uninstallers should remove only symlinks/config entries they own. They
#   should not delete package-manager-installed programs or this repo.
#
# Portability:
#   This script resolves the repo path from its own location. The repo can be
#   cloned under any folder name; do not hardcode the top-level folder name.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Reverse of install order is safest for a full uninstall: remove tools that
# depend on Shell conventions before removing Shell's symlinks.
DEFAULT_TOOLS=(Tmux Nvim Shell)

usage() {
    echo "Usage: $0 [tool ...]"
    echo ""
    echo "Available tools:"
    for tool in "${DEFAULT_TOOLS[@]}"; do
        echo "  $tool"
    done
}

run_tool_uninstaller() {
    local tool="$1"
    local uninstaller="$SCRIPT_DIR/$tool/uninstall.sh"

    if [ ! -x "$uninstaller" ]; then
        echo "ERROR: uninstaller not found or not executable: $uninstaller" >&2
        exit 1
    fi

    echo "--- $tool Uninstall ---"
    "$uninstaller"
    echo ""
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

TOOLS_TO_UNINSTALL=("${@:-}")
if [ "$#" -eq 0 ]; then
    TOOLS_TO_UNINSTALL=("${DEFAULT_TOOLS[@]}")
fi

echo "========================================="
echo "  Tools — Uninstall"
echo "========================================="
echo ""
echo "  Repo: $SCRIPT_DIR"
echo "  Tools: ${TOOLS_TO_UNINSTALL[*]}"
echo ""

for tool in "${TOOLS_TO_UNINSTALL[@]}"; do
    run_tool_uninstaller "$tool"
done

echo "========================================="
echo "  Requested tools uninstalled!"
echo "========================================="
echo ""
echo "  This repo is still intact:"
echo "    $SCRIPT_DIR"
echo ""
