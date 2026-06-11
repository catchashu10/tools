#!/usr/bin/env bash
# Shell setup installer
# Usage: <repo>/Shell/install.sh
#
# Installs CLI tools, copies machine-local shell rc templates, and symlinks
# tool-owned shell configs/scripts into place.
# Paths are resolved relative to this script so the repo folder can have any name.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup/helpers.sh"

copy_shell_rc() {
    local src="$1" dest="$2"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        warn "Backing up existing $dest -> $dest.bak.$timestamp"
        mv "$dest" "$dest.bak.$timestamp"
    fi

    cp "$src" "$dest"
    chmod 0644 "$dest"
    echo "  Copied $src -> $dest"
}

echo "=== Shell Setup Installer ==="
echo ""

# -- 1. install zsh ----------------------------------------------------------

step "Checking zsh..."
if command -v zsh >/dev/null 2>&1; then
    echo "  zsh $(zsh --version | cut -d' ' -f2) found"
else
    warn "zsh not found. Installing..."
    install_pkg zsh
fi

# -- 2. install CLI tools -----------------------------------------------------

step "Checking CLI tools..."

APT_PACKAGES=()

check_tool() {
    local name="$1" cmd="$2" pkg="$3"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  $name found"
    else
        echo "  $name not found — queuing install"
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

if [ ${#APT_PACKAGES[@]} -gt 0 ]; then
    step "Installing: ${APT_PACKAGES[*]}..."
    FAILED_PACKAGES=()
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        for pkg in "${APT_PACKAGES[@]}"; do
            if sudo apt install -y "$pkg" 2>/dev/null; then
                echo "  $pkg installed"
            else
                FAILED_PACKAGES+=("$pkg")
                warn "$pkg not available in apt repos — skipping"
            fi
        done
    elif command -v brew >/dev/null 2>&1; then
        for pkg in "${APT_PACKAGES[@]}"; do
            if brew install "$pkg" 2>/dev/null; then
                echo "  $pkg installed"
            else
                FAILED_PACKAGES+=("$pkg")
                warn "$pkg not available — skipping"
            fi
        done
    else
        FAILED_PACKAGES=("${APT_PACKAGES[@]}")
        warn "No package manager found. Install manually: ${APT_PACKAGES[*]}"
    fi
    # Fallback: try GitHub releases for packages not in apt/brew
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        step "Trying GitHub releases for: ${FAILED_PACKAGES[*]}..."
        STILL_FAILED=()
        for pkg in "${FAILED_PACKAGES[@]}"; do
            case "$pkg" in
                eza)       install_github_binary "eza-community/eza" "eza" || STILL_FAILED+=("$pkg") ;;
                git-delta) install_github_binary "dandavison/delta" "delta" || STILL_FAILED+=("$pkg") ;;
                *)         STILL_FAILED+=("$pkg") ;;
            esac
        done
        if [ ${#STILL_FAILED[@]} -gt 0 ]; then
            echo ""
            warn "Could not install: ${STILL_FAILED[*]}"
        fi
    fi
else
    echo "  All CLI tools already installed"
fi

# -- 3. install starship -----------------------------------------------------

step "Checking starship..."
if command -v starship >/dev/null 2>&1; then
    echo "  starship $(starship --version | head -1 | awk '{print $2}') found"
else
    warn "starship not found. Installing to ~/.local/bin/..."
    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$HOME/.local/bin" -y
fi

# -- 4. install NVM ----------------------------------------------------------

step "Checking NVM..."
if [ -d "$HOME/.nvm" ]; then
    echo "  NVM found at ~/.nvm"
else
    warn "NVM not found. Installing..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    echo "  NVM installed — restart shell to use"
fi

# -- 5. install shell config files -------------------------------------------

step "Installing shell config files..."
mkdir -p "$HOME/.config" "$HOME/.config/bat"

# ~/.bashrc and ~/.zshrc are copied, not symlinked, because shell rc files tend
# to drift per machine. The repo keeps good defaults for bootstrapping new
# systems, while each machine gets an editable local copy.
copy_shell_rc "$SCRIPT_DIR/config/bashrc" "$HOME/.bashrc"
copy_shell_rc "$SCRIPT_DIR/config/zshrc" "$HOME/.zshrc"

# Starship and bat env are tool-owned configs, so keeping them symlinked makes
# theme/tool updates flow through the repo cleanly.
symlink_config "$SCRIPT_DIR/config/starship.toml"  "$HOME/.config/starship.toml"
symlink_config "$SCRIPT_DIR/config/bat-env"        "$HOME/.config/bat/env"

# -- 6. symlink scripts to ~/.local/bin --------------------------------------

step "Linking scripts..."
mkdir -p "$HOME/.local/bin"

if [ -d "$SCRIPT_DIR/scripts" ]; then
    for script in "$SCRIPT_DIR/scripts/"*; do
        [ -f "$script" ] || continue
        chmod +x "$script"
        ln -s -f "$script" "$HOME/.local/bin/$(basename "$script")"
        echo "  ~/.local/bin/$(basename "$script") → $script"
    done
else
    echo "  No scripts directory found — skipping"
fi

# -- 7. git delta config -----------------------------------------------------

step "Checking git delta config..."
delta_include_path="$SCRIPT_DIR/config/delta.gitconfig"
python3 - "$HOME/.gitconfig" "$delta_include_path" <<'PY'
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
out.extend(["[include]\n", f"	path = {delta_path}\n"])

gitconfig.write_text("".join(out))
print("updated" if removed_old_delta_include else "added")
PY
echo "  Ensured [include] for delta.gitconfig in ~/.gitconfig"

# -- 8. ensure ~/.local/bin in PATH ------------------------------------------

step "Checking PATH..."
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo "  ~/.local/bin already in PATH"
else
    warn "~/.local/bin not in PATH — it will be after shell restart (set in bashrc/zshrc)"
fi

echo ""
step "Installation complete!"
echo ""
echo "  Shell rc files were copied to ~/.bashrc and ~/.zshrc."
echo "  They are machine-local now, so edits there will not dirty this repo."
echo "  Tool-owned configs/scripts are still symlinked to this repo."
echo "  DO NOT delete this folder ($SCRIPT_DIR) while symlinked configs remain."
echo ""
echo "  Installed tools:"
echo "    bat (batcat)  — syntax-highlighted cat"
echo "    delta         — beautiful side-by-side git diffs"
echo "    eza           — modern ls with icons"
echo "    fd (fdfind)   — fast file finder"
echo "    ripgrep (rg)  — fast grep"
echo "    fzf           — fuzzy finder (Ctrl-R, Ctrl-T, Alt-C)"
echo "    zoxide (z)    — smarter cd"
echo "    starship      — cross-shell prompt"
echo ""
echo "  Next steps:"
echo "    1. Restart your shell (or: source ~/.bashrc)"
echo "    2. Install Node.js: nvm install --lts"
echo ""
