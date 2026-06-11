#!/usr/bin/env bash
# Nvim setup uninstaller
# Removes ~/.config/nvim only when it points into this repo's Nvim folder.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup/helpers.sh"

NVIM_CONFIG_DIR="$HOME/.config/nvim"

usage() {
    cat <<USAGE
Usage: $0 [options]

Remove the repo-owned ~/.config/nvim symlink.

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
        *) error "Unknown argument for Nvim uninstaller: $1"; usage >&2; exit 1 ;;
    esac
    shift
done

setup_ui

banner "Nvim Uninstall"
printf '  %s %s\n' "$(paint "$CYAN" 'Target:')" "$NVIM_CONFIG_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Nvim folder:')" "$SCRIPT_DIR"

section "Config symlink"
if [ ! -L "$NVIM_CONFIG_DIR" ]; then
    warn "$NVIM_CONFIG_DIR is not a symlink. Not touching it."
    exit 0
fi

current_target="$(readlink "$NVIM_CONFIG_DIR")"
case "$current_target" in
    "$SCRIPT_DIR"/*)
        if [ "$DRY_RUN" = "1" ]; then
            dry "Would remove symlink: $NVIM_CONFIG_DIR"
        else
            rm "$NVIM_CONFIG_DIR"
            ok "Removed symlink: $NVIM_CONFIG_DIR"
        fi
        info "Nvim configs remain intact under: $SCRIPT_DIR"
        ;;
    *)
        error "Refusing to remove symlink pointing outside this repo: $NVIM_CONFIG_DIR -> $current_target"
        exit 1
        ;;
esac

rule
if [ "$DRY_RUN" = "1" ]; then
    dry "Nvim uninstall preview complete, no changes were made by this tool"
else
    ok "Nvim uninstall complete"
fi
rule
