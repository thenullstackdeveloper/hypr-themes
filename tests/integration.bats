#!/usr/bin/env bats
#
# End-to-end against a sandbox $HOME with stubbed daemons: the real bin/theme
# and uninstall.sh run as processes and we check what lands on disk.

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR"
    HYPR="$HOME/.config/hypr"; WOFI="$HOME/.config/wofi"; DUNST="$HOME/.config/dunst"
    mkdir -p "$HYPR/modules" "$WOFI" "$DUNST/dunstrc.d" \
             "$HOME/.config/hypr-themes" "$HOME/.local/bin" "$HOME/walls" "$HOME/stub"
    : > "$HOME/walls/pic.jpg"
    cat > "$HOME/.config/hypr-themes/config.sh" <<EOF
WALLPAPER_DIR="$HOME/walls"
HYPR_CONFIG_DIR="$HYPR"
WOFI_CONFIG_DIR="$WOFI"
DUNST_CONFIG_DIR="$DUNST"
EOF
    # Stub the daemons so reload is a no-op and nothing real is touched.
    local t
    for t in hyprctl pkill setsid dunst hyprpaper wofi; do
        printf '#!/bin/sh\nexit 0\n' > "$HOME/stub/$t"; chmod +x "$HOME/stub/$t"
    done
    export PATH="$HOME/stub:$PATH"
}

@test "applying a theme writes the four color partials" {
    run "$REPO_DIR/bin/theme" peach
    [ "$status" -eq 0 ]
    [ -f "$HYPR/modules/theme.lua" ]
    [ -f "$HYPR/hyprlock-theme.conf" ]
    [ -f "$WOFI/colors.css" ]
    [ -f "$DUNST/dunstrc.d/99-hypr-themes.conf" ]
}

@test "no wallpaper override means hyprpaper.conf is left untouched" {
    run "$REPO_DIR/bin/theme" peach
    [ "$status" -eq 0 ]
    [ ! -e "$HYPR/hyprpaper.conf" ]
}

@test "a wallpaper override makes apply write hyprpaper.conf" {
    printf 'peach=pic.jpg\n' > "$HOME/.config/hypr-themes/wallpapers.conf"
    run "$REPO_DIR/bin/theme" peach
    [ "$status" -eq 0 ]
    [ -f "$HYPR/hyprpaper.conf" ]
    grep -q "pic.jpg" "$HYPR/hyprpaper.conf"
}

@test "the active symlink tracks the applied theme" {
    "$REPO_DIR/bin/theme" mauve
    run "$REPO_DIR/bin/theme" current
    [ "$output" = "mauve" ]
}

@test "uninstall removes fresh partials, the symlink and user config" {
    "$REPO_DIR/bin/theme" peach
    ln -sf "$REPO_DIR/bin/theme" "$HOME/.local/bin/theme"
    run "$REPO_DIR/uninstall.sh"
    [ "$status" -eq 0 ]
    [ ! -e "$HYPR/modules/theme.lua" ]
    [ ! -e "$WOFI/colors.css" ]
    [ ! -e "$HOME/.local/bin/theme" ]
    [ ! -e "$HOME/.config/hypr-themes" ]
}

@test "uninstall restores a .orig-backed config instead of deleting it" {
    echo ORIGINAL > "$HYPR/hyprpaper.conf"
    printf 'peach=pic.jpg\n' > "$HOME/.config/hypr-themes/wallpapers.conf"
    "$REPO_DIR/bin/theme" peach            # overwrites hyprpaper.conf, makes .orig
    [ -f "$HYPR/hyprpaper.conf.orig" ]
    run "$REPO_DIR/uninstall.sh"
    [ "$status" -eq 0 ]
    [ "$(cat "$HYPR/hyprpaper.conf")" = "ORIGINAL" ]
}
