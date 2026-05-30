#!/usr/bin/env bash
#
# record-demo.sh — record the theme-switch flow and turn it into an optimized,
# looping GIF for the README.
#
# Requires: wf-recorder, ffmpeg, the installed `theme` command, and (for the
# default region capture) slurp.
#
#   ./scripts/record-demo.sh             # AUTO: switches peach→mauve→peach itself
#   ./scripts/record-demo.sh -m          # MANUAL: you drive the switches
#   ./scripts/record-demo.sh -o DP-1     # capture a whole monitor (no slurp)
#
# AUTO mode is hands-off but the captured window stays unfocused, so its active
# border won't recolor (only the wallpaper changes).
#
# MANUAL mode lets you type the switches in the focused target terminal, so the
# active border + glow recolor too — and the command shows on screen. It starts
# recording, then watches `theme current`: once it sees mauve and then a switch
# back, it stops automatically (safety cap: MAX_WAIT seconds).
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_GIF="$REPO_DIR/screenshots/demo.gif"
TMP_VIDEO="$(mktemp --suffix=.mp4)"
TMP_PALETTE="$(mktemp --suffix=.png)"

# Tunables
FPS=14
WIDTH=960
HOLD=2.2          # AUTO: seconds each theme stays on screen
LEAD=4            # MANUAL: seconds to focus your terminal before recording
MAX_WAIT=40       # MANUAL: safety cap if you never switch

manual=0
monitor=""
while getopts ":o:mh" opt; do
    case "$opt" in
        o) monitor="$OPTARG" ;;
        m) manual=1 ;;
        h) echo "Usage: $0 [-m] [-o MONITOR]"; exit 0 ;;
        *) echo "Usage: $0 [-m] [-o MONITOR]" >&2; exit 1 ;;
    esac
done

for dep in wf-recorder ffmpeg theme; do
    command -v "$dep" >/dev/null 2>&1 || { echo "Missing dependency: $dep" >&2; exit 1; }
done

# Capture target: a whole monitor (-o) or an interactively selected region.
rec_args=()
if [[ -n "$monitor" ]]; then
    rec_args=(-o "$monitor")
    echo "Recording monitor: $monitor"
else
    command -v slurp >/dev/null 2>&1 || { echo "slurp not found; pass -o MONITOR instead." >&2; exit 1; }
    echo "Select the region to record (drag a box over a window on your wallpaper)…"
    geom="$(slurp)" || { echo "No region selected." >&2; exit 1; }
    rec_args=(-g "$geom")
fi

cleanup() { rm -f "$TMP_VIDEO" "$TMP_PALETTE"; }
trap cleanup EXIT

start_recorder() {
    wf-recorder "${rec_args[@]}" -f "$TMP_VIDEO" >/dev/null 2>&1 &
    rec_pid=$!
}

stop_recorder() {
    kill -INT "$rec_pid" 2>/dev/null || true
    wait "$rec_pid" 2>/dev/null || true
}

encode_gif() {
    echo "Encoding GIF…"
    mkdir -p "$(dirname "$OUT_GIF")"
    # Two-pass palette for clean colors at a small size.
    ffmpeg -y -i "$TMP_VIDEO" \
        -vf "fps=$FPS,scale=$WIDTH:-1:flags=lanczos,palettegen=stats_mode=diff" \
        "$TMP_PALETTE" >/dev/null 2>&1
    ffmpeg -y -i "$TMP_VIDEO" -i "$TMP_PALETTE" \
        -lavfi "fps=$FPS,scale=$WIDTH:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" \
        "$OUT_GIF" >/dev/null 2>&1
    echo "Done: $OUT_GIF ($(du -h "$OUT_GIF" | cut -f1))"
}

if (( manual )); then
    theme peach >/dev/null            # baseline state (before recording)
    echo "Focus the terminal you want to capture. Recording starts in ${LEAD}s…"
    sleep "$LEAD"
    start_recorder
    echo "● RECORDING — in your focused terminal run:  theme mauve   (wait ~2s)   theme peach"
    SECONDS=0
    seen_mauve=0
    while (( SECONDS < MAX_WAIT )); do
        cur="$(theme current 2>/dev/null || echo '')"
        [[ "$cur" == mauve ]] && seen_mauve=1
        if (( seen_mauve )) && [[ -n "$cur" && "$cur" != mauve ]]; then
            sleep 1.2                 # let the switch-back settle on screen
            break
        fi
        sleep 0.3
    done
    stop_recorder
else
    theme peach >/dev/null            # deterministic start, no reload flash on tape
    sleep 0.6
    echo "Recording… themes switch automatically (peach → mauve → peach)."
    start_recorder
    sleep 1.2
    sleep "$HOLD"
    theme mauve >/dev/null; sleep "$HOLD"
    theme peach >/dev/null; sleep 1.2
    stop_recorder
fi

encode_gif
