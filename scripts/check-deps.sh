#!/usr/bin/env bash
#
# check-deps.sh — verify the tools hypr-themes needs are installed.
#
# Exits non-zero if a REQUIRED dependency is missing (envsubst). Recommended ones
# only disable a feature when absent. install.sh runs this first; you can also run
# it any time as a diagnostic:  ./scripts/check-deps.sh
#
set -euo pipefail

# cmd | what it's for | typical package | tier (required|recommended)
DEPS=(
    "envsubst|render the templates|gettext|required"
    "luac|validate the generated Lua config|lua|recommended"
    "hyprctl|reload Hyprland after applying|hyprland|recommended"
    "hyprpaper|set the wallpaper|hyprpaper|recommended"
    "wofi|interactive theme picker|wofi|recommended"
    "dunst|notification theming|dunst|recommended"
)

# Colors only when writing to a terminal.
if [[ -t 1 ]]; then
    c_g=$'\e[32m'; c_r=$'\e[31m'; c_y=$'\e[33m'; c_b=$'\e[1m'; c_0=$'\e[0m'
else
    c_g=""; c_r=""; c_y=""; c_b=""; c_0=""
fi
ok="${c_g}✓${c_0}"
bad="${c_r}✗${c_0}"

print_tier() {  # $1 = tier to print
    local entry cmd purpose pkg tier
    for entry in "${DEPS[@]}"; do
        IFS='|' read -r cmd purpose pkg tier <<< "$entry"
        [[ "$tier" == "$1" ]] || continue
        if command -v "$cmd" >/dev/null 2>&1; then
            printf '  %s %-11s %s\n' "$ok" "$cmd" "$purpose"
        else
            printf '  %s %-11s %s  %s→ pkg: %s%s\n' "$bad" "$cmd" "$purpose" "$c_y" "$pkg" "$c_0"
        fi
    done
}

missing_required=0
for entry in "${DEPS[@]}"; do
    IFS='|' read -r cmd _ _ tier <<< "$entry"
    if [[ "$tier" == required ]] && ! command -v "$cmd" >/dev/null 2>&1; then
        missing_required=$((missing_required + 1))
    fi
done

echo "${c_b}hypr-themes — dependency check${c_0}"
echo
echo "${c_b}Required${c_0}"
print_tier required
echo
echo "${c_b}Recommended${c_0} (missing ones just disable that part)"
print_tier recommended
echo

if (( missing_required > 0 )); then
    echo "${c_r}Result: ${missing_required} required dependency missing.${c_0}"
    echo "Package names vary by distro; the ones shown are for Arch/CachyOS."
    exit 1
fi
echo "${c_g}Result: all required dependencies present.${c_0}"
