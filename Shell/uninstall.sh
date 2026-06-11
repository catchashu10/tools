#!/usr/bin/env bash
# Shell setup uninstaller
#
# Purpose:
#   Remove Shell-owned symlinks and the git-delta include that Shell/install.sh
#   adds to ~/.gitconfig. ~/.bashrc and ~/.zshrc are installed as local copies,
#   so regular copied rc files are left in place during uninstall.
#
# Safety:
#   This script removes only symlinks that point back into this Shell folder. If
#   an older install left ~/.bashrc or ~/.zshrc as owned symlinks, removing those
#   symlinks can restore a matching .bak file. Regular copied rc files are not
#   deleted or restored automatically.
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
        "$SCRIPT_DIR"/*)
            rm "$dest"
            echo "  Removed $dest"
            REMOVED=$((REMOVED + 1))

            # symlink_config backs up existing files as <dest>.bak. Restore that
            # backup if it exists after removing our symlink.
            if [ -f "${dest}.bak" ]; then
                mv "${dest}.bak" "$dest"
                echo "  Restored $dest from ${dest}.bak"
                RESTORED=$((RESTORED + 1))
            fi
            ;;
        *)
            warn "Skipping $dest — points outside this Shell folder ($target)"
            SKIPPED=$((SKIPPED + 1))
            ;;
    esac
}

note_local_copy() {
    local dest="$1"

    if [ -L "$dest" ]; then
        remove_owned_symlink "$dest"
    elif [ -e "$dest" ]; then
        echo "  $dest is a regular local file — leaving it in place"
        echo "  Backups, if any, remain beside it as $dest.bak.*"
    else
        echo "  $dest not found — skipping"
    fi
}

remove_delta_include() {
    local gitconfig="$HOME/.gitconfig"

    if [ ! -f "$gitconfig" ]; then
        echo "  No ~/.gitconfig found — skipping"
        return 0
    fi

    if ! grep -q 'delta.gitconfig' "$gitconfig"; then
        echo "  No delta.gitconfig include found — skipping"
        return 0
    fi

    # Remove any [include] block that references delta.gitconfig. This handles
    # both old hardcoded entries and the current repo-relative installer output.
    python3 - "$gitconfig" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = path.read_text().splitlines(keepends=True)
out = []
i = 0
removed = False

while i < len(lines):
    if lines[i].strip() == "[include]":
        block = [lines[i]]
        i += 1
        while i < len(lines) and not lines[i].lstrip().startswith("["):
            block.append(lines[i])
            i += 1
        if any("delta.gitconfig" in line for line in block):
            removed = True
            continue
        out.extend(block)
    else:
        out.append(lines[i])
        i += 1

path.write_text("".join(out).rstrip() + "\n")
print("removed" if removed else "not-found")
PY
    echo "  Removed delta.gitconfig include from ~/.gitconfig"
    REMOVED=$((REMOVED + 1))
}

echo "=== Shell Setup Uninstaller ==="
echo ""
echo "  Shell folder: $SCRIPT_DIR"
echo ""

step "Handling machine-local shell rc files..."
note_local_copy "$HOME/.bashrc"
note_local_copy "$HOME/.zshrc"

step "Removing Shell-owned config symlinks..."
remove_owned_symlink "$HOME/.config/starship.toml"
remove_owned_symlink "$HOME/.config/bat/env"

step "Removing shell scripts from ~/.local/bin..."
if [ -d "$SCRIPT_DIR/scripts" ]; then
    for script in "$SCRIPT_DIR/scripts/"*; do
        [ -f "$script" ] || continue
        remove_owned_symlink "$HOME/.local/bin/$(basename "$script")"
    done
else
    echo "  No scripts directory found — skipping"
fi

step "Removing git delta include..."
remove_delta_include

echo ""
step "Shell uninstall complete"
echo "  Symlinks/config entries removed: $REMOVED"
echo "  Backups restored:              $RESTORED"
echo "  Skipped:                       $SKIPPED"
echo ""
echo "  Not removed: copied ~/.bashrc and ~/.zshrc files, CLI packages, NVM, Starship, or this repo."
