#!/usr/bin/env bash
# Tmux setup uninstaller
#
# Purpose:
#   Remove Tmux-owned symlinks created by Tmux/install.sh.
#
# Safety:
#   This script removes only symlinks that point to this Tmux folder or to the
#   gpakosz ~/.tmux framework file used by this setup. It does not uninstall
#   tmux, delete ~/.tmux, delete ~/.tmux-context, or delete this repo.
#
# Portability:
#   Paths are resolved relative to this script so the repo can be cloned under
#   any top-level folder name.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup/helpers.sh"

REMOVED=0
RESTORED=0
SKIPPED=0

remove_owned_symlink() {
    local dest="$1"

    if [ ! -L "$dest" ]; then
        echo "  No owned symlink at $dest — skipping"
        return 0
    fi

    local target
    target="$(readlink "$dest")"

    case "$target" in
        "$SCRIPT_DIR"/*|"$HOME/.tmux/.tmux.conf")
            rm "$dest"
            echo "  Removed $dest"
            REMOVED=$((REMOVED + 1))

            if [ -f "${dest}.bak" ]; then
                mv "${dest}.bak" "$dest"
                echo "  Restored $dest from ${dest}.bak"
                RESTORED=$((RESTORED + 1))
            fi
            ;;
        *)
            warn "Skipping $dest — points outside this Tmux setup ($target)"
            SKIPPED=$((SKIPPED + 1))
            ;;
    esac
}

echo "=== Tmux Setup Uninstaller ==="
echo ""
echo "  Tmux folder: $SCRIPT_DIR"
echo ""

step "Removing tmux config symlinks..."
remove_owned_symlink "$HOME/.tmux.conf"
remove_owned_symlink "$HOME/.tmux.conf.local"

step "Removing tmux themes symlink..."
remove_owned_symlink "$HOME/.tmux/themes"

step "Removing tmux scripts from ~/.local/bin..."
if [ -d "$SCRIPT_DIR/scripts" ]; then
    for script in "$SCRIPT_DIR/scripts/"*; do
        [ -f "$script" ] || continue
        remove_owned_symlink "$HOME/.local/bin/$(basename "$script")"
    done
else
    echo "  No scripts directory found — skipping"
fi

echo ""
step "Tmux uninstall complete"
echo "  Symlinks removed: $REMOVED"
echo "  Backups restored: $RESTORED"
echo "  Skipped:          $SKIPPED"
echo ""
echo "  Not removed: tmux package, ~/.tmux, ~/.tmux-context, or this repo."
