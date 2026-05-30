# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/), versioning aims for
[SemVer](https://semver.org/).

## [Unreleased]

### Added
- `theme` CLI: apply a theme, `list`, `current`, interactive wofi picker, `--help`.
- Templates for Hyprland (`config.lua`, `hyprlock.conf`, `hyprpaper.conf`), wofi
  (`style.css`) and dunst (`dunstrc`), rendered with `envsubst`.
- Themes: `peach` (Catppuccin Mocha + peach accent) and `mauve` (mauve accent).
- `install.sh` / `uninstall.sh` and `config.example.sh` for user configuration.
- shellcheck CI workflow.

### Safety
- `envsubst` runs against an explicit variable allowlist (no accidental expansion
  of unrelated environment variables).
- Pristine `.orig` backups created once per target file; restored by `uninstall.sh`.
- Generated `config.lua` is validated with `luac -p` before replacing the live file.
