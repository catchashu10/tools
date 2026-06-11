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
#   ./install.sh --allow-all         # skip prompts for all changes
#   ./install.sh --dry-run           # preview changes without modifying the system
#   ./install.sh --check             # run health.sh after install
#
# Safety:
#   Default mode runs symlink-only changes automatically and asks before
#   non-symlink changes such as package installs, file copies, backups,
#   git clones/pulls, and config edits.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/setup/helpers.sh"
# shellcheck source=tools.conf
source "$SCRIPT_DIR/tools.conf"
TOOLS_TO_INSTALL=()
HEALTH_TOOLS=()
FORWARD_ARGS=()
HEALTH_ARGS=()
CHECK_AFTER=0
TOOL_SUMMARY_FILE=""

usage() {
    cat <<USAGE
Usage: $0 [options] [tool ...]

Install all tools or selected tools from this repo.

Options:
  --check           Run health.sh after install completes
$(common_options_help)

Available tools:
USAGE
    for tool in "${TOOLS[@]}"; do
        echo "  $tool"
    done
    cat <<'USAGE'

Shell install includes:
  Shell
  ├── shell rc templates       copied to ~/.bashrc and ~/.zshrc
  ├── CLI packages             zsh, bat, delta, eza, fd, ripgrep, fzf, zoxide
  ├── Starship prompt          ~/.config/starship.toml plus ~/.local/bin/starship
  ├── NVM                      Node version manager under ~/.nvm
  ├── bat/delta theme config   ~/.config/bat/env and delta.gitconfig include
  └── helper scripts           bat-theme linked into ~/.local/bin
USAGE
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
            --check)
                CHECK_AFTER=1
                ;;
            --color=auto)
                COLOR_MODE="auto"
                FORWARD_ARGS+=("$1")
                HEALTH_ARGS+=("$1")
                ;;
            --color=always)
                COLOR_MODE="always"
                FORWARD_ARGS+=("$1")
                HEALTH_ARGS+=("$1")
                ;;
            --color=never|--no-color)
                COLOR_MODE="never"
                FORWARD_ARGS+=("$1")
                HEALTH_ARGS+=("$1")
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

run_health_check() {
    local health_script="$SCRIPT_DIR/health.sh"

    if [ ! -x "$health_script" ]; then
        error "Health check not found or not executable: $health_script"
        exit 1
    fi

    section "Post-install health check"
    if [ "${#HEALTH_TOOLS[@]}" -eq 0 ]; then
        "$health_script" "${HEALTH_ARGS[@]}"
    else
        "$health_script" "${HEALTH_ARGS[@]}" "${HEALTH_TOOLS[@]}"
    fi
}

parse_args "$@"
setup_ui
TOOL_SUMMARY_FILE="$(mktemp)"
trap 'rm -f "$TOOL_SUMMARY_FILE"' EXIT

if [ "${#TOOLS_TO_INSTALL[@]}" -eq 0 ]; then
    TOOLS_TO_INSTALL=("${INSTALL_ORDER[@]}")
else
    HEALTH_TOOLS=("${TOOLS_TO_INSTALL[@]}")
fi

banner "Tools Setup"
printf '  %s %s\n' "$(paint "$CYAN" 'Repo:')" "$SCRIPT_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Tools:')" "${TOOLS_TO_INSTALL[*]}"
printf '  %s %s\n' "$(paint "$CYAN" 'Mode:')" "$(mode_label)"
printf '  %s %s\n' "$(paint "$CYAN" 'Color:')" "$COLOR_MODE"
printf '  %s %s\n' "$(paint "$CYAN" 'Post-check:')" "$([ "$CHECK_AFTER" = "1" ] && { [ "${#HEALTH_TOOLS[@]}" -eq 0 ] && echo 'health.sh all checks' || echo "health.sh ${HEALTH_TOOLS[*]}"; } || echo 'disabled')"

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

if [ "$CHECK_AFTER" = "1" ]; then
    run_health_check
fi
rule
