#!/usr/bin/env bats
#
# Render smoke test: every theme must render every template with no leftover
# ${VAR}. This guards the THEME_VARS allowlist — add a variable to a template
# but forget the allowlist and envsubst leaves it literal, failing here.

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    # Pull the real allowlist straight from the script (no sourcing needed).
    THEME_VARS="$(sed -n "s/^THEME_VARS='\(.*\)'/\1/p" "$REPO_DIR/bin/theme")"
}

# Render $1 (.theme) into $2 (.tmpl) and print the result.
render() {
    (
        set -a
        # shellcheck source=/dev/null
        source "$1"
        : "${WALLPAPER_DIR:=/wallpapers}"
        set +a
        envsubst "$THEME_VARS" < "$2"
    )
}

@test "THEME_VARS allowlist was extracted from bin/theme" {
    [ -n "$THEME_VARS" ]
    [[ "$THEME_VARS" == *'$ACCENT_PRIMARY'* ]]
    [[ "$THEME_VARS" == *'$WALLPAPER_DIR'* ]]
}

@test "every theme renders every template with no unsubstituted \${VAR}" {
    local theme tmpl out bad=0
    for theme in "$REPO_DIR"/themes/*.theme; do
        while IFS= read -r tmpl; do
            out="$(render "$theme" "$tmpl")"
            if [[ "$out" == *'${'* ]]; then
                echo "Unsubstituted var in $(basename "$theme") x $(basename "$tmpl"):"
                printf '%s\n' "$out" | grep -F '${' || true
                bad=1
            fi
        done < <(find "$REPO_DIR/templates" -type f -name '*.tmpl')
    done
    [ "$bad" -eq 0 ]
}

@test "the generated Lua partial is valid for every theme" {
    command -v luac >/dev/null 2>&1 || skip "luac not installed"
    local theme tmp="$BATS_TEST_TMPDIR/t.lua"
    for theme in "$REPO_DIR"/themes/*.theme; do
        render "$theme" "$REPO_DIR/templates/hypr/modules/theme.lua.tmpl" > "$tmp"
        run luac -p "$tmp"
        [ "$status" -eq 0 ]
    done
}
