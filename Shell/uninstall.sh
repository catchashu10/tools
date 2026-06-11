#!/usr/bin/env bash
# Shell setup uninstaller
#
# Removes Shell-owned symlinks and optionally edits non-symlink files only after
# confirmation unless --allow-all is passed. Owned symlink removals run automatically.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup/helpers.sh"

REMOVED=0
RESTORED=0
SKIPPED=0

usage() {
    cat <<USAGE
Usage: $0 [options]

Remove Shell-owned symlinks and optional config entries.

Options:
$(common_options_help)
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --allow-all) ALLOW_ALL=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --color=auto) COLOR_MODE="auto" ;;
        --color=always) COLOR_MODE="always" ;;
        --color=never|--no-color) COLOR_MODE="never" ;;
        --*) error "Unknown option: $1"; usage >&2; exit 1 ;;
        *) error "Unknown argument for Shell uninstaller: $1"; usage >&2; exit 1 ;;
    esac
    shift
done

setup_ui

restore_backup_if_allowed() {
    local dest="$1"
    local backup="${dest}.bak"

    if [ ! -f "$backup" ]; then
        return 0
    fi

    if confirm_change "Restore backup $backup to $dest"; then
        if [ "$DRY_RUN" = "1" ]; then
            dry "Would restore backup $backup to $dest"
            return 0
        fi
        mv "$backup" "$dest"
        ok "Restored $dest from $backup"
        RESTORED=$((RESTORED + 1))
    else
        skip "Left backup in place: $backup"
        SKIPPED=$((SKIPPED + 1))
    fi
}

remove_owned_symlink() {
    local dest="$1"

    if [ ! -L "$dest" ]; then
        skip "No owned symlink at $dest"
        return 0
    fi

    local target
    target="$(readlink "$dest")"

    case "$target" in
        "$SCRIPT_DIR"/*)
            if [ "$DRY_RUN" = "1" ]; then
                dry "Would remove symlink: $dest"
            else
                rm "$dest"
                ok "Removed symlink: $dest"
                REMOVED=$((REMOVED + 1))
            fi
            restore_backup_if_allowed "$dest"
            ;;
        *)
            warn "Skipping $dest, points outside this Shell folder: $target"
            SKIPPED=$((SKIPPED + 1))
            ;;
    esac
}

note_local_copy() {
    local dest="$1"

    if [ -L "$dest" ]; then
        remove_owned_symlink "$dest"
    elif [ -e "$dest" ]; then
        info "$dest is a regular local file, leaving it in place"
        info "Backups, if any, remain beside it as $dest.bak.*"
    else
        skip "$dest not found"
    fi
}

remove_delta_include() {
    local gitconfig="$HOME/.gitconfig"

    if [ ! -f "$gitconfig" ]; then
        skip "No ~/.gitconfig found"
        return 0
    fi

    if ! grep -q 'delta.gitconfig' "$gitconfig"; then
        skip "No delta.gitconfig include found in ~/.gitconfig"
        return 0
    fi

    if ! confirm_change "Remove delta.gitconfig include block from ~/.gitconfig"; then
        skip "Left ~/.gitconfig unchanged"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi

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
    ok "Removed delta.gitconfig include from ~/.gitconfig"
    REMOVED=$((REMOVED + 1))
}

banner "Shell Uninstall"
printf '  %s %s\n' "$(paint "$CYAN" 'Shell folder:')" "$SCRIPT_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Mode:')" "$(mode_label)"

section "Machine-local shell rc files"
note_local_copy "$HOME/.bashrc"
note_local_copy "$HOME/.zshrc"

section "Tool-owned config symlinks"
remove_owned_symlink "$HOME/.config/starship.toml"
remove_owned_symlink "$HOME/.config/bat/env"

section "Shell scripts"
if [ -d "$SCRIPT_DIR/scripts" ]; then
    for script in "$SCRIPT_DIR/scripts/"*; do
        [ -f "$script" ] || continue
        remove_owned_symlink "$HOME/.local/bin/$(basename "$script")"
    done
else
    skip "No scripts directory found"
fi

section "Git delta"
remove_delta_include

echo ""
rule
if [ "$DRY_RUN" = "1" ]; then
    dry "Shell uninstall preview complete, no changes were made by this tool"
else
    ok "Shell uninstall complete"
fi
info "Symlinks/config entries removed: $REMOVED"
info "Backups restored: $RESTORED"
info "Skipped: $SKIPPED"
info "Not removed: copied ~/.bashrc and ~/.zshrc, CLI packages, NVM, Starship, or this repo"
print_action_summary "Shell uninstall summary"
rule
