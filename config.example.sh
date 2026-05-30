# hypr-themes user config.
# Copy to ~/.config/hypr-themes/config.sh and edit. Sourced by `theme`.

# Where your wallpapers live. Each theme references an image by name; the
# script resolves it as ${WALLPAPER_DIR}/${WALLPAPER}.
#
# Per-theme wallpaper overrides are stored separately (and managed for you) in
# ~/.config/hypr-themes/wallpapers.conf — written when you pick a wallpaper via
# the install prompt or `theme wallpaper <name>`. No need to edit it by hand.
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Theme applied on install / first run without arguments.
DEFAULT_THEME="peach"

# Destination config dirs — override only if your configs live elsewhere.
HYPR_CONFIG_DIR="$HOME/.config/hypr"
WOFI_CONFIG_DIR="$HOME/.config/wofi"
DUNST_CONFIG_DIR="$HOME/.config/dunst"
