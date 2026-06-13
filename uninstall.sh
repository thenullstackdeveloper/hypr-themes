#!/usr/bin/env bash
#
# uninstall.sh — remove the symlink + user config and restore the pristine
# .orig backups created on the first theme apply.
#
set -euo pipefail

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

# 1. Remove the generated theme partials (tool-owned — safe to delete).
removed=0
for p in \
    "$HYPR_CONFIG_DIR/modules/theme.lua" \
    "$HYPR_CONFIG_DIR/hyprlock-theme.conf" \
    "$WOFI_CONFIG_DIR/colors.css" \
    "$DUNST_CONFIG_DIR/dunstrc.d/99-hypr-themes.conf"; do
    [[ -e "$p" ]] && { rm -f "$p"; removed=$((removed + 1)); }
done

# 2. Restore pristine .orig backups where present. These cover hyprpaper.conf
#    (still fully managed) and any base config that existed before install.
restored=0
for base in \
    "$HYPR_CONFIG_DIR/hyprpaper.conf" \
    "$HYPR_CONFIG_DIR/hyprlock.conf" \
    "$HYPR_CONFIG_DIR/modules/config.lua" \
    "$WOFI_CONFIG_DIR/style.css" \
    "$DUNST_CONFIG_DIR/dunstrc"; do
    if [[ -f "$base.orig" ]]; then
        mv "$base.orig" "$base"
        restored=$((restored + 1))
    fi
done

# Remove the symlink and user config.
rm -f "$BIN_DIR/theme"
rm -rf "$USER_CONFIG_DIR"

echo "hypr-themes uninstalled ($removed partials removed, $restored configs restored from .orig)."
echo "Note: base configs created from skeletons still hold an include line"
echo "(require/source/@import) pointing at the removed partials — edit or delete them."
echo "Daemons not restarted — reload them or relaunch your Hyprland session."
