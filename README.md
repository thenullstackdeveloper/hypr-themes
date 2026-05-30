# hypr-themes

> One-command theme switcher for Hyprland. Define a theme once, apply it across
> border, glow, wofi, dunst, hyprlock and wallpaper.

![shellcheck](https://github.com/thenullstackdeveloper/hypr-themes/actions/workflows/shellcheck.yml/badge.svg)
![license](https://img.shields.io/badge/license-MIT-blue.svg)

![hypr-themes switching between the peach and mauve themes](screenshots/demo.gif)

## ⚠️ Read before installing

This is a **personal theming setup made portable**, not a drop-in for every rig.
Two things to know up front:

- **It overwrites your Hyprland/wofi/dunst configs.** Applying a theme regenerates
  `config.lua`, `hyprlock.conf`, `hyprpaper.conf`, `wofi/style.css` and
  `dunst/dunstrc` from this repo's templates. The templates are *my* configs with
  the colors parameterized — installing them replaces yours. A pristine `.orig`
  backup of every file is made on first apply and restored by `uninstall.sh`, so
  it's reversible, but don't run it blind on a setup you care about.
- **Wallpapers are not bundled.** The repo stays light; themes reference an image
  *by name*. You point `WALLPAPER_DIR` at your own folder, and the installer (or
  `theme wallpaper`) helps you associate one. A theme with no matching image just
  keeps your current wallpaper — it never breaks.

If you want the switching mechanism but your own configs, fork it and replace the
files in `templates/` with yours (keep the `${VAR}` placeholders).

## Quick start

```bash
git clone https://github.com/thenullstackdeveloper/hypr-themes ~/Projects/hypr-themes
cd ~/Projects/hypr-themes
./install.sh        # guided: asks for your wallpaper folder + default theme
theme               # interactive picker (wofi)
theme peach         # apply directly
```

`install.sh` is a small wizard: it checks dependencies (via `scripts/check-deps.sh`,
which you can also run on its own), asks where your wallpapers live and which theme
to default to, symlinks `theme` into `~/.local/bin`, and applies your default
theme. Run it without a terminal (pipe/CI) and it falls back to copying
`config.example.sh` silently.

```bash
./scripts/check-deps.sh     # required vs recommended tools, with package hints
```

## Why

Changing the color palette of a Hyprland setup means editing five files by hand
(`config.lua` border + glow, `hyprlock.conf`, `hyprpaper.conf`, `wofi/style.css`,
`dunst/dunstrc`). Forget one and your visuals drift. hypr-themes keeps a single
source of truth per theme and regenerates every config from templates. One
command. No drift.

## Commands

```
theme <name>          Apply the theme <name>
theme                 Interactive picker (wofi)
theme list            List available themes
theme current         Show the active theme
theme wallpaper [n]   Pick/change the wallpaper for a theme (default: active)
theme --help          Help
```

## Wallpapers

Each theme names a wallpaper (e.g. `friki-salon.jpg`), resolved against your
`WALLPAPER_DIR`. When you apply a theme whose image isn't in that folder **and
you're in a terminal**, the script offers to associate one:

```
Theme 'peach' — Warm peach accent for retro/CRT/pixel-art wallpapers
No wallpaper found for this theme in /home/you/Pictures/Wallpapers.
Associate a wallpaper now? [Y/n] y
Images in /home/you/Pictures/Wallpapers:
   1) arbol.jpg
   2) cerezos.jpg
   ...
Choose a number, type a filename, or Enter to skip:
```

Your choice is saved per-user in `~/.config/hypr-themes/wallpapers.conf` (never in
the repo theme), so it sticks. Change it any time with `theme wallpaper <name>`.
Outside a terminal (keybind, pipe) nothing is asked — the current wallpaper is
kept and a warning is printed.

## Themes included

Ten themes, all sharing the Catppuccin Mocha base — they only differ in the accent
and the wallpaper, so they stay consistent across wofi, dunst and hyprlock.

| Theme | Accent | Pairs with |
|-------|--------|-----------|
| `peach` | warm orange | retro / CRT / pixel-art |
| `mauve` | purple | fantasy / dreamy |
| `pink` | bright pink | sakura / sunset / synthwave |
| `red` | red | sunset / autumn-maple / dramatic |
| `yellow` | gold | autumn / desert / sunny |
| `green` | green | forest / nature / foliage |
| `teal` | teal | turquoise / water / tropical / aurora |
| `sky` | cyan | clear-sky / glacier / snow |
| `blue` | azure | ocean / night-city / deep-space |
| `lavender` | periwinkle | dawn / soft-purple / misty |

Some themes ship without a default wallpaper; set one with `theme wallpaper <name>`.

## Creating your own theme

```bash
cp themes/peach.theme themes/teal.theme
$EDITOR themes/teal.theme   # change ACCENT_*, BORDER_*, GLOW_COLOR, WALLPAPER
theme teal
```

Backgrounds and text use the Catppuccin Mocha base shared across themes; most new
themes only change the accent block and the wallpaper. `_HEX` and `_RGB` variants
are duplicated because some targets need `#RRGGBB` and others need `R, G, B`.

## Reinstall / fresh machine

The installer is idempotent — re-run `./install.sh` any time (it won't clobber an
existing `config.sh` unless you choose to reconfigure). On a fresh machine:

```bash
git clone https://github.com/thenullstackdeveloper/hypr-themes ~/Projects/hypr-themes
cd ~/Projects/hypr-themes && ./install.sh
```

Then make sure your wallpapers are in `WALLPAPER_DIR` (or let the prompt associate
ones you have), and that `~/.local/bin` is on your `PATH` (the installer warns if
not). The `theme` symlink points at the repo, so if you move the repo, re-run the
installer to refresh it.

## Config

`install.sh` writes `~/.config/hypr-themes/config.sh`:

- `WALLPAPER_DIR` — folder holding your wallpapers.
- `DEFAULT_THEME` — applied on install / first run without arguments.
- `HYPR_CONFIG_DIR` / `WOFI_CONFIG_DIR` / `DUNST_CONFIG_DIR` — override only if your
  configs live outside `~/.config/<tool>`.

Per-theme wallpaper choices live in `~/.config/hypr-themes/wallpapers.conf`
(managed for you).

## Uninstall

```bash
./uninstall.sh   # restores the .orig backups, removes the symlink and user config
```

Daemons aren't restarted automatically — reload them or relaunch your Hyprland
session.

## Adding a Hyprland keybind

In your binds (not managed by this repo):

```lua
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("theme"))
```

## How it works

A `.theme` file is a set of `KEY=VALUE` color variables. `theme` sources it and
renders each `templates/**/*.tmpl` with `envsubst` into your live config, then
reloads the affected daemons. Safety built in: an **envsubst allowlist** (only
theme vars expand, so tokens like hyprlock's `$FAIL` survive), **pristine `.orig`
backups**, and **`luac -p` validation** of the generated `config.lua` before it
replaces the live file.

## License

MIT
