#!/usr/bin/env bash
# Nvim setup installer
# Usage:
#   ./install.sh
#   ./install.sh lazyNvim
#   ./install.sh lazyNvim --force-clean
#
# Creates ~/.config/nvim as a symlink to one Nvim flavor in this repo.
# The repo folder can be named anything and live anywhere.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup/helpers.sh"

FLAVOR="${1:-lazyNvim}"
FORCE_CLEAN="${2:-}"

NVIM_FLAVOR_DIR="$SCRIPT_DIR/$FLAVOR"
NVIM_CONFIG_DIR="$HOME/.config/nvim"

backup_or_remove() {
    local path="$1"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"

    if [ -e "$path" ] || [ -L "$path" ]; then
        if [ "$FORCE_CLEAN" = "--force-clean" ]; then
            warn "Removing existing $path"
            rm -rf "$path"
        else
            warn "Backing up existing $path"
            mv "$path" "$path.bak.$timestamp"
            echo "  $path -> $path.bak.$timestamp"
        fi
    fi
}

if [ -n "$FORCE_CLEAN" ] && [ "$FORCE_CLEAN" != "--force-clean" ]; then
    warn "Unknown option: $FORCE_CLEAN"
    echo "Usage: $0 [flavor] [--force-clean]"
    exit 1
fi

echo "=== Nvim Setup Installer ==="
echo ""
echo "  Flavor: $FLAVOR"
echo "  Source: $NVIM_FLAVOR_DIR"
echo "  Target: $NVIM_CONFIG_DIR"
echo ""

if [ ! -d "$NVIM_FLAVOR_DIR" ]; then
    warn "Nvim flavor not found: $NVIM_FLAVOR_DIR"
    echo ""
    echo "Available flavors:"
    find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d -printf "  %f\n" | sort
    exit 1
fi

step "Checking dependencies..."

if ! command -v nvim >/dev/null 2>&1; then
    warn "nvim not found. Installing..."
    install_pkg neovim
fi

if ! command -v git >/dev/null 2>&1; then
    warn "git not found. Installing..."
    install_pkg git
fi

if ! command -v rg >/dev/null 2>&1; then
    warn "ripgrep not found. Installing..."
    install_pkg ripgrep
fi

if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
    warn "fd not found. Installing..."
    install_pkg fd-find || install_pkg fd
fi

step "Preparing clean Neovim runtime directories..."
backup_or_remove "$HOME/.local/share/nvim"
backup_or_remove "$HOME/.local/state/nvim"
backup_or_remove "$HOME/.cache/nvim"

step "Linking Neovim config..."
mkdir -p "$HOME/.config"

if [ -L "$NVIM_CONFIG_DIR" ]; then
    current_target="$(readlink "$NVIM_CONFIG_DIR")"
    if [ "$current_target" = "$NVIM_FLAVOR_DIR" ]; then
        echo "  Already linked: $NVIM_CONFIG_DIR -> $NVIM_FLAVOR_DIR"
    else
        backup_or_remove "$NVIM_CONFIG_DIR"
        ln -s "$NVIM_FLAVOR_DIR" "$NVIM_CONFIG_DIR"
        echo "  $NVIM_CONFIG_DIR -> $NVIM_FLAVOR_DIR"
    fi
elif [ -e "$NVIM_CONFIG_DIR" ]; then
    backup_or_remove "$NVIM_CONFIG_DIR"
    ln -s "$NVIM_FLAVOR_DIR" "$NVIM_CONFIG_DIR"
    echo "  $NVIM_CONFIG_DIR -> $NVIM_FLAVOR_DIR"
else
    ln -s "$NVIM_FLAVOR_DIR" "$NVIM_CONFIG_DIR"
    echo "  $NVIM_CONFIG_DIR -> $NVIM_FLAVOR_DIR"
fi

echo ""
step "Installation complete!"
echo ""
echo "  Start Neovim:"
echo "    nvim"
echo ""
echo "  Then run inside Neovim:"
echo "    :LazyHealth"
echo ""
