#!/usr/bin/env bash
# Shell setup installer
# Usage: <repo>/Shell/install.sh [--allow-all] [--dry-run]
#
# Installs CLI tools, copies machine-local shell rc templates, and symlinks
# tool-owned shell configs/scripts into place.

set -e

# User-facing messages intentionally use literal ~ paths.
# shellcheck disable=SC2088

# ALLOW_ALL and COLOR_MODE are read by setup/helpers.sh after argument parsing.
# shellcheck disable=SC2034

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=setup/helpers.sh
source "$SCRIPT_DIR/../setup/helpers.sh"

usage() {
    cat <<USAGE
Usage: $0 [options]

Install shell tools, copied rc files, and tool-owned symlinks.

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
        *) error "Unknown argument for Shell installer: $1"; usage >&2; exit 1 ;;
    esac
    shift
done

setup_ui

copy_shell_rc() {
    local src="$1" dest="$2"
    local timestamp backup
    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup="$dest.bak.$timestamp"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if cmp -s "$src" "$dest" 2>/dev/null && [ ! -L "$dest" ]; then
            ok "$dest already matches repo template"
            return 0
        fi
        if ! confirm_change "Back up existing $dest and copy repo template over it"; then
            skip "Left $dest unchanged"
            return 0
        fi
        mv "$dest" "$backup"
        ok "Backed up $dest -> $backup"
    else
        if ! confirm_change "Create local shell rc file from repo template: $dest"; then
            skip "Did not create $dest"
            return 0
        fi
    fi

    cp "$src" "$dest"
    chmod 0644 "$dest"
    ok "Copied $src -> $dest"
}

install_missing_packages() {
    local packages=("$@")
    local failed=()

    [ "${#packages[@]}" -gt 0 ] || return 0

    if command -v apt >/dev/null 2>&1; then
        if confirm_change "Run apt update and install package(s): ${packages[*]}"; then
            sudo apt update
            for pkg in "${packages[@]}"; do
                if sudo apt install -y "$pkg" 2>/dev/null; then
                    ok "$pkg installed"
                else
                    failed+=("$pkg")
                    warn "$pkg not available in apt repos"
                fi
            done
        else
            failed=("${packages[@]}")
        fi
    elif command -v brew >/dev/null 2>&1; then
        if confirm_change "Install package(s) with brew: ${packages[*]}"; then
            for pkg in "${packages[@]}"; do
                if brew install "$pkg" 2>/dev/null; then
                    ok "$pkg installed"
                else
                    failed+=("$pkg")
                    warn "$pkg not available in brew"
                fi
            done
        else
            failed=("${packages[@]}")
        fi
    else
        failed=("${packages[@]}")
        warn "No package manager found. Install manually: ${packages[*]}"
    fi

    if [ "${#failed[@]}" -gt 0 ]; then
        section "GitHub release fallbacks"
        local still_failed=()
        for pkg in "${failed[@]}"; do
            case "$pkg" in
                eza) install_github_binary "eza-community/eza" "eza" || still_failed+=("$pkg") ;;
                git-delta) install_github_binary "dandavison/delta" "delta" || still_failed+=("$pkg") ;;
                *) still_failed+=("$pkg") ;;
            esac
        done
        if [ "${#still_failed[@]}" -gt 0 ]; then
            warn "Could not install: ${still_failed[*]}"
        fi
    fi
}

ensure_delta_include() {
    local delta_include_path="$SCRIPT_DIR/config/delta.gitconfig"
    local gitconfig="$HOME/.gitconfig"

    if [ -f "$gitconfig" ] && grep -Fq "$delta_include_path" "$gitconfig"; then
        ok "Git delta include already present in ~/.gitconfig"
        return 0
    fi

    if ! confirm_change "Update ~/.gitconfig to include $delta_include_path"; then
        skip "Left ~/.gitconfig unchanged"
        return 0
    fi

    python3 - "$gitconfig" "$delta_include_path" <<'PY'
import sys
from pathlib import Path

gitconfig = Path(sys.argv[1])
delta_path = sys.argv[2]

if gitconfig.exists():
    lines = gitconfig.read_text().splitlines(keepends=True)
else:
    lines = []

out = []
i = 0
removed_old_delta_include = False
while i < len(lines):
    if lines[i].strip() == "[include]":
        block = [lines[i]]
        i += 1
        while i < len(lines) and not lines[i].lstrip().startswith("["):
            block.append(lines[i])
            i += 1
        if any("delta.gitconfig" in line for line in block):
            removed_old_delta_include = True
            continue
        out.extend(block)
    else:
        out.append(lines[i])
        i += 1

if out and out[-1].strip():
    out.append("\n")
out.extend(["[include]\n", f"\tpath = {delta_path}\n"])

gitconfig.write_text("".join(out))
print("updated" if removed_old_delta_include else "added")
PY
    ok "Ensured [include] for delta.gitconfig in ~/.gitconfig"
}

