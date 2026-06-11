#!/usr/bin/env bash
# Nvim setup uninstaller
# Removes ~/.config/nvim only when it points into this repo's Nvim folder.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup/helpers.sh"

NVIM_CONFIG_DIR="$HOME/.config/nvim"

echo "=== Nvim Setup Uninstaller ==="
echo ""

if [ ! -L "$NVIM_CONFIG_DIR" ]; then
    warn "$NVIM_CONFIG_DIR is not a symlink. Not touching it."
    exit 0
fi

current_target="$(readlink "$NVIM_CONFIG_DIR")"

case "$current_target" in
    "$SCRIPT_DIR"/*)
        rm "$NVIM_CONFIG_DIR"
        echo "  Removed $NVIM_CONFIG_DIR"
        echo ""
        echo "  Your Nvim configs are still intact under:"
        echo "    $SCRIPT_DIR"
        ;;
    *)
        warn "Refusing to remove symlink pointing outside this repo:"
        echo "  $NVIM_CONFIG_DIR -> $current_target"
        exit 1
        ;;
esac
