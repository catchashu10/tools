#!/usr/bin/env bash
# Nvim setup installer
# Usage:
#   ./install.sh [flavor] [--force-clean] [--allow-all] [--dry-run]
#
# Creates ~/.config/nvim as a symlink to one Nvim flavor in this repo.

set -e

# ALLOW_ALL and COLOR_MODE are read by setup/helpers.sh after argument parsing.
# shellcheck disable=SC2034

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=setup/helpers.sh
source "$SCRIPT_DIR/../setup/helpers.sh"

FLAVOR="lazyNvim"
FORCE_CLEAN=0

usage() {
    cat <<USAGE
Usage: $0 [options] [flavor]

Install one Neovim config flavor. Default flavor: lazyNvim.

Options:
  --force-clean     Remove existing Neovim runtime/cache dirs instead of backing them up
$(common_options_help)
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --force-clean) FORCE_CLEAN=1 ;;
        --allow-all) ALLOW_ALL=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --color=auto) COLOR_MODE="auto" ;;
        --color=always) COLOR_MODE="always" ;;
        --color=never|--no-color) COLOR_MODE="never" ;;
        --*) error "Unknown option: $1"; usage >&2; exit 1 ;;
        *) FLAVOR="$1" ;;
    esac
    shift
done

setup_ui

NVIM_FLAVOR_DIR="$SCRIPT_DIR/$FLAVOR"
NVIM_CONFIG_DIR="$HOME/.config/nvim"

backup_or_remove() {
    local path="$1"
    local timestamp backup
    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup="$path.bak.$timestamp"

    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        return 0
    fi

    if [ "$FORCE_CLEAN" = "1" ]; then
        if confirm_change "Remove existing path: $path"; then
            rm -rf "$path"
            ok "Removed $path"
        else
            skip "Left $path unchanged"
        fi
    else
        if confirm_change "Back up existing path: $path -> $backup"; then
            mv "$path" "$backup"
            ok "Backed up $path -> $backup"
        else
            skip "Left $path unchanged"
        fi
    fi
}

banner "Nvim Setup"
printf '  %s %s\n' "$(paint "$CYAN" 'Flavor:')" "$FLAVOR"
printf '  %s %s\n' "$(paint "$CYAN" 'Source:')" "$NVIM_FLAVOR_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Target:')" "$NVIM_CONFIG_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Runtime mode:')" "$([ "$FORCE_CLEAN" = "1" ] && echo 'force-clean' || echo 'backup')"
printf '  %s %s\n' "$(paint "$CYAN" 'Mode:')" "$(mode_label)"

if [ ! -d "$NVIM_FLAVOR_DIR" ]; then
    error "Nvim flavor not found: $NVIM_FLAVOR_DIR"
    echo ""
    echo "Available flavors:"
    find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d -printf "  %f\n" | sort
    exit 1
fi

section "Dependencies"
if command -v nvim >/dev/null 2>&1; then
    ok "nvim found"
else
    warn "nvim not found"
    install_pkg neovim
fi
if command -v git >/dev/null 2>&1; then
    ok "git found"
else
    warn "git not found"
    install_pkg git
fi
if command -v rg >/dev/null 2>&1; then
    ok "ripgrep found"
else
    warn "ripgrep not found"
    install_pkg ripgrep
fi
if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
    ok "fd found"
else
    warn "fd not found"
    install_pkg fd-find || install_pkg fd || true
fi

section "Runtime directories"
backup_or_remove "$HOME/.local/share/nvim"
backup_or_remove "$HOME/.local/state/nvim"
backup_or_remove "$HOME/.cache/nvim"

section "Neovim config symlink"
if [ -L "$NVIM_CONFIG_DIR" ]; then
    current_target="$(readlink "$NVIM_CONFIG_DIR")"
    if [ "$current_target" = "$NVIM_FLAVOR_DIR" ]; then
        ok "Already linked: $NVIM_CONFIG_DIR -> $NVIM_FLAVOR_DIR"
    else
        backup_or_remove "$NVIM_CONFIG_DIR"
        if [ ! -e "$NVIM_CONFIG_DIR" ] && [ ! -L "$NVIM_CONFIG_DIR" ]; then
            symlink_config "$NVIM_FLAVOR_DIR" "$NVIM_CONFIG_DIR"
        fi
    fi
elif [ -e "$NVIM_CONFIG_DIR" ]; then
    backup_or_remove "$NVIM_CONFIG_DIR"
    if [ ! -e "$NVIM_CONFIG_DIR" ] && [ ! -L "$NVIM_CONFIG_DIR" ]; then
        symlink_config "$NVIM_FLAVOR_DIR" "$NVIM_CONFIG_DIR"
    fi
else
    symlink_config "$NVIM_FLAVOR_DIR" "$NVIM_CONFIG_DIR"
fi

echo ""
rule
if [ "$DRY_RUN" = "1" ]; then
    dry "Nvim install preview complete, no changes were made by this tool"
else
    ok "Nvim installation complete"
fi
info "Start Neovim with: nvim"
info "Then run inside Neovim: :LazyHealth"
print_action_summary "Nvim install summary"
rule
