#!/usr/bin/env bash
# Tools — master installer
#
# Purpose:
#   Run one or more tool-specific installers from this repo.
#
# Usage:
#   ./install.sh                     # install every tool in default order
#   ./install.sh Shell               # install only Shell
#   ./install.sh Nvim Tmux           # install only Nvim and Tmux
#   ./install.sh --allow-all         # do not prompt before non-symlink changes
#   ./install.sh --dry-run           # preview changes without modifying the system
#
# Safety:
#   Symlink-only changes are allowed by default. Non-symlink system changes such
#   as package installs, file copies, backups, git clones/pulls, and config edits
#   prompt unless --allow-all is passed.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/setup/helpers.sh"

DEFAULT_TOOLS=(Shell Nvim Tmux)
TOOLS_TO_INSTALL=()
FORWARD_ARGS=()
TOOL_SUMMARY_FILE=""

usage() {
    cat <<USAGE
Usage: $0 [options] [tool ...]

Install all tools or selected tools from this repo.

Options:
$(common_options_help)

Available tools:
USAGE
    for tool in "${DEFAULT_TOOLS[@]}"; do
        echo "  $tool"
    done
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --allow-all)
                ALLOW_ALL=1
                FORWARD_ARGS+=("$1")
                ;;
            --dry-run)
                DRY_RUN=1
                FORWARD_ARGS+=("$1")
                ;;
            --color=auto)
                COLOR_MODE="auto"
                FORWARD_ARGS+=("$1")
                ;;
            --color=always)
                COLOR_MODE="always"
                FORWARD_ARGS+=("$1")
                ;;
            --color=never|--no-color)
                COLOR_MODE="never"
                FORWARD_ARGS+=("$1")
                ;;
            --)
                shift
                while [ "$#" -gt 0 ]; do
                    TOOLS_TO_INSTALL+=("$1")
                    shift
                done
                break
                ;;
            --*)
                error "Unknown option: $1"
                usage >&2
                exit 1
                ;;
            *)
                TOOLS_TO_INSTALL+=("$1")
                ;;
        esac
        shift
    done
}

run_tool_installer() {
    local tool="$1"
    local installer="$SCRIPT_DIR/$tool/install.sh"

    if [ ! -x "$installer" ]; then
        error "Installer not found or not executable: $installer"
        exit 1
    fi

    section "$tool install"
    SUMMARY_DEFER_FILE="$TOOL_SUMMARY_FILE" "$installer" "${FORWARD_ARGS[@]}"
}

parse_args "$@"
setup_ui
TOOL_SUMMARY_FILE="$(mktemp)"
trap 'rm -f "$TOOL_SUMMARY_FILE"' EXIT

if [ "${#TOOLS_TO_INSTALL[@]}" -eq 0 ]; then
    TOOLS_TO_INSTALL=("${DEFAULT_TOOLS[@]}")
fi

banner "Tools Setup"
printf '  %s %s\n' "$(paint "$CYAN" 'Repo:')" "$SCRIPT_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Tools:')" "${TOOLS_TO_INSTALL[*]}"
printf '  %s %s\n' "$(paint "$CYAN" 'Mode:')" "$([ "$DRY_RUN" = "1" ] && echo 'dry-run preview' || { [ "$ALLOW_ALL" = "1" ] && echo 'allow-all' || echo 'symlinks auto, non-symlink changes confirm'; })"
printf '  %s %s\n' "$(paint "$CYAN" 'Color:')" "$COLOR_MODE"

for tool in "${TOOLS_TO_INSTALL[@]}"; do
    run_tool_installer "$tool"
done

if [ "$DRY_RUN" = "1" ]; then
    dry "Preview complete, no changes were made"
else
    ok "Requested tools installed"
fi
info "Restart your shell to pick up changes"
print_action_summary "Tools setup orchestration summary"
if [ -s "$TOOL_SUMMARY_FILE" ]; then
    section "Tool summaries"
    cat "$TOOL_SUMMARY_FILE"
fi
rule
