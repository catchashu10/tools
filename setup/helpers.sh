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

# Download a binary from GitHub releases and install to ~/.local/bin
# Usage: install_github_binary "owner/repo" "binary_name"
install_github_binary() {
    local repo="$1" binary="$2"
    local arch
    arch="$(uname -m)"

    local url
    url=$(curl -sL "https://api.github.com/repos/$repo/releases/latest" \
        | grep "browser_download_url" \
        | grep -i "${arch}.*linux" \
        | grep "\.tar\.gz" \
        | grep -v "musl\|\.sha\|\.md5\|\.sig" \
        | head -1 \
        | cut -d'"' -f4)

    if [ -z "$url" ]; then
        warn "No matching release found for $repo ($arch)"
        return 1
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    echo "  Downloading $binary from GitHub..."

    if curl -sL "$url" -o "$tmpdir/archive.tar.gz"; then
        tar xzf "$tmpdir/archive.tar.gz" -C "$tmpdir"
        local bin
        bin=$(find "$tmpdir" -name "$binary" -type f | head -1)
        if [ -n "$bin" ]; then
            chmod +x "$bin"
            mkdir -p "$HOME/.local/bin"
            mv "$bin" "$HOME/.local/bin/$binary"
            echo "  $binary installed to ~/.local/bin/"
            rm -rf "$tmpdir"
            return 0
        fi
    fi

    rm -rf "$tmpdir"
    warn "Failed to install $binary from GitHub"
    return 1
}
