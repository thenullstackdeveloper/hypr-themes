#!/usr/bin/env bats
#
# lib/paths.sh — the single source of truth for generated-file destinations.

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    HYPR_CONFIG_DIR="/cfg/hypr"
    WOFI_CONFIG_DIR="/cfg/wofi"
    DUNST_CONFIG_DIR="/cfg/dunst"
    # shellcheck source=/dev/null
    source "$REPO_DIR/lib/paths.sh"
}

@test "target_for maps the hypr tool dir" {
    [ "$(target_for "hypr/modules/theme.lua")" = "/cfg/hypr/modules/theme.lua" ]
}

@test "target_for maps the wofi tool dir" {
    [ "$(target_for "wofi/colors.css")" = "/cfg/wofi/colors.css" ]
}

@test "target_for maps the dunst tool dir (nested)" {
    [ "$(target_for "dunst/dunstrc.d/99-hypr-themes.conf")" = "/cfg/dunst/dunstrc.d/99-hypr-themes.conf" ]
}

@test "target_for falls back to ~/.config for an unknown tool" {
    [ "$(target_for "kitty/colors.conf")" = "$HOME/.config/kitty/colors.conf" ]
}

@test "each_partial_target lists every template destination" {
    run each_partial_target
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep -c .)" -eq 5 ]
    [[ "$output" == *"/cfg/hypr/modules/theme.lua"* ]]
    [[ "$output" == *"/cfg/hypr/hyprlock-theme.conf"* ]]
    [[ "$output" == *"/cfg/hypr/hyprpaper.conf"* ]]
    [[ "$output" == *"/cfg/wofi/colors.css"* ]]
    [[ "$output" == *"/cfg/dunst/dunstrc.d/99-hypr-themes.conf"* ]]
}

@test "each_base_target lists every skeleton destination" {
    run each_base_target
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep -c .)" -eq 4 ]
    [[ "$output" == *"/cfg/hypr/modules/config.lua"* ]]
    [[ "$output" == *"/cfg/hypr/hyprlock.conf"* ]]
    [[ "$output" == *"/cfg/wofi/style.css"* ]]
    [[ "$output" == *"/cfg/dunst/dunstrc"* ]]
}
