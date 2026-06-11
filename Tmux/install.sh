#!/usr/bin/env bash
# Tmux setup installer
# Usage: <repo>/Tmux/install.sh [--allow-all]
#
# Creates symlinks from tmux locations to this repo.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup/helpers.sh"

usage() {
    cat <<USAGE
Usage: $0 [options]

Install tmux framework, config symlinks, themes, and helper scripts.

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
        *) error "Unknown argument for Tmux installer: $1"; usage >&2; exit 1 ;;
    esac
    shift
done

setup_ui

banner "Tmux Setup"
printf '  %s %s\n' "$(paint "$CYAN" 'Tmux folder:')" "$SCRIPT_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Prompt mode:')" "$([ "$ALLOW_ALL" = "1" ] && echo 'allow-all' || echo 'confirm non-symlink changes')"

section "Dependencies"
if command -v tmux >/dev/null 2>&1; then
    ok "tmux $(tmux -V | cut -d' ' -f2) found"
else
    warn "tmux not found"
    install_pkg tmux
fi

section "gpakosz/.tmux framework"
if [ -d "$HOME/.tmux/.git" ]; then
    if confirm_change "Update existing ~/.tmux framework with git pull"; then
        git -C "$HOME/.tmux" pull
        ok "Updated ~/.tmux"
    else
        skip "Left existing ~/.tmux unchanged"
    fi
elif [ -e "$HOME/.tmux" ]; then
    warn "~/.tmux exists but is not a git checkout; leaving it untouched"
else
    if confirm_change "Clone gpakosz/.tmux framework into ~/.tmux"; then
        git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
        ok "Cloned ~/.tmux framework"
    else
        skip "Did not clone ~/.tmux framework"
    fi
fi

if [ -f "$HOME/.tmux/.tmux.conf" ]; then
    symlink_config "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
else
    warn "Missing ~/.tmux/.tmux.conf; cannot link ~/.tmux.conf"
fi

section "Tmux config"
symlink_config "$SCRIPT_DIR/config/tmux.conf.local" "$HOME/.tmux.conf.local"

section "Themes"
if [ -d "$HOME/.tmux/themes" ] && [ ! -L "$HOME/.tmux/themes" ]; then
    if confirm_change "Back up existing non-symlink ~/.tmux/themes before replacing with symlink"; then
        timestamp="$(date +%Y%m%d-%H%M%S)"
        mv "$HOME/.tmux/themes" "$HOME/.tmux/themes.bak.$timestamp"
        ok "Backed up ~/.tmux/themes -> ~/.tmux/themes.bak.$timestamp"
    else
        skip "Left existing ~/.tmux/themes unchanged"
    fi
fi
if [ ! -e "$HOME/.tmux/themes" ] && [ ! -L "$HOME/.tmux/themes" ]; then
    symlink_config "$SCRIPT_DIR/themes" "$HOME/.tmux/themes"
elif [ -L "$HOME/.tmux/themes" ]; then
    symlink_config "$SCRIPT_DIR/themes" "$HOME/.tmux/themes"
fi
info "Themes: $(find "$SCRIPT_DIR/themes" -maxdepth 1 -type f -name '*.conf' -printf '%f ' 2>/dev/null | sed 's/\.conf//g')"

section "Scripts"
if [ -d "$SCRIPT_DIR/scripts" ]; then
    for script in "$SCRIPT_DIR/scripts/"*; do
        [ -f "$script" ] || continue
        chmod +x "$script"
        symlink_config "$script" "$HOME/.local/bin/$(basename "$script")"
    done
else
    skip "No scripts directory found"
fi

section "PATH"
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
    ok "~/.local/bin already in PATH"
else
    warn "~/.local/bin not in current PATH"
    SHELL_RC="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
    if confirm_change "Append ~/.local/bin PATH export to $SHELL_RC"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        ok "Added PATH export to $SHELL_RC"
    fi
fi

section "Runtime folders"
ensure_dir "$HOME/.tmux-context" "Create tmux capture output directory" || true

section "Clipboard helper"
if [ "$(uname)" != "Darwin" ]; then
    if command -v xsel >/dev/null 2>&1 || command -v xclip >/dev/null 2>&1 || command -v wl-copy >/dev/null 2>&1; then
        ok "Clipboard helper found"
    else
        warn "No clipboard helper found"
        install_pkg xsel || true
    fi
else
    ok "macOS pbcopy/pbpaste available by default"
fi

echo ""
rule
ok "Tmux installation complete"
info "Start tmux: tmux new -s main"
info "Install plugins: Ctrl-a I"
info "Prefix: Ctrl-a primary, Ctrl-Space secondary"
rule