banner "Shell Setup"
printf '  %s %s\n' "$(paint "$CYAN" 'Shell folder:')" "$SCRIPT_DIR"
printf '  %s %s\n' "$(paint "$CYAN" 'Mode:')" "$(mode_label)"

section "Dependencies"
if command -v zsh >/dev/null 2>&1; then
    ok "zsh $(zsh --version | cut -d' ' -f2) found"
else
    warn "zsh not found"
    install_pkg zsh
fi

APT_PACKAGES=()
check_tool() {
    local name="$1" cmd="$2" pkg="$3"
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$name found"
    else
        warn "$name not found, package needed: $pkg"
        APT_PACKAGES+=("$pkg")
    fi
}

check_tool "bat"     "batcat" "bat"
check_tool "delta"   "delta"  "git-delta"
check_tool "eza"     "eza"    "eza"
check_tool "fd"      "fdfind" "fd-find"
check_tool "ripgrep" "rg"     "ripgrep"
check_tool "fzf"     "fzf"    "fzf"
check_tool "zoxide"  "zoxide" "zoxide"
install_missing_packages "${APT_PACKAGES[@]}"

section "Starship"
if command -v starship >/dev/null 2>&1; then
    ok "starship found: $(command -v starship)"
else
    warn "starship not found"
    if confirm_change "Install starship to ~/.local/bin via starship.rs installer"; then
        if ensure_dir "$HOME/.local/bin" "Create local bin directory"; then
            curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$HOME/.local/bin" -y
            ok "Starship installer completed"
        fi
    fi
fi

section "NVM"
if [ -d "$HOME/.nvm" ]; then
    ok "NVM found at ~/.nvm"
else
    warn "NVM not found"
    if confirm_change "Install NVM into ~/.nvm via upstream install script"; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        ok "NVM installed, restart shell to use"
    fi
fi

section "Shell rc files"
copy_shell_rc "$SCRIPT_DIR/config/bashrc" "$HOME/.bashrc"
copy_shell_rc "$SCRIPT_DIR/config/zshrc" "$HOME/.zshrc"

section "Tool-owned config symlinks"
symlink_config "$SCRIPT_DIR/config/starship.toml"  "$HOME/.config/starship.toml"
symlink_config "$SCRIPT_DIR/config/bat-env"        "$HOME/.config/bat/env"

section "Shell scripts"
if [ -d "$SCRIPT_DIR/scripts" ]; then
    for script in "$SCRIPT_DIR/scripts/"*; do
        [ -f "$script" ] || continue
        if [ "$DRY_RUN" = "1" ]; then
            dry "Would chmod +x $script"
        else
            chmod +x "$script"
        fi
        symlink_config "$script" "$HOME/.local/bin/$(basename "$script")"
    done
else
    skip "No scripts directory found"
fi

section "Git delta"
ensure_delta_include

section "PATH"
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ok "~/.local/bin already in PATH" ;;
    *) warn "~/.local/bin not in current PATH; copied bashrc/zshrc templates include it after shell restart" ;;
esac

echo ""
if [ "$DRY_RUN" = "1" ]; then
    dry "Shell install preview complete, no changes were made by this tool"
else
    ok "Shell installation complete"
fi
info "Shell rc files are local copies; tool-owned configs/scripts are symlinked"
info "Do not delete this folder while symlinked configs remain: $SCRIPT_DIR"
print_action_summary "Shell install summary"
rule
