#!/usr/bin/env bash
# Shell setup installer (symlink mode)
# Usage: git clone <repo> ~/Tools && ~/Tools/Shell/install.sh
#
# Installs CLI tools, symlinks shell configs into place.
# The repo folder must remain in place — it IS your config.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup/helpers.sh"

echo "=== Shell Setup Installer ==="
echo ""

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
    FAILED_PACKAGES=()
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        for pkg in "${APT_PACKAGES[@]}"; do
            if sudo apt install -y "$pkg" 2>/dev/null; then
                echo "  $pkg installed"
            else
                FAILED_PACKAGES+=("$pkg")
                warn "$pkg not available in apt repos — skipping"
            fi
        done
    elif command -v brew >/dev/null 2>&1; then
        for pkg in "${APT_PACKAGES[@]}"; do
            if brew install "$pkg" 2>/dev/null; then
                echo "  $pkg installed"
            else
                FAILED_PACKAGES+=("$pkg")
                warn "$pkg not available — skipping"
            fi
        done
    else
        FAILED_PACKAGES=("${APT_PACKAGES[@]}")
        warn "No package manager found. Install manually: ${APT_PACKAGES[*]}"
    fi
    # Fallback: try GitHub releases for packages not in apt/brew
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        step "Trying GitHub releases for: ${FAILED_PACKAGES[*]}..."
        STILL_FAILED=()
        for pkg in "${FAILED_PACKAGES[@]}"; do
            case "$pkg" in
                eza)       install_github_binary "eza-community/eza" "eza" || STILL_FAILED+=("$pkg") ;;
                git-delta) install_github_binary "dandavison/delta" "delta" || STILL_FAILED+=("$pkg") ;;
                *)         STILL_FAILED+=("$pkg") ;;
            esac
        done
        if [ ${#STILL_FAILED[@]} -gt 0 ]; then
            echo ""
            warn "Could not install: ${STILL_FAILED[*]}"
        fi
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
mkdir -p "$HOME/.config" "$HOME/.config/bat"

symlink_config "$SCRIPT_DIR/config/bashrc"        "$HOME/.bashrc"
symlink_config "$SCRIPT_DIR/config/zshrc"          "$HOME/.zshrc"
symlink_config "$SCRIPT_DIR/config/starship.toml"  "$HOME/.config/starship.toml"
symlink_config "$SCRIPT_DIR/config/bat-env"        "$HOME/.config/bat/env"

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

# -- 7. git delta config -----------------------------------------------------

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

# -- 8. ensure ~/.local/bin in PATH ------------------------------------------

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
