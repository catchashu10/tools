#!/usr/bin/env bash
# Tools — smoke test runner
#
# Purpose:
#   Run the lightweight checks used while maintaining this repo. The tests are
#   intended to be read-only, except for temporary directories created under /tmp.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=tools.conf
source "$SCRIPT_DIR/tools.conf"

PASS_COUNT=0
FAIL_COUNT=0

section() {
    printf '\n%s\n' '────────────────────────────────────────────────────────────'
    printf '● %s\n' "$1"
    printf '%s\n' '────────────────────────────────────────────────────────────'
}

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ✓ PASS  %s\n' "$1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  ✗ FAIL  %s\n' "$1" >&2
}

run() {
    local label="$1"
    shift
    if "$@"; then
        pass "$label"
    else
        fail "$label"
        return 1
    fi
}

run_to_file() {
    local label="$1" output_file="$2"
    shift 2
    if "$@" > "$output_file"; then
        pass "$label"
    else
        fail "$label"
        printf '    Output captured in: %s\n' "$output_file" >&2
        return 1
    fi
}

assert_grep() {
    local label="$1" pattern="$2" file="$3"
    if grep -Eq "$pattern" "$file"; then
        pass "$label"
    else
        fail "$label"
        printf '    Missing pattern: %s\n' "$pattern" >&2
        printf '    In file: %s\n' "$file" >&2
        return 1
    fi
}

tracked_shell_scripts() {
    git -C "$SCRIPT_DIR" ls-files '*.sh' | sort | sed "s#^#$SCRIPT_DIR/#"
}

all_shell_scripts() {
    find "$SCRIPT_DIR" -name '*.sh' -type f -print | sort
}

make_temp_home() {
    local tmp_home
    tmp_home="$(mktemp -d)"
    mkdir -p "$tmp_home/.config" "$tmp_home/.local/bin"
    printf '%s\n' "$tmp_home"
}

section "Shell syntax"
mapfile -t syntax_scripts < <(all_shell_scripts)
run "bash -n for ${#syntax_scripts[@]} shell scripts" bash -n "${syntax_scripts[@]}"
run "bash -n tools.conf" bash -n "$SCRIPT_DIR/tools.conf"

section "Help output"
install_help="$(mktemp)"
uninstall_help="$(mktemp)"
health_help="$(mktemp)"
trap 'rm -f "$install_help" "$uninstall_help" "$health_help"; [ -z "${tmp_home:-}" ] || rm -rf "$tmp_home"' EXIT
run_to_file "install help exits cleanly" "$install_help" "$SCRIPT_DIR/install.sh" --help
run_to_file "uninstall help exits cleanly" "$uninstall_help" "$SCRIPT_DIR/uninstall.sh" --help
run_to_file "health help exits cleanly" "$health_help" "$SCRIPT_DIR/health.sh" --help
for tool in "${TOOLS[@]}"; do
    assert_grep "install help lists $tool" "^  $tool$" "$install_help"
    assert_grep "uninstall help lists $tool" "^  $tool$" "$uninstall_help"
done
for check in "${HEALTH_CHECKS[@]}" "${EXTRA_HEALTH_CHECKS[@]}"; do
    assert_grep "health help lists $check" "^  $check$" "$health_help"
done

section "Read-only health"
health_output="$(mktemp)"
trap 'rm -f "$install_help" "$uninstall_help" "$health_help" "$health_output"; [ -z "${tmp_home:-}" ] || rm -rf "$tmp_home"' EXIT
run_to_file "default health exits cleanly" "$health_output" "$SCRIPT_DIR/health.sh" --no-color
assert_grep "health uses manifest default checks" "Checks: ${HEALTH_CHECKS[*]}" "$health_output"
assert_grep "health reports OK result" "Result: OK" "$health_output"
run_to_file "backup discovery exits cleanly" /tmp/tools-test-backups.out "$SCRIPT_DIR/health.sh" --no-color Backups
run_to_file "ShellCheck health exits cleanly" /tmp/tools-test-shellcheck.out "$SCRIPT_DIR/health.sh" --no-color ShellCheck

section "Dry-run smoke with temporary HOME"
tmp_home="$(make_temp_home)"
install_dry="$(mktemp)"
uninstall_dry="$(mktemp)"
direct_shell_dry="$(mktemp)"
trap 'rm -f "$install_help" "$uninstall_help" "$health_help" "$health_output" "$install_dry" "$uninstall_dry" "$direct_shell_dry"; [ -z "${tmp_home:-}" ] || rm -rf "$tmp_home"' EXIT
run_to_file "top-level install dry-run exits cleanly" "$install_dry" env HOME="$tmp_home" "$SCRIPT_DIR/install.sh" --dry-run --no-color
run_to_file "top-level uninstall dry-run exits cleanly" "$uninstall_dry" env HOME="$tmp_home" "$SCRIPT_DIR/uninstall.sh" --dry-run --no-color
run_to_file "direct Shell install dry-run exits cleanly" "$direct_shell_dry" env HOME="$tmp_home" "$SCRIPT_DIR/Shell/install.sh" --dry-run --no-color
assert_grep "install dry-run uses manifest install order" "Tools: ${INSTALL_ORDER[*]}" "$install_dry"
assert_grep "uninstall dry-run uses manifest uninstall order" "Tools: ${UNINSTALL_ORDER[*]}" "$uninstall_dry"
assert_grep "install dry-run shows elapsed time" "Completed in [0-9]+s" "$install_dry"
assert_grep "uninstall dry-run shows elapsed time" "Completed in [0-9]+s" "$uninstall_dry"
assert_grep "direct Shell dry-run shows summary" "Shell install summary" "$direct_shell_dry"
if grep -q 'INFO  Later:' "$direct_shell_dry"; then
    fail "dry-run output should not include Later hints"
    exit 1
else
    pass "dry-run output omits Later hints"
fi

section "Hardcoded path scan"
if grep -RIn --include='*.sh' --exclude='test.sh' -E '(/home/[^[:space:]]+|~/Tools|~/tools)' "$SCRIPT_DIR"; then
    fail "shell scripts contain hardcoded home/repo paths"
    exit 1
else
    pass "no hardcoded home/repo paths in shell scripts"
fi

section "Optional direct ShellCheck"
if command -v shellcheck >/dev/null 2>&1; then
    mapfile -t shellcheck_scripts < <(tracked_shell_scripts)
    if [ -x "$SCRIPT_DIR/test.sh" ]; then
        shellcheck_scripts+=("$SCRIPT_DIR/test.sh")
    fi
    run "shellcheck for tracked scripts plus test.sh" shellcheck -x -e SC1091 -e SC2034 -e SC2088 -e SC2016 "${shellcheck_scripts[@]}"
else
    pass "shellcheck not installed, skipped optional direct ShellCheck"
fi

section "Summary"
printf '  PASS %s\n' "$PASS_COUNT"
printf '  FAIL %s\n' "$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    printf '\nResult: FAIL\n' >&2
    exit 1
fi

printf '\nResult: OK\n'
