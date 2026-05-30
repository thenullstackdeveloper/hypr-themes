# hypr-themes

> One-command theme switcher for Hyprland. Define a theme once, apply it across
> border, glow, wofi, dunst, hyprlock and wallpaper.

![shellcheck](https://github.com/thenullstackdeveloper/hypr-themes/actions/workflows/shellcheck.yml/badge.svg)
![license](https://img.shields.io/badge/license-MIT-blue.svg)

<!-- demo GIF here -->

## Quick start

```bash
git clone https://github.com/thenullstackdeveloper/hypr-themes ~/Projects/hypr-themes
cd ~/Projects/hypr-themes
./install.sh
theme          # interactive picker (wofi)
theme peach    # apply directly
```

## Why

Changing the color palette of a Hyprland setup means editing five files by hand
(`config.lua` border + glow, `hyprlock.conf`, `hyprpaper.conf`, `wofi/style.css`,
`dunst/dunstrc`). Forget one and your visuals drift.

hypr-themes keeps a single source of truth per theme and regenerates every config
from templates. One command. No drift.

## How it works

A `.theme` file is a set of `KEY=VALUE` color variables. The `theme` script sources
it, exports the variables, and renders each `templates/**/*.tmpl` with `envsubst`
into your live config, then reloads the affected daemons (`hyprctl reload`, dunst,
hyprpaper). wofi and hyprlock pick up their new CSS/config on next use.

Safety built in:

- **envsubst allowlist** — only theme variables are expanded, so unrelated tokens
  (e.g. hyprlock's `$FAIL` / `$ATTEMPTS`) are preserved.
- **Pristine `.orig` backups** — created once per file the first time it's themed,
  restored by `uninstall.sh`.
- **Lua validation** — generated `config.lua` is checked with `luac -p`; if it
  doesn't parse, the previous file is kept.

## Commands

```
theme <name>      Apply the theme <name>
theme             Interactive picker (wofi)
theme list        List available themes
theme current     Show the active theme
theme --help      Help
```

## Themes included

- `peach` — warm orange accent, fits retro / CRT / pixel-art wallpapers.
- `mauve` — purple accent, fits fantasy / dreamy wallpapers.

## Creating your own theme

Copy an existing theme and edit the colors:

```bash
cp themes/peach.theme themes/teal.theme
$EDITOR themes/teal.theme   # change ACCENT_*, BORDER_*, GLOW_COLOR, WALLPAPER
theme teal
```

Backgrounds and text use the Catppuccin Mocha base shared across themes; most new
themes only change the accent block and the wallpaper. `_HEX` and `_RGB` variants
are duplicated because some targets need `#RRGGBB` and others need `R, G, B`.

## Config

`./install.sh` copies `config.example.sh` to `~/.config/hypr-themes/config.sh`:

- `WALLPAPER_DIR` — folder holding your wallpapers; each theme references one by name.
- `DEFAULT_THEME` — applied on install / first run without arguments.
- `HYPR_CONFIG_DIR` / `WOFI_CONFIG_DIR` / `DUNST_CONFIG_DIR` — override only if your
  configs live outside `~/.config/<tool>`.

## Adding a Hyprland keybind

In your binds (not managed by this repo):

```lua
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("theme"))
```

## License

MIT
