#!/usr/bin/env bash
# Shell setup installer (symlink mode)
# Usage: git clone <repo> ~/Tools && ~/Tools/Shell/install.sh
#
# Installs CLI tools, symlinks shell configs into place.
# The repo folder must remain in place — it IS your config.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

echo "=== Shell Setup Installer ==="
echo ""

# -- detect package manager --------------------------------------------------

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

# -- 1. install zsh ----------------------------------------------------------

step "Checking zsh..."
if command -v zsh >/dev/null 2>&1; then
    echo "  zsh $(zsh --version | cut -d' ' -f2) found"
else
    warn "zsh not found. Installing..."
    install_pkg zsh
fi

# -- 2. install CLI tools -----------------------------------------------------

step "Checking CLI tools..."

APT_PACKAGES=()

check_tool() {
    local name="$1" cmd="$2" pkg="$3"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  $name found"
    else
        echo "  $name not found — queuing install"
        APT_PACKAGES+=("$pkg")
    fi
}

check_tool "bat"     "batcat" "bat"
check_tool "delta"   "delta"  "git-delta"
check_tool "eza"     "eza"    "eza"
check_tool "fd"      "fdfind" "fd-find"
check_tool "ripgrep" "rg"     "ripgrep"
check_tool "fzf"     "fzf"    "fzf"
check_tool "zoxide"  "zoxide" "zoxide"

if [ ${#APT_PACKAGES[@]} -gt 0 ]; then
    step "Installing: ${APT_PACKAGES[*]}..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y "${APT_PACKAGES[@]}"
    elif command -v brew >/dev/null 2>&1; then
        brew install "${APT_PACKAGES[@]}"
    else
        warn "Cannot install packages. Install manually: ${APT_PACKAGES[*]}"
    fi
else
    echo "  All CLI tools already installed"
fi

# -- 3. install starship -----------------------------------------------------

step "Checking starship..."
if command -v starship >/dev/null 2>&1; then
    echo "  starship $(starship --version | head -1 | awk '{print $2}') found"
else
    warn "starship not found. Installing to ~/.local/bin/..."
    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$HOME/.local/bin" -y
fi

# -- 4. install NVM ----------------------------------------------------------

step "Checking NVM..."
if [ -d "$HOME/.nvm" ]; then
    echo "  NVM found at ~/.nvm"
else
    warn "NVM not found. Installing..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    echo "  NVM installed — restart shell to use"
fi

# -- 5. symlink configs ------------------------------------------------------

step "Linking shell configs..."
mkdir -p "$HOME/.config"

symlink_config() {
    local src="$1" dest="$2"
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        warn "Backing up existing $(basename "$dest") → $(basename "$dest").bak"
        cp "$dest" "${dest}.bak"
    fi
    ln -s -f "$src" "$dest"
    echo "  $dest → $src"
}

symlink_config "$SCRIPT_DIR/config/bashrc"        "$HOME/.bashrc"
symlink_config "$SCRIPT_DIR/config/zshrc"          "$HOME/.zshrc"
symlink_config "$SCRIPT_DIR/config/starship.toml"  "$HOME/.config/starship.toml"

# -- 6. symlink scripts to ~/.local/bin --------------------------------------

step "Linking scripts..."
mkdir -p "$HOME/.local/bin"

if [ -d "$SCRIPT_DIR/scripts" ]; then
    for script in "$SCRIPT_DIR/scripts/"*; do
        [ -f "$script" ] || continue
        chmod +x "$script"
        ln -s -f "$script" "$HOME/.local/bin/$(basename "$script")"
        echo "  ~/.local/bin/$(basename "$script") → $script"
    done
else
    echo "  No scripts directory found — skipping"
fi

# -- 7. bat theme env --------------------------------------------------------

step "Checking bat theme..."
BAT_ENV="$HOME/.config/bat/env"
if [ -f "$BAT_ENV" ]; then
    echo "  $BAT_ENV already exists"
else
    mkdir -p "$(dirname "$BAT_ENV")"
    echo 'export BAT_THEME="base16"' > "$BAT_ENV"
    echo "  Created $BAT_ENV (default: base16)"
fi

# -- 8. git delta config -----------------------------------------------------

step "Checking git delta config..."
if grep -q 'delta.gitconfig' "$HOME/.gitconfig" 2>/dev/null; then
    echo "  delta.gitconfig already included in ~/.gitconfig"
else
    if [ -f "$HOME/.gitconfig" ]; then
        echo "" >> "$HOME/.gitconfig"
    fi
    cat >> "$HOME/.gitconfig" <<'GITEOF'
[include]
	path = ~/Tools/Shell/config/delta.gitconfig
GITEOF
    echo "  Added [include] for delta.gitconfig to ~/.gitconfig"
fi

# -- 9. ensure ~/.local/bin in PATH ------------------------------------------

step "Checking PATH..."
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo "  ~/.local/bin already in PATH"
else
    warn "~/.local/bin not in PATH — it will be after shell restart (set in bashrc/zshrc)"
fi

echo ""
step "Installation complete!"
echo ""
echo "  Shell configs are symlinked to this repo."
echo "  Edit anywhere — changes reflect everywhere."
echo "  DO NOT delete this folder ($SCRIPT_DIR)."
echo ""
echo "  Installed tools:"
echo "    bat (batcat)  — syntax-highlighted cat"
echo "    delta         — beautiful side-by-side git diffs"
echo "    eza           — modern ls with icons"
echo "    fd (fdfind)   — fast file finder"
echo "    ripgrep (rg)  — fast grep"
echo "    fzf           — fuzzy finder (Ctrl-R, Ctrl-T, Alt-C)"
echo "    zoxide (z)    — smarter cd"
echo "    starship      — cross-shell prompt"
echo ""
echo "  Next steps:"
echo "    1. Restart your shell (or: source ~/.bashrc)"
echo "    2. Install Node.js: nvm install --lts"
echo ""
