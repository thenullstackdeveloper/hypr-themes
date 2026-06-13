#!/usr/bin/env bash
#
# uninstall.sh — remove the symlink + user config and restore the pristine
# .orig backups created on the first theme apply.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_CONFIG_DIR="$HOME/.config/hypr-themes"
BIN_DIR="$HOME/.local/bin"

# Load config dirs (fall back to defaults) so we restore the right paths.
if [[ -f "$USER_CONFIG_DIR/config.sh" ]]; then
    # shellcheck source=/dev/null
    source "$USER_CONFIG_DIR/config.sh"
fi
: "${HYPR_CONFIG_DIR:=$HOME/.config/hypr}"
: "${WOFI_CONFIG_DIR:=$HOME/.config/wofi}"
: "${DUNST_CONFIG_DIR:=$HOME/.config/dunst}"

# Shared path helpers (each_partial_target / each_base_target) — the same
# single source of truth bin/theme renders from.
# shellcheck source=/dev/null
source "$REPO_DIR/lib/paths.sh"

# 1. Generated partials (derived from templates/ — the same source bin/theme
#    renders from). Restore the ones that overwrote a pre-existing config
#    (.orig present, e.g. hyprpaper.conf); delete the ones created fresh.
removed=0
restored=0
while IFS= read -r target; do
    if [[ -f "$target.orig" ]]; then
        mv "$target.orig" "$target"; restored=$((restored + 1))
    elif [[ -e "$target" ]]; then
        rm -f "$target"; removed=$((removed + 1))
    fi
done < <(each_partial_target)

# 2. Base configs (derived from skeleton/): restore any pristine .orig left by
#    an older version that overwrote them. Current versions never touch these.
while IFS= read -r target; do
    if [[ -f "$target.orig" ]]; then
        mv "$target.orig" "$target"; restored=$((restored + 1))
    fi
done < <(each_base_target)

# Remove the symlink and user config.
rm -f "$BIN_DIR/theme"
rm -rf "$USER_CONFIG_DIR"

echo "hypr-themes uninstalled ($removed partials removed, $restored configs restored from .orig)."
echo "Note: base configs created from skeletons still hold an include line"
echo "(require/source/@import) pointing at the removed partials — edit or delete them."
echo "Daemons not restarted — reload them or relaunch your Hyprland session."
