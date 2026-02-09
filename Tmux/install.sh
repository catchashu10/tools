#!/usr/bin/env bash
# Tmux setup installer (symlink mode)
# Usage: git clone <repo> ~/Tools && ~/Tools/Tmux/install.sh
#
# Creates symlinks from dotfile locations to this repo.
# The repo folder must remain in place — it IS your config.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup/helpers.sh"

echo "=== Tmux Setup Installer ==="
echo ""

# 1. Check / install tmux
step "Checking dependencies..."
if ! command -v tmux >/dev/null 2>&1; then
    warn "tmux not found. Installing..."
    install_pkg tmux
fi
echo "  tmux $(tmux -V | cut -d' ' -f2) found"

# 2. Install gpakosz/.tmux framework
if [ -d "$HOME/.tmux/.git" ]; then
    step "gpakosz/.tmux already installed, updating..."
    cd "$HOME/.tmux" && git pull && cd -
else
    step "Installing gpakosz/.tmux framework..."
    git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
fi
ln -s -f "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"

# 3. Symlink config
step "Linking tmux config..."
symlink_config "$SCRIPT_DIR/config/tmux.conf.local" "$HOME/.tmux.conf.local"

# 4. Symlink themes
step "Linking themes..."
if [ -d "$HOME/.tmux/themes" ] && [ ! -L "$HOME/.tmux/themes" ]; then
    rm -rf "$HOME/.tmux/themes"
fi
ln -s -f -n "$SCRIPT_DIR/themes" "$HOME/.tmux/themes"
echo "  ~/.tmux/themes → $SCRIPT_DIR/themes/"
echo "  Themes: $(ls "$SCRIPT_DIR/themes/" | sed 's/.conf//g' | tr '\n' ' ')"

# 5. Symlink scripts
step "Linking scripts..."
mkdir -p "$HOME/.local/bin"
for script in "$SCRIPT_DIR/scripts/"*; do
    name=$(basename "$script")
    chmod +x "$script"
    ln -s -f "$script" "$HOME/.local/bin/$name"
    echo "  ~/.local/bin/$name → $script"
done

# 6. Check PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    warn "~/.local/bin not in PATH. Adding to shell rc..."
    SHELL_RC="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "  Added to $SHELL_RC"
fi

# 7. Create directories
mkdir -p "$HOME/.tmux-context"

# 8. Install clipboard tool (Linux only — macOS has pbcopy built in)
if [ "$(uname)" != "Darwin" ]; then
    if ! command -v xsel >/dev/null 2>&1 && ! command -v xclip >/dev/null 2>&1; then
        if command -v apt >/dev/null 2>&1; then
            step "Installing xsel for clipboard support..."
            sudo apt install -y xsel 2>/dev/null || warn "Could not install xsel"
        fi
    fi
fi

echo ""
step "Installation complete!"
echo ""
echo "  All config files are symlinked to this repo."
echo "  Edit anywhere — changes reflect everywhere."
echo "  DO NOT delete this folder ($SCRIPT_DIR)."
echo ""
echo "  Next steps:"
echo "  1. Start tmux:        tmux new -s main"
echo "  2. Install plugins:   Ctrl-a I  (wait for it to finish)"
echo "  3. Switch theme:      Ctrl-a T"
echo "  4. Toggle scroll:     Ctrl-a S  (natural/normal)"
echo ""
echo "  Prefix: Ctrl-a (primary), Ctrl-Space (secondary)"
