#!/usr/bin/env bash
# Tools — uninstaller
# Removes symlinks created by install.sh and restores backups where available.
# Does NOT uninstall CLI tools (bat, delta, eza, etc.) or NVM.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/setup/helpers.sh"

REMOVED=0
RESTORED=0
SKIPPED=0

# Remove a symlink only if it points into this repo.
# Restores .bak file if one exists.
remove_symlink() {
    local dest="$1"
    if [ -L "$dest" ]; then
        local target
        target="$(readlink "$dest")"
        # Check that the symlink target lives inside this repo
        case "$target" in
            "$SCRIPT_DIR"/*|"$HOME/.tmux/.tmux.conf")
                rm "$dest"
                echo "  Removed $dest"
                REMOVED=$((REMOVED + 1))
                # Restore backup if available
                if [ -f "${dest}.bak" ]; then
                    mv "${dest}.bak" "$dest"
                    echo "  Restored $(basename "$dest") from backup"
                    RESTORED=$((RESTORED + 1))
                fi
                ;;
            *)
                warn "Skipping $dest — points outside this repo ($target)"
                SKIPPED=$((SKIPPED + 1))
                ;;
        esac
    fi
}

echo "========================================="
echo "  Tools — Uninstaller"
echo "========================================="
echo ""
echo "  Repo: $SCRIPT_DIR"
echo ""

# -- 1. Shell config symlinks ------------------------------------------------

step "Removing shell config symlinks..."

remove_symlink "$HOME/.bashrc"
remove_symlink "$HOME/.zshrc"
remove_symlink "$HOME/.config/starship.toml"
remove_symlink "$HOME/.config/bat/env"

# -- 2. Shell scripts in ~/.local/bin ----------------------------------------

step "Removing shell scripts from ~/.local/bin..."

if [ -d "$SCRIPT_DIR/Shell/scripts" ]; then
    for script in "$SCRIPT_DIR/Shell/scripts/"*; do
        [ -f "$script" ] || continue
        remove_symlink "$HOME/.local/bin/$(basename "$script")"
    done
fi

# -- 3. Git delta include ----------------------------------------------------

step "Removing delta.gitconfig include from ~/.gitconfig..."

if [ -f "$HOME/.gitconfig" ] && grep -q 'delta.gitconfig' "$HOME/.gitconfig"; then
    # Remove the [include] block that references delta.gitconfig
    sed -i '/^\[include\]/{N;/delta\.gitconfig/d;}' "$HOME/.gitconfig"
    # Clean up any trailing blank lines left behind
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$HOME/.gitconfig"
    echo "  Removed [include] for delta.gitconfig"
    REMOVED=$((REMOVED + 1))
else
    echo "  No delta.gitconfig include found — skipping"
fi

# -- 4. Tmux config symlinks -------------------------------------------------

step "Removing tmux config symlinks..."

remove_symlink "$HOME/.tmux.conf"
remove_symlink "$HOME/.tmux.conf.local"

# -- 5. Tmux themes directory symlink ----------------------------------------

step "Removing tmux themes symlink..."

if [ -L "$HOME/.tmux/themes" ]; then
    local_target="$(readlink "$HOME/.tmux/themes")"
    case "$local_target" in
        "$SCRIPT_DIR"/*)
            rm "$HOME/.tmux/themes"
            echo "  Removed ~/.tmux/themes"
            REMOVED=$((REMOVED + 1))
            ;;
        *)
            warn "Skipping ~/.tmux/themes — points outside this repo"
            SKIPPED=$((SKIPPED + 1))
            ;;
    esac
fi

# -- 6. Tmux scripts in ~/.local/bin -----------------------------------------

step "Removing tmux scripts from ~/.local/bin..."

if [ -d "$SCRIPT_DIR/Tmux/scripts" ]; then
    for script in "$SCRIPT_DIR/Tmux/scripts/"*; do
        [ -f "$script" ] || continue
        remove_symlink "$HOME/.local/bin/$(basename "$script")"
    done
fi

# -- 7. Summary ---------------------------------------------------------------

echo ""
echo "========================================="
echo "  Uninstall complete"
echo "  Symlinks removed:  $REMOVED"
echo "  Backups restored:  $RESTORED"
echo "  Skipped:           $SKIPPED"
echo "========================================="
echo ""
echo "  Not removed (manual cleanup if desired):"
echo "    ~/.tmux/          — gpakosz/.tmux framework"
echo "    ~/.tmux-context/  — tmux context data"
echo "    ~/.nvm/           — Node Version Manager"
echo "    CLI tools         — bat, delta, eza, fd, rg, fzf, zoxide, starship"
echo ""
echo "  This repo ($SCRIPT_DIR) is still intact."
echo "  You can re-run install.sh at any time to set things up again."
echo ""
