#!/usr/bin/env bash
# Tools — read-only health check
#
# Purpose:
#   Inspect this Tools repo and the expected user-level install state without
#   changing the system. This script is safe to run repeatedly.
#
# Usage:
#   ./health.sh                  # check all tools
#   ./health.sh Shell            # check one tool
#   ./health.sh Shell Nvim       # check selected tools
#   ./health.sh --color=always   # force ANSI colors, useful when output is piped
#   ./health.sh --no-color       # disable ANSI colors
#
# Exit codes:
#   0 = no failures found, although warnings may be present
#   1 = one or more required checks failed

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_TOOLS=(Repo Shell Nvim Tmux)

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
INFO_COUNT=0
CURRENT_SECTION=""
COLOR_MODE="auto"
USE_COLOR=0

# Color palette. Values are set after argument parsing by setup_color().
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

setup_color() {
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
                # Prefer colors for normal interactive use. If output is piped,
                # auto disables colors; pass --color=always to force them.
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

section() {
    CURRENT_SECTION="$1"
    echo ""
    rule
    printf '%s %s\n' "$(paint "$BLUE" '●')" "$(paint "$BOLD" "$CURRENT_SECTION")"
    rule
}

status_line() {
    local color="$1" icon="$2" label="$3" message="$4"
    printf '  %s %-5s %s\n' "$(paint "$color" "$icon")" "$(paint "$color$BOLD" "$label")" "$message"
}

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    status_line "$GREEN" "✓" "PASS" "$1"
}

warn() {
    WARN_COUNT=$((WARN_COUNT + 1))
    status_line "$YELLOW" "!" "WARN" "$1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    status_line "$RED" "✗" "FAIL" "$1"
}

info() {
    INFO_COUNT=$((INFO_COUNT + 1))
    status_line "$CYAN" "i" "INFO" "$1"
}

usage() {
    cat <<USAGE
Usage: $0 [options] [tool ...]

Options:
  --color=auto     Color only when stdout is a terminal (default)
  --color=always   Force ANSI colors
  --color=never    Disable ANSI colors
  --no-color       Same as --color=never
  -h, --help       Show this help

Available checks:
USAGE
    for tool in "${DEFAULT_TOOLS[@]}"; do
        echo "  $tool"
    done
}

command_path() {
    command -v "$1" 2>/dev/null || true
}

check_command() {
    local label="$1" cmd="$2" required="${3:-required}"
    local path
    path="$(command_path "$cmd")"

    if [ -n "$path" ]; then
        pass "$label command found: $path"
    elif [ "$required" = "optional" ]; then
        warn "$label command not found: $cmd"
    else
        fail "$label command not found: $cmd"
    fi
}

check_any_command() {
    local label="$1" required="$2"
    shift 2

    local cmd path
    for cmd in "$@"; do
        path="$(command_path "$cmd")"
        if [ -n "$path" ]; then
            pass "$label command found: $cmd ($path)"
            return 0
        fi
    done

    if [ "$required" = "optional" ]; then
        warn "$label command not found. Tried: $*"
    else
        fail "$label command not found. Tried: $*"
    fi
}

check_file() {
    local label="$1" path="$2" required="${3:-required}"

    if [ -f "$path" ]; then
        pass "$label exists: $path"
    elif [ "$required" = "optional" ]; then
        warn "$label missing: $path"
    else
        fail "$label missing: $path"
    fi
}

check_dir() {
    local label="$1" path="$2" required="${3:-required}"

    if [ -d "$path" ]; then
        pass "$label exists: $path"
    elif [ "$required" = "optional" ]; then
        warn "$label missing: $path"
    else
        fail "$label missing: $path"
    fi
}

check_executable() {
    local label="$1" path="$2"

    if [ -x "$path" ]; then
        pass "$label executable: $path"
    elif [ -e "$path" ]; then
        fail "$label exists but is not executable: $path"
    else
        fail "$label missing: $path"
    fi
}

