#!/usr/bin/env bash
#
# install.sh — symlink the `theme` script, seed user config, apply default theme.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_CONFIG_DIR="$HOME/.config/hypr-themes"
BIN_DIR="$HOME/.local/bin"

# 1. Dependencies
missing=()
for cmd in hyprctl envsubst wofi dunst hyprpaper luac; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if (( ${#missing[@]} )); then
    echo "Error: missing dependencies: ${missing[*]}" >&2
    exit 1
fi

# 2. User config
mkdir -p "$USER_CONFIG_DIR"
if [[ ! -f "$USER_CONFIG_DIR/config.sh" ]]; then
    cp "$REPO_DIR/config.example.sh" "$USER_CONFIG_DIR/config.sh"
    echo "Created $USER_CONFIG_DIR/config.sh (edit WALLPAPER_DIR / DEFAULT_THEME)."
fi

# 3. Symlink the script
mkdir -p "$BIN_DIR"
ln -sfn "$REPO_DIR/bin/theme" "$BIN_DIR/theme"

# 4. PATH check
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "Note: $BIN_DIR is not in PATH. Add it to your shell rc."
fi

# 5. Apply default theme
# shellcheck source=/dev/null
source "$USER_CONFIG_DIR/config.sh"
"$REPO_DIR/bin/theme" "${DEFAULT_THEME:-peach}"

echo "hypr-themes installed. Use 'theme <name>' or 'theme' for the interactive picker."
