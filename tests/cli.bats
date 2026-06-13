#!/usr/bin/env bats
#
# CLI logic: cycle math and wallpaper-override resolution. We source bin/theme
# (its dispatch is guarded by a main() so sourcing is side-effect free) and, for
# the cycle tests, stub the functions that touch the system so we test the logic
# in isolation. bats re-runs setup() before each test, so stubs are per-test.
#
# Sorted theme list: blue green lavender mauve peach pink red sky teal yellow

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR"
    # shellcheck source=/dev/null
    source "$REPO_DIR/bin/theme"
}

# Replace the side-effecting calls cmd_cycle makes with harmless stubs.
stub_cycle() {
    cmd_apply()    { echo "APPLIED $1"; }
    notify_theme() { :; }
}

@test "cmd_cycle next wraps from the last theme to the first" {
    stub_cycle
    cmd_current() { echo "yellow"; }
    run cmd_cycle next
    [ "$status" -eq 0 ]
    [[ "$output" == *"APPLIED blue"* ]]
}

@test "cmd_cycle prev wraps from the first theme to the last" {
    stub_cycle
    cmd_current() { echo "blue"; }
    run cmd_cycle prev
    [[ "$output" == *"APPLIED yellow"* ]]
}

@test "cmd_cycle next advances one step in the middle" {
    stub_cycle
    cmd_current() { echo "green"; }
    run cmd_cycle next
    [[ "$output" == *"APPLIED lavender"* ]]
}

@test "cmd_cycle prev steps back in the middle" {
    stub_cycle
    cmd_current() { echo "mauve"; }
    run cmd_cycle prev
    [[ "$output" == *"APPLIED lavender"* ]]
}

@test "wallpaper_override returns the saved file for a theme" {
    WALLPAPERS_CONF="$BATS_TEST_TMPDIR/wallpapers.conf"
    printf 'green=forest.jpg\nred=rosas.jpg\n' > "$WALLPAPERS_CONF"
    [ "$(wallpaper_override green)" = "forest.jpg" ]
    [ "$(wallpaper_override red)" = "rosas.jpg" ]
}

@test "wallpaper_override is empty for a theme with no override" {
    WALLPAPERS_CONF="$BATS_TEST_TMPDIR/wallpapers.conf"
    printf 'green=forest.jpg\n' > "$WALLPAPERS_CONF"
    [ -z "$(wallpaper_override blue)" ]
}

@test "wallpaper_override is empty when no override file exists" {
    WALLPAPERS_CONF="$BATS_TEST_TMPDIR/nope.conf"
    [ -z "$(wallpaper_override green)" ]
}

@test "applying an unknown theme fails with a clear message" {
    run cmd_apply does-not-exist
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}