check_symlink_target() {
    local label="$1" link_path="$2" expected_target="$3" required="${4:-required}"
    local target

    if [ ! -L "$link_path" ]; then
        if [ -e "$link_path" ]; then
            fail "$label is not a symlink: $link_path"
        elif [ "$required" = "optional" ]; then
            warn "$label symlink missing: $link_path"
        else
            fail "$label symlink missing: $link_path"
        fi
        return 0
    fi

    target="$(readlink "$link_path")"
    if [ "$target" = "$expected_target" ]; then
        pass "$label symlink ok: $link_path -> $target"
    else
        fail "$label symlink target mismatch: $link_path -> $target (expected $expected_target)"
    fi
}

check_symlink_under() {
    local label="$1" link_path="$2" expected_prefix="$3" required="${4:-required}"
    local target

    if [ ! -L "$link_path" ]; then
        if [ -e "$link_path" ]; then
            fail "$label is not a symlink: $link_path"
        elif [ "$required" = "optional" ]; then
            warn "$label symlink missing: $link_path"
        else
            fail "$label symlink missing: $link_path"
        fi
        return 0
    fi

    target="$(readlink "$link_path")"
    case "$target" in
        "$expected_prefix"|"$expected_prefix"/*)
            pass "$label symlink points into expected location: $link_path -> $target"
            ;;
        *)
            fail "$label symlink points outside expected location: $link_path -> $target (expected under $expected_prefix)"
            ;;
    esac
}

check_regular_copy() {
    local label="$1" path="$2" template="$3"

    if [ ! -e "$path" ]; then
        fail "$label missing: $path"
        return 0
    fi

    if [ -L "$path" ]; then
        fail "$label should be a regular local copy, but is a symlink: $path -> $(readlink "$path")"
        return 0
    fi

    if [ ! -f "$path" ]; then
        fail "$label should be a regular file: $path"
        return 0
    fi

    pass "$label is a regular local file: $path"

    if cmp -s "$template" "$path"; then
        info "$label matches repo template exactly"
    else
        info "$label differs from repo template, which is allowed for machine-local drift"
    fi
}

check_git_include_contains() {
    local label="$1" expected_path="$2"
    local gitconfig="$HOME/.gitconfig"

    if [ ! -f "$gitconfig" ]; then
        fail "$label missing ~/.gitconfig, so delta include is absent"
        return 0
    fi

    if grep -Fq "$expected_path" "$gitconfig"; then
        pass "$label include found in ~/.gitconfig: $expected_path"
    elif grep -Fq 'delta.gitconfig' "$gitconfig"; then
        fail "$label includes delta.gitconfig, but not expected path: $expected_path"
    else
        fail "$label delta.gitconfig include missing from ~/.gitconfig"
    fi
}

check_repo() {
    section "Repo"

    check_dir "Repo root" "$SCRIPT_DIR"
    check_dir "Shared setup folder" "$SCRIPT_DIR/setup"
    check_file "Shared helpers" "$SCRIPT_DIR/setup/helpers.sh"
    check_executable "Top-level installer" "$SCRIPT_DIR/install.sh"
    check_executable "Top-level uninstaller" "$SCRIPT_DIR/uninstall.sh"
    check_executable "Top-level health check" "$SCRIPT_DIR/health.sh"

    local tool
    for tool in Shell Nvim Tmux; do
        check_dir "$tool tool folder" "$SCRIPT_DIR/$tool"
        check_executable "$tool installer" "$SCRIPT_DIR/$tool/install.sh"
        check_executable "$tool uninstaller" "$SCRIPT_DIR/$tool/uninstall.sh"
    done

    if git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        pass "Repo is a git work tree"
        local status
        status="$(git -C "$SCRIPT_DIR" status --short)"
        if [ -z "$status" ]; then
            pass "Git working tree is clean"
        else
            warn "Git working tree has uncommitted changes:"
            printf '%s\n' "$status" | sed 's/^/        /'
        fi
    else
        warn "Repo is not a git work tree: $SCRIPT_DIR"
    fi
}

check_shell() {
    section "Shell"

    check_dir "Shell config folder" "$SCRIPT_DIR/Shell/config"
    check_dir "Shell scripts folder" "$SCRIPT_DIR/Shell/scripts"
    check_file "Bash template" "$SCRIPT_DIR/Shell/config/bashrc"
    check_file "Zsh template" "$SCRIPT_DIR/Shell/config/zshrc"
    check_file "Starship config" "$SCRIPT_DIR/Shell/config/starship.toml"
    check_file "Bat env config" "$SCRIPT_DIR/Shell/config/bat-env"
    check_file "Delta gitconfig" "$SCRIPT_DIR/Shell/config/delta.gitconfig"

    check_regular_copy "~/.bashrc" "$HOME/.bashrc" "$SCRIPT_DIR/Shell/config/bashrc"
    check_regular_copy "~/.zshrc" "$HOME/.zshrc" "$SCRIPT_DIR/Shell/config/zshrc"
    check_symlink_target "Starship config" "$HOME/.config/starship.toml" "$SCRIPT_DIR/Shell/config/starship.toml"
    check_symlink_target "Bat env config" "$HOME/.config/bat/env" "$SCRIPT_DIR/Shell/config/bat-env"

    if [ -d "$SCRIPT_DIR/Shell/scripts" ]; then
        local script name
        for script in "$SCRIPT_DIR/Shell/scripts/"*; do
            [ -f "$script" ] || continue
            name="$(basename "$script")"
            check_executable "Shell repo script $name" "$script"
            check_symlink_target "Installed shell script $name" "$HOME/.local/bin/$name" "$script"
        done
    fi

    check_git_include_contains "Git delta" "$SCRIPT_DIR/Shell/config/delta.gitconfig"

    check_command "git" git
    check_any_command "bat" required bat batcat
    check_command "delta" delta
    check_command "eza" eza
    check_any_command "fd" required fd fdfind
    check_command "ripgrep" rg
    check_command "fzf" fzf
    check_command "zoxide" zoxide
    check_command "starship" starship
    check_command "zsh" zsh optional

    if [ -d "$HOME/.nvm" ]; then
        pass "NVM directory exists: $HOME/.nvm"
    else
        warn "NVM directory missing: $HOME/.nvm"
    fi

    case ":$PATH:" in
        *":$HOME/.local/bin:"*) pass "~/.local/bin is present in current PATH" ;;
        *) warn "~/.local/bin is not present in current PATH for this shell" ;;
    esac
}

check_nvim() {
    section "Nvim"

    check_dir "Nvim folder" "$SCRIPT_DIR/Nvim"
    check_dir "LazyVim flavor" "$SCRIPT_DIR/Nvim/lazyNvim"
    check_file "LazyVim init.lua" "$SCRIPT_DIR/Nvim/lazyNvim/init.lua"
    check_dir "LazyVim lua folder" "$SCRIPT_DIR/Nvim/lazyNvim/lua"
    check_symlink_target "Neovim config" "$HOME/.config/nvim" "$SCRIPT_DIR/Nvim/lazyNvim"

    check_command "nvim" nvim
    check_command "git" git
    check_command "ripgrep" rg
    check_any_command "fd" required fd fdfind
    check_command "lazygit" lazygit optional
    check_command "node" node optional
    check_command "npm" npm optional
    check_command "python3" python3 optional

    check_dir "Neovim data dir" "$HOME/.local/share/nvim" optional
    check_dir "Neovim state dir" "$HOME/.local/state/nvim" optional
    check_dir "Neovim cache dir" "$HOME/.cache/nvim" optional

    if command -v nvim >/dev/null 2>&1; then
        local version
        version="$(nvim --version 2>/dev/null | sed -n '1p')"
        info "nvim version: ${version:-unknown}"
    fi
}

check_tmux() {
    section "Tmux"

    check_dir "Tmux folder" "$SCRIPT_DIR/Tmux"
    check_dir "Tmux config folder" "$SCRIPT_DIR/Tmux/config"
    check_dir "Tmux themes folder" "$SCRIPT_DIR/Tmux/themes"
    check_dir "Tmux scripts folder" "$SCRIPT_DIR/Tmux/scripts"
    check_file "Tmux local config" "$SCRIPT_DIR/Tmux/config/tmux.conf.local"
    check_file "Default tmux theme" "$SCRIPT_DIR/Tmux/themes/default.conf"

    check_command "tmux" tmux
    if command -v tmux >/dev/null 2>&1; then
        info "tmux version: $(tmux -V 2>/dev/null || true)"
    fi

    check_dir "gpakosz .tmux framework" "$HOME/.tmux" optional
    check_file "gpakosz main tmux config" "$HOME/.tmux/.tmux.conf" optional
    check_symlink_target "~/.tmux.conf" "$HOME/.tmux.conf" "$HOME/.tmux/.tmux.conf" optional
    check_symlink_target "~/.tmux.conf.local" "$HOME/.tmux.conf.local" "$SCRIPT_DIR/Tmux/config/tmux.conf.local"
    check_symlink_target "Tmux themes" "$HOME/.tmux/themes" "$SCRIPT_DIR/Tmux/themes"
    check_dir "Tmux capture output folder" "$HOME/.tmux-context" optional

    if [ -d "$SCRIPT_DIR/Tmux/scripts" ]; then
        local script name
        for script in "$SCRIPT_DIR/Tmux/scripts/"*; do
            [ -f "$script" ] || continue
            name="$(basename "$script")"
            check_executable "Tmux repo script $name" "$script"
            check_symlink_target "Installed tmux script $name" "$HOME/.local/bin/$name" "$script"
        done
    fi

    if [ "$(uname)" != "Darwin" ]; then
        check_any_command "Clipboard helper" optional xsel xclip wl-copy
    fi
}

run_check() {
    case "$1" in
        Repo) check_repo ;;
        Shell) check_shell ;;
        Nvim) check_nvim ;;
        Tmux) check_tmux ;;
        *)
            echo "ERROR: unknown health check: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
}

TOOLS_TO_CHECK=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --no-color)
            COLOR_MODE="never"
            ;;
        --color=auto)
            COLOR_MODE="auto"
            ;;
        --color=always)
            COLOR_MODE="always"
            ;;
        --color=never)
            COLOR_MODE="never"
            ;;
        --color)
            shift
            COLOR_MODE="${1:-}"
            ;;
        --)
            shift
            while [ "$#" -gt 0 ]; do
                TOOLS_TO_CHECK+=("$1")
                shift
            done
            break
            ;;
        --*)
            echo "ERROR: unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            TOOLS_TO_CHECK+=("$1")
            ;;
    esac
    shift
done

if [ "${#TOOLS_TO_CHECK[@]}" -eq 0 ]; then
    TOOLS_TO_CHECK=("${DEFAULT_TOOLS[@]}")
fi

setup_color

rule
printf '%s\n' "$(paint "$BOLD$MAGENTA" 'Tools Health Check')"
rule
printf '  %s %s\n' "$(paint "$CYAN" 'Repo:')" "$SCRIPT_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Checks:')" "${TOOLS_TO_CHECK[*]}"
printf '  %s %s\n' "$(paint "$CYAN" 'Mode:')" "read-only, no files are modified"
printf '  %s %s\n' "$(paint "$CYAN" 'Color:')" "$COLOR_MODE"

for tool in "${TOOLS_TO_CHECK[@]}"; do
    run_check "$tool"
done

echo ""
rule
printf '%s\n' "$(paint "$BOLD" 'Health summary')"
rule
printf '  %s %s\n' "$(paint "$GREEN$BOLD" 'PASS')" "$PASS_COUNT"
printf '  %s %s\n' "$(paint "$YELLOW$BOLD" 'WARN')" "$WARN_COUNT"
printf '  %s %s\n' "$(paint "$RED$BOLD" 'FAIL')" "$FAIL_COUNT"
printf '  %s %s\n' "$(paint "$CYAN$BOLD" 'INFO')" "$INFO_COUNT"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    printf '%s %s\n' "$(paint "$RED$BOLD" 'Result: FAIL')" "- fix required checks above."
    exit 1
fi

if [ "$WARN_COUNT" -gt 0 ]; then
    printf '%s %s\n' "$(paint "$YELLOW$BOLD" 'Result: OK with warnings')" "- review optional/missing details above."
else
    printf '%s\n' "$(paint "$GREEN$BOLD" 'Result: OK — no required issues found.')"
fi
