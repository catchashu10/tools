#!/usr/bin/env bash
# Tmux setup uninstaller
# Removes Tmux-owned symlinks. Non-symlink restores prompt unless --allow-all.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup/helpers.sh"

REMOVED=0
RESTORED=0
SKIPPED=0

usage() {
    cat <<USAGE
Usage: $0 [options]

Remove Tmux-owned symlinks created by the installer.

Options:
$(common_options_help)
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --allow-all) ALLOW_ALL=1 ;;
        --color=auto) COLOR_MODE="auto" ;;
        --color=always) COLOR_MODE="always" ;;
        --color=never|--no-color) COLOR_MODE="never" ;;
        --*) error "Unknown option: $1"; usage >&2; exit 1 ;;
        *) error "Unknown argument for Tmux uninstaller: $1"; usage >&2; exit 1 ;;
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
        "$SCRIPT_DIR"/*|"$HOME/.tmux/.tmux.conf")
            rm "$dest"
            ok "Removed symlink: $dest"
            REMOVED=$((REMOVED + 1))
            restore_backup_if_allowed "$dest"
            ;;
        *)
            warn "Skipping $dest, points outside this Tmux setup: $target"
            SKIPPED=$((SKIPPED + 1))
            ;;
    esac
}

banner "Tmux Uninstall"
printf '  %s %s\n' "$(paint "$CYAN" 'Tmux folder:')" "$SCRIPT_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Prompt mode:')" "$([ "$ALLOW_ALL" = "1" ] && echo 'allow-all' || echo 'confirm non-symlink changes')"

section "Config symlinks"
remove_owned_symlink "$HOME/.tmux.conf"
remove_owned_symlink "$HOME/.tmux.conf.local"

section "Themes symlink"
remove_owned_symlink "$HOME/.tmux/themes"

section "Scripts"
if [ -d "$SCRIPT_DIR/scripts" ]; then
    for script in "$SCRIPT_DIR/scripts/"*; do
        [ -f "$script" ] || continue
        remove_owned_symlink "$HOME/.local/bin/$(basename "$script")"
    done
else
    skip "No scripts directory found"
fi

echo ""
rule
ok "Tmux uninstall complete"
info "Symlinks removed: $REMOVED"
info "Backups restored: $RESTORED"
info "Skipped: $SKIPPED"
info "Not removed: tmux package, ~/.tmux, ~/.tmux-context, or this repo"
rule
