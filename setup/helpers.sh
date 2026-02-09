#!/usr/bin/env bash
# Shared helper functions for Tools installers
# Source this from any install.sh:
#   source "$(dirname "$0")/../setup/helpers.sh"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

symlink_config() {
    local src="$1" dest="$2"
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        warn "Backing up existing $(basename "$dest") → $(basename "$dest").bak"
        cp "$dest" "${dest}.bak"
    fi
    ln -s -f "$src" "$dest"
    echo "  $dest → $src"
}

install_pkg() {
    if command -v apt >/dev/null 2>&1; then
        sudo apt install -y "$@"
    elif command -v brew >/dev/null 2>&1; then
        brew install "$@"
    else
        warn "No supported package manager (apt/brew). Install manually: $*"
        return 1
    fi
}
