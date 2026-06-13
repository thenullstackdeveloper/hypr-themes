# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/), versioning aims for
[SemVer](https://semver.org/).

## [Unreleased]

### Added
- `theme` CLI: apply a theme, `list`, `current`, `wallpaper`, `--help`, and theme
  browsing — a looping wofi picker (apply on pick and reopen, with keep / revert)
  plus `theme next` / `theme prev` to cycle (with a desktop notification), ideal
  for a keybind.
- Non-destructive theming: each switch regenerates a small tool-owned **color
  partial** per app — `hypr/modules/theme.lua`, `hypr/hyprlock-theme.conf`,
  `wofi/colors.css`, the `dunst/dunstrc.d/99-hypr-themes.conf` drop-in — which your
  own configs include via `require` / `source` / `@import` / drop-in. Your base
  configs (`config.lua`, `hyprlock.conf`, `style.css`, `dunstrc`) are never
  overwritten, so non-color settings (`kb_layout`, gaps, fonts, geometry…) survive
  every switch. `hyprpaper.conf` stays fully managed (it holds only the wallpaper).
- `skeleton/`: ready-made base configs with the include line wired up. `install.sh`
  copies one only when you don't already have that config; if you do, it leaves it
  alone and prints the single line to add.
- Themes: ten Catppuccin Mocha variants — `peach`, `mauve`, `pink`, `red`,
  `yellow`, `green`, `teal`, `sky`, `blue`, `lavender` (same base, different
  accent). Wallpapers are not bundled; each machine sets its own per theme with
  `theme wallpaper` (stored in `wallpapers.conf`).
- Guided `install.sh` wizard: prompts for `WALLPAPER_DIR` and default theme on a
  real terminal; silent `config.example.sh` copy when non-interactive.
- Interactive wallpaper association: applying a theme whose image is missing
  offers a picker of the files in `WALLPAPER_DIR`; the choice is saved per-user in
  `wallpapers.conf` and can be changed with `theme wallpaper <name>`.
- `scripts/check-deps.sh`: a reusable dependency checker (required vs recommended,
  with per-tool purpose and package hints) that `install.sh` runs before anything
  else, and that you can run standalone as a diagnostic.
- `uninstall.sh` and `config.example.sh` for user configuration.
- shellcheck CI workflow (covers `bin/`, the install/uninstall scripts and
  `scripts/`).

### Safety
- `envsubst` runs against an explicit variable allowlist (no accidental expansion
  of unrelated environment variables).
- Pristine `.orig` backups created once per target file; restored by `uninstall.sh`.
- Generated `theme.lua` is validated with `luac -p` before replacing the live partial.
- A missing wallpaper never writes a broken path: `hyprpaper.conf` is left
  untouched and the current wallpaper is kept.
- All prompts are gated on a real TTY, so `install.sh`, keybinds and pipes keep
  the non-interactive behavior.

### Internal
- `lib/paths.sh`: single source of truth for generated-file paths (`target_for`,
  `each_partial_target`, `each_base_target`). `install.sh` and `uninstall.sh` now
  derive the partial/skeleton paths from `templates/` and `skeleton/` instead of
  hardcoding them, so adding a target tool is just dropping a template.
- bats test suite (`tests/`) with a CI workflow: path mapping, a render smoke test
  that guards the `THEME_VARS` allowlist, cycle/override logic, and sandboxed
  apply/uninstall. `bin/theme` gained a `main` guard so it can be sourced for unit
  tests, and `luac` validation now only runs when `luac` is installed (it is a
  recommended, not required, dependency).
