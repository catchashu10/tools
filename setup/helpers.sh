#!/usr/bin/env bash
# Shared helper functions for Tools installers/uninstallers.
# Source this from tool scripts:
#   source "$(dirname "$0")/../setup/helpers.sh"

# Common runtime flags. Scripts may override these after sourcing.
ALLOW_ALL="${ALLOW_ALL:-0}"
COLOR_MODE="${COLOR_MODE:-auto}"
USE_COLOR=0

BOLD=""
DIM=""
RESET=""
GREEN=""
YELLOW=""
RED=""
CYAN=""
BLUE=""
MAGENTA=""
GRAY=""

setup_ui() {
    case "$COLOR_MODE" in
        always)
            USE_COLOR=1
            ;;
        never)
            USE_COLOR=0
            ;;
        auto)
            if [ -n "${NO_COLOR:-}" ] || [ "${TERM:-}" = "dumb" ]; then
                USE_COLOR=0
            else
                [ -t 1 ] && USE_COLOR=1 || USE_COLOR=0
            fi
            ;;
        *)
            echo "ERROR: invalid color mode: $COLOR_MODE" >&2
            exit 1
            ;;
    esac

    if [ "$USE_COLOR" -eq 1 ]; then
        BOLD=$'\033[1m'
        DIM=$'\033[2m'
        RESET=$'\033[0m'
        GREEN=$'\033[32m'
        YELLOW=$'\033[33m'
        RED=$'\033[31m'
        CYAN=$'\033[36m'
        BLUE=$'\033[34m'
        MAGENTA=$'\033[35m'
        GRAY=$'\033[90m'
    fi
}

paint() {
    local color="$1" text="$2"
    printf '%s%s%s' "$color" "$text" "$RESET"
}

rule() {
    printf '%s\n' "$(paint "$GRAY" '────────────────────────────────────────────────────────────')"
}

banner() {
    local title="$1"
    rule
    printf '%s\n' "$(paint "$BOLD$MAGENTA" "$title")"
    rule
}

section() {
    local title="$1"
    echo ""
    rule
    printf '%s %s\n' "$(paint "$BLUE" '●')" "$(paint "$BOLD" "$title")"
    rule
}

status_line() {
    local color="$1" icon="$2" label="$3" message="$4"
    printf '  %s %-5s %s\n' "$(paint "$color" "$icon")" "$(paint "$color$BOLD" "$label")" "$message"
}

ok() { status_line "$GREEN" "✓" "OK" "$1"; }
step() { status_line "$BLUE" "›" "STEP" "$1"; }
info() { status_line "$CYAN" "i" "INFO" "$1"; }
warn() { status_line "$YELLOW" "!" "WARN" "$1"; }
error() { status_line "$RED" "✗" "ERROR" "$1"; }
skip() { status_line "$GRAY" "-" "SKIP" "$1"; }

confirm_change() {
    local message="$1"

    if [ "$ALLOW_ALL" = "1" ]; then
        ok "Allowed: $message"
        return 0
    fi

    if [ ! -t 0 ]; then
        warn "Skipping, confirmation required in interactive shell: $message"
        return 1
    fi

    printf '  %s %s\n' "$(paint "$YELLOW" '?')" "$(paint "$YELLOW$BOLD" 'CONFIRM') $message"
    printf '    Proceed? [y/N] '
    local answer
    read -r answer
    case "$answer" in
        y|Y|yes|YES|Yes)
            ok "Confirmed: $message"
            return 0
            ;;
        *)
            skip "Declined: $message"
            return 1
            ;;
    esac
}

common_options_help() {
    cat <<'HELP'
  --allow-all       Do not prompt before non-symlink system changes
  --color=auto      Color only when stdout is a terminal (default)
  --color=always    Force ANSI colors
  --color=never     Disable ANSI colors
  --no-color        Same as --color=never
  -h, --help        Show help
HELP
}

append_common_arg() {
    case "$1" in
        --allow-all)
            printf '%s\n' "$1"
            ;;
        --color=auto|--color=always|--color=never|--no-color)
            printf '%s\n' "$1"
            ;;
    esac
}

ensure_dir() {
    local dir="$1" reason="${2:-Create directory}"

    if [ -d "$dir" ]; then
        return 0
    fi

    if confirm_change "$reason: $dir"; then
        mkdir -p "$dir"
        ok "Created directory: $dir"
        return 0
    fi

    skip "Directory not created: $dir"
    return 1
}

symlink_config() {
    local src="$1" dest="$2"
    local parent
    parent="$(dirname "$dest")"

    if [ ! -d "$parent" ]; then
        ensure_dir "$parent" "Create parent directory for symlink" || return 0
    fi

    if [ -L "$dest" ]; then
        local current_target
        current_target="$(readlink "$dest")"
        if [ "$current_target" = "$src" ]; then
            ok "Already linked: $dest -> $src"
            return 0
        fi
        ln -s -f "$src" "$dest"
        ok "Updated symlink: $dest -> $src"
        return 0
    fi

    if [ -e "$dest" ]; then
        local timestamp backup
        timestamp="$(date +%Y%m%d-%H%M%S)"
        backup="$dest.bak.$timestamp"
        if confirm_change "Back up existing non-symlink $dest and replace it with symlink"; then
            mv "$dest" "$backup"
            ln -s "$src" "$dest"
            ok "Backed up $dest -> $backup"
            ok "Linked: $dest -> $src"
        else
            skip "Left existing $dest unchanged"
        fi
        return 0
    fi

    ln -s "$src" "$dest"
    ok "Linked: $dest -> $src"
}

install_pkg() {
    if [ "$#" -eq 0 ]; then
        return 0
    fi

    if command -v apt >/dev/null 2>&1; then
        if confirm_change "Install package(s) with apt: $*"; then
            sudo apt install -y "$@"
        fi
    elif command -v brew >/dev/null 2>&1; then
        if confirm_change "Install package(s) with brew: $*"; then
            brew install "$@"
        fi
    else
        warn "No supported package manager (apt/brew). Install manually: $*"
        return 1
    fi
}

# Download a binary from GitHub releases and install to ~/.local/bin.
# Usage: install_github_binary "owner/repo" "binary_name"
install_github_binary() {
    local repo="$1" binary="$2"

    if ! confirm_change "Download and install $binary from GitHub releases into ~/.local/bin"; then
        return 1
    fi

    local arch
    arch="$(uname -m)"

    local url
    url=$(curl -sL "https://api.github.com/repos/$repo/releases/latest" \
        | grep "browser_download_url" \
        | grep -i "${arch}.*linux" \
        | grep "\.tar\.gz" \
        | grep -v "musl\|\.sha\|\.md5\|\.sig" \
        | head -1 \
        | cut -d'"' -f4)

    if [ -z "$url" ]; then
        warn "No matching release found for $repo ($arch)"
        return 1
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    info "Downloading $binary from GitHub..."

    if curl -sL "$url" -o "$tmpdir/archive.tar.gz"; then
        tar xzf "$tmpdir/archive.tar.gz" -C "$tmpdir"
        local bin
        bin=$(find "$tmpdir" -name "$binary" -type f | head -1)
        if [ -n "$bin" ]; then
            chmod +x "$bin"
            mkdir -p "$HOME/.local/bin"
            mv "$bin" "$HOME/.local/bin/$binary"
            ok "$binary installed to ~/.local/bin/"
            rm -rf "$tmpdir"
            return 0
        fi
    fi

    rm -rf "$tmpdir"
    warn "Failed to install $binary from GitHub"
    return 1
}
