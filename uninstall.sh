#!/usr/bin/env bash
#
# uninstall.sh — remove the symlink + user config and restore the pristine
# .orig backups created on the first theme apply.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$REPO_DIR/templates"
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

target_for() {
    local rel="$1" tool="${1%%/*}" sub="${1#*/}"
    case "$tool" in
        hypr)  echo "$HYPR_CONFIG_DIR/$sub" ;;
        wofi)  echo "$WOFI_CONFIG_DIR/$sub" ;;
        dunst) echo "$DUNST_CONFIG_DIR/$sub" ;;
        *)     echo "$HOME/.config/$rel" ;;
    esac
}

# Restore pristine backups.
restored=0
while IFS= read -r tmpl; do
    rel="${tmpl#"$TEMPLATES_DIR"/}"; rel="${rel%.tmpl}"
    target="$(target_for "$rel")"
    if [[ -f "$target.orig" ]]; then
        mv "$target.orig" "$target"
        restored=$((restored + 1))
    fi
done < <(find "$TEMPLATES_DIR" -type f -name '*.tmpl')

# Remove the symlink and user config.
rm -f "$BIN_DIR/theme"
rm -rf "$USER_CONFIG_DIR"

echo "hypr-themes uninstalled ($restored configs restored from .orig)."
echo "Daemons not restarted — reload them or relaunch your Hyprland session."
