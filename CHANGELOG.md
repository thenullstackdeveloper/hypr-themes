# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/), versioning aims for
[SemVer](https://semver.org/).

## [Unreleased]

### Added
- `theme` CLI: apply a theme, `list`, `current`, `wallpaper`, interactive wofi
  picker, `--help`.
- Templates for Hyprland (`config.lua`, `hyprlock.conf`, `hyprpaper.conf`), wofi
  (`style.css`) and dunst (`dunstrc`), rendered with `envsubst`.
- Themes: `peach` (Catppuccin Mocha + peach accent) and `mauve` (mauve accent).
- Guided `install.sh` wizard: prompts for `WALLPAPER_DIR` and default theme on a
  real terminal; silent `config.example.sh` copy when non-interactive.
- Interactive wallpaper association: applying a theme whose image is missing
  offers a picker of the files in `WALLPAPER_DIR`; the choice is saved per-user in
  `wallpapers.conf` and can be changed with `theme wallpaper <name>`.
- `uninstall.sh` and `config.example.sh` for user configuration.
- shellcheck CI workflow.

### Safety
- `envsubst` runs against an explicit variable allowlist (no accidental expansion
  of unrelated environment variables).
- Pristine `.orig` backups created once per target file; restored by `uninstall.sh`.
- Generated `config.lua` is validated with `luac -p` before replacing the live file.
- A missing wallpaper never writes a broken path: `hyprpaper.conf` is left
  untouched and the current wallpaper is kept.
- All prompts are gated on a real TTY, so `install.sh`, keybinds and pipes keep
  the non-interactive behavior.
