#!/usr/bin/env bash
# Tools — master uninstaller
#
# Purpose:
#   Run one or more tool-specific uninstallers from this repo.
#
# Usage:
#   ./uninstall.sh                     # uninstall every tool in reverse order
#   ./uninstall.sh Nvim                # uninstall only Nvim
#   ./uninstall.sh Tmux Shell          # uninstall selected tools
#   ./uninstall.sh --allow-all         # do not prompt before non-symlink changes
#
# Safety:
#   Removing owned symlinks is allowed by default. Non-symlink system changes,
#   such as restoring backup files or editing ~/.gitconfig, prompt unless
#   --allow-all is passed.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/setup/helpers.sh"

# Reverse of install order is safest for a full uninstall: remove tools that
# depend on Shell conventions before removing Shell's symlinks.
DEFAULT_TOOLS=(Tmux Nvim Shell)
TOOLS_TO_UNINSTALL=()
FORWARD_ARGS=()

usage() {
    cat <<USAGE
Usage: $0 [options] [tool ...]

Uninstall all tools or selected tools from this repo.

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
                    TOOLS_TO_UNINSTALL+=("$1")
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
                TOOLS_TO_UNINSTALL+=("$1")
                ;;
        esac
        shift
    done
}

run_tool_uninstaller() {
    local tool="$1"
    local uninstaller="$SCRIPT_DIR/$tool/uninstall.sh"

    if [ ! -x "$uninstaller" ]; then
        error "Uninstaller not found or not executable: $uninstaller"
        exit 1
    fi

    section "$tool uninstall"
    "$uninstaller" "${FORWARD_ARGS[@]}"
}

parse_args "$@"
setup_ui

if [ "${#TOOLS_TO_UNINSTALL[@]}" -eq 0 ]; then
    TOOLS_TO_UNINSTALL=("${DEFAULT_TOOLS[@]}")
fi

banner "Tools Uninstall"
printf '  %s %s\n' "$(paint "$CYAN" 'Repo:')" "$SCRIPT_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Tools:')" "${TOOLS_TO_UNINSTALL[*]}"
printf '  %s %s\n' "$(paint "$CYAN" 'Prompt mode:')" "$([ "$ALLOW_ALL" = "1" ] && echo 'allow-all' || echo 'confirm non-symlink changes')"
printf '  %s %s\n' "$(paint "$CYAN" 'Color:')" "$COLOR_MODE"

for tool in "${TOOLS_TO_UNINSTALL[@]}"; do
    run_tool_uninstaller "$tool"
done

echo ""
rule
ok "Requested tools uninstalled"
info "Repo remains intact: $SCRIPT_DIR"
rule
