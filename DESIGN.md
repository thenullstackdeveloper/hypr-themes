# hypr-themes — Design Document

> Diseño del proyecto **hypr-themes**: theme switcher para Hyprland. Documento
> autocontenido para arrancar la implementación en una sesión nueva (con agentes
> dedicados de programación si procede).

Generado en `2026-05-27` a partir del bloque 12 del [[Hyprland CachyOS Setup]] (vault Obsidian).

> **Revisión 2026-06-13 — arquitectura no destructiva (parciales).**
> El diseño original (abajo) regeneraba *el config completo* de cada app desde una
> plantilla (`config.lua`, `hyprlock.conf`, `style.css`, `dunstrc`), por lo que la
> herramienta era dueña de ficheros que también contienen ajustes personales
> (`kb_layout`/`kb_variant`, gaps, fuentes…) y los pisaba en cada cambio de tema.
>
> Ahora la herramienta **solo genera un parcial de color por app** y el config del
> usuario lo incluye con el mecanismo nativo de cada uno:
> - Hyprland → `modules/theme.lua` (`require`)
> - hyprlock → `hyprlock-theme.conf` (`source =`)
> - wofi → `colors.css` (`@import`, ruta **absoluta**: wofi pasa el CSS a GTK como
>   blob sin directorio base, así que un `@import` relativo no resuelve)
> - dunst → `dunstrc.d/99-hypr-themes.conf` (drop-in, sin tocar `dunstrc`)
> - hyprpaper → sigue como plantilla completa (solo contiene el wallpaper)
>
> Los configs base se entregan como **skeletons** (`skeleton/`) que `install.sh`
> copia solo si no existen; si existen, no los toca y muestra la línea a añadir.
> Esto invalida la meta de "regenerar bit-identical" de §5 y la lista de plantillas
> de §5/anexo: las plantillas de fichero completo ya no existen.

---

## 1. Resumen ejecutivo

**Problema**: cambiar la paleta de colores de un setup Hyprland implica editar 4+ archivos
de configuración (border, glow, wofi, dunst, hyprlock, hyprpaper). Cada vez. Repetitivo y
propenso a olvidar componentes.

**Solución**: definir un **tema** (KEY=VALUE) que captura todas las decisiones cromáticas
(+ wallpaper asociado). Un script `theme <name>` regenera todos los configs desde
plantillas via `envsubst` y recarga los daemons. Cambiar de tema = un comando.

**Público objetivo**: usuarios Hyprland que quieran iterar visualmente sin fricción.

**Modo portfolio**: el repo va a vivir en `github.com/thenullstackdeveloper/hypr-themes`
público. Cuidar README, commits atómicos, CI con shellcheck, demo GIF.

---

## 2. Decisiones tomadas

| # | Decision | Valor |
|---|----------|-------|
| 1 | URL del repo | `github.com/thenullstackdeveloper/hypr-themes` |
| 2 | Licencia | MIT |
| 3 | Ubicación local | `~/Projects/hypr-themes/` |
| 4 | Naming de temas | Por color (peach, mauve, teal, ...) — universal |
| 5 | Wallpapers en repo | **NO**. Repo ligero. Path configurable por usuario |
| 6 | Scope | Solo theme switcher ahora. Crecerá a dotfiles en repo aparte si surge |
| 7 | Wallpaper por tema | **SÍ**. Tema referencia nombre, script combina con `WALLPAPER_DIR` |
| 8 | Templating | `envsubst` (estándar, simple) |
| 9 | Script lenguaje | Bash con `set -euo pipefail`, shellcheck-clean |
| 10 | Branch principal | `main` |
| 11 | Conventional commits | `feat:`, `fix:`, `docs:`, `chore:`, `ci:` |
| 12 | Initial commit strategy | Incremental (~11 commits atómicos), no megacommit |

---

## 3. Arquitectura

### 3.1 Estructura del repo

```
~/Projects/hypr-themes/
├── README.md                  # demo GIF + quick start + why
├── DESIGN.md                  # este documento (puede mover a docs/)
├── CHANGELOG.md
├── LICENSE                    # MIT
├── .gitignore
├── .github/workflows/
│   └── shellcheck.yml         # CI: lint en cada PR
├── bin/
│   └── theme                  # script principal
├── themes/
│   ├── peach.theme            # KEY=VALUE
│   ├── mauve.theme
│   └── teal.theme             # futuro
├── templates/
│   ├── hypr/
│   │   ├── modules/config.lua.tmpl
│   │   ├── hyprlock.conf.tmpl
│   │   └── hyprpaper.conf.tmpl
│   ├── wofi/style.css.tmpl
│   └── dunst/dunstrc.tmpl
├── config.example.sh          # user customiza: WALLPAPER_DIR, DEFAULT_THEME
├── install.sh
├── uninstall.sh               # reverse del install (importante)
└── screenshots/
    ├── peach.png
    ├── mauve.png
    └── demo.gif
```

### 3.2 Flujo del switcher

```
theme peach
  │
  ├─ source ~/.config/hypr-themes/config.sh         # WALLPAPER_DIR, ...
  ├─ source themes/peach.theme                       # ACCENT_*, BG_*, FG_*, WALLPAPER, ...
  ├─ for each .tmpl in templates/:
  │     envsubst < templates/X.tmpl > $HOME/.config/X
  ├─ update symlink ~/.config/hypr-themes/.active → themes/peach.theme
  ├─ hyprctl reload                                  # Hyprland + glow + border
  ├─ pkill -x dunst && dunst &                       # dunst no recarga sin SIGTERM
  ├─ pkill -9 -x hyprpaper && hyprpaper &            # hyprpaper recoge nuevo config
  └─ echo "Theme: peach"
```

wofi y hyprlock recogen el nuevo CSS/config al siguiente uso (no son daemons que mantener).

### 3.3 Templating con envsubst

Plantilla:
```
border = ${ACCENT_PRIMARY}
background = ${BG_BASE}
```

Con vars exportadas (ACCENT_PRIMARY=#fab387, BG_BASE=#1e1e2e), `envsubst < tmpl > real`:
```
border = #fab387
background = #1e1e2e
```

Simple, estándar GNU, sin deps extras.

### 3.4 Configuración personalizable

`config.example.sh` (committed):

```sh
# Copia a ~/.config/hypr-themes/config.sh y edita

# Donde viven tus wallpapers. Cada tema referencia por nombre,
# el script los combina: ${WALLPAPER_DIR}/${WALLPAPER}
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Tema aplicado al instalar/primera ejecución sin args
DEFAULT_THEME="peach"

# Rutas destino (override si tu Hyprland config vive en otro sitio)
HYPR_CONFIG_DIR="$HOME/.config/hypr"
WOFI_CONFIG_DIR="$HOME/.config/wofi"
DUNST_CONFIG_DIR="$HOME/.config/dunst"
```

---

## 4. Formato de tema (.theme)

Un archivo bash-sourcable con KEY=VALUE. Variables divididas en grupos:

```sh
# themes/peach.theme

# ============================================================
#  IDENTIDAD
# ============================================================
THEME_NAME="peach"
THEME_DESCRIPTION="Warm peach accent for retro/CRT aesthetic wallpapers"

# ============================================================
#  WALLPAPER
# ============================================================
WALLPAPER="friki-salon.jpg"   # referenciado por nombre, dir global

# ============================================================
#  ACCENT (color principal del tema)
# ============================================================
ACCENT_HEX="fab387"           # sin #, para rgba() Hyprland
ACCENT_RGB="250, 179, 135"    # decimal, para hyprlock rgba(R, G, B, A)
ACCENT_PRIMARY="#fab387"      # con #, para CSS / dunst
ACCENT_SECONDARY="#f9e2af"    # gradient end del border
ACCENT_SECONDARY_HEX="f9e2af"

# Borde Hyprland (active_border)
BORDER_COLOR_1="rgba(fab387ee)"
BORDER_COLOR_2="rgba(f9e2afee)"
BORDER_ANGLE="45"

# Glow (decoration.glow.color)
GLOW_COLOR="rgba(fab38780)"   # accent + alpha 0x80

# ============================================================
#  BASE (fondos y textos - Catppuccin Mocha base)
# ============================================================
BG_BASE_HEX="#1e1e2e"
BG_BASE_RGB="30, 30, 46"
BG_MANTLE_HEX="#181825"
BG_MANTLE_RGB="24, 24, 37"
BG_CRUST_HEX="#11111b"
BG_SURFACE0_HEX="#313244"     # input fields
BG_SURFACE1_HEX="#45475a"     # borders sutiles

FG_TEXT_HEX="#cdd6f4"
FG_TEXT_RGB="205, 214, 244"
FG_SUBTEXT0_HEX="#a6adc8"     # urgency low
FG_SUBTEXT1_HEX="#bac2de"

# ============================================================
#  COLORES SEMANTICOS (alertas)
# ============================================================
COLOR_RED_HEX="#f38ba8"       # urgency critical
COLOR_RED_RGB="243, 139, 168"
COLOR_GREEN_HEX="#a6e3a1"
COLOR_YELLOW_HEX="#f9e2af"
COLOR_OVERLAY_HEX="#6c7086"   # urgency low frame, inactive border
```

> **Por qué duplicar HEX/RGB**: `envsubst` no permite funciones. Hyprlock necesita
> `rgba(R, G, B, A)` (decimal), otros usan `#XXXXXX`. Duplicar en el .theme es más simple
> que escribir un conversor hex→rgb en bash.

---

## 5. Plantillas (templates/)

Las plantillas son los configs **actuales** del usuario con valores literales reemplazados
por `${VARS}`. Pipeline para crear cada una:

1. Coger config actual
2. Identificar cada hex/color usado
3. Sustituir por la var correspondiente
4. Verificar que `envsubst` con peach.theme regenera **bit-identical** el config original

### 5.1 templates/hypr/modules/config.lua.tmpl

Vive en repo. Genera `~/.config/hypr/modules/config.lua`.

**Cambios desde el config actual** (`~/.config/hypr/modules/config.lua`):

```lua
-- Original
active_border = { colors = { "rgba(fab387ee)", "rgba(f9e2afee)" }, angle = 45 },
glow = {
    enabled = true,
    color = "rgba(fab38780)",
},

-- Template
active_border = { colors = { "${BORDER_COLOR_1}", "${BORDER_COLOR_2}" }, angle = ${BORDER_ANGLE} },
glow = {
    enabled = true,
    color = "${GLOW_COLOR}",
},
```

Resto del archivo igual (gaps, blur, shadow, rounding NO se tematizan en v1).

### 5.2 templates/hypr/hyprlock.conf.tmpl

Genera `~/.config/hypr/hyprlock.conf`.

**Sustituciones**:
- `background.color = rgba(24, 24, 37, 1.0)` → `rgba(${BG_MANTLE_RGB}, 1.0)`
- `label.color = rgba(205, 214, 244, 1.0)` → `rgba(${FG_TEXT_RGB}, 1.0)`
- `label.color = rgba(205, 214, 244, 0.7)` → `rgba(${FG_TEXT_RGB}, 0.7)`
- `input.outer_color = rgba(250, 179, 135, 1.0)` → `rgba(${ACCENT_RGB}, 1.0)`
- `input.inner_color = rgba(30, 30, 46, 1.0)` → `rgba(${BG_BASE_RGB}, 1.0)`
- `input.font_color = rgba(205, 214, 244, 1.0)` → `rgba(${FG_TEXT_RGB}, 1.0)`
- `input.fail_color = rgba(243, 139, 168, 1.0)` → `rgba(${COLOR_RED_RGB}, 1.0)`

### 5.3 templates/hypr/hyprpaper.conf.tmpl

Genera `~/.config/hypr/hyprpaper.conf`.

**Template completo**:
```
wallpaper {
    monitor =
    path = ${WALLPAPER_DIR}/${WALLPAPER}
    fit_mode = cover
}
```

`WALLPAPER_DIR` viene de `config.sh`, `WALLPAPER` del .theme.

### 5.4 templates/wofi/style.css.tmpl

Genera `~/.config/wofi/style.css`.

**Sustituciones desde el style.css actual**:
- `#fab387` (accent border + selected bg) → `${ACCENT_PRIMARY}`
- `#1e1e2e` (window bg, entry:selected text) → `${BG_BASE_HEX}`
- `#cdd6f4` (text) → `${FG_TEXT_HEX}`
- `#313244` (input bg) → `${BG_SURFACE0_HEX}`
- `#45475a` (input border) → `${BG_SURFACE1_HEX}`

### 5.5 templates/dunst/dunstrc.tmpl

Genera `~/.config/dunst/dunstrc`.

**Sustituciones**:
- `frame_color = "#fab387"` (global y urgency_normal) → `${ACCENT_PRIMARY}`
- `background = "#1e1e2e"` → `${BG_BASE_HEX}`
- `foreground = "#cdd6f4"` (normal/critical) → `${FG_TEXT_HEX}`
- `foreground = "#a6adc8"` (low) → `${FG_SUBTEXT0_HEX}`
- `frame_color = "#6c7086"` (low) → `${COLOR_OVERLAY_HEX}`
- `frame_color = "#f38ba8"` (critical) → `${COLOR_RED_HEX}`

---

## 6. Script `bin/theme`

### 6.1 API CLI

```
theme <name>                  Aplica el tema <name>
theme                          Sin args: wofi picker, eliges y aplica
theme list                     Lista temas disponibles
theme current                  Muestra el tema activo ahora
theme --help                   Ayuda
```

### 6.2 Estructura del script

```bash
#!/usr/bin/env bash
set -euo pipefail

# Constantes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
USER_CONFIG_DIR="$HOME/.config/hypr-themes"
ACTIVE_LINK="$USER_CONFIG_DIR/.active"

# Cargar config de usuario (WALLPAPER_DIR, etc.)
if [[ -f "$USER_CONFIG_DIR/config.sh" ]]; then
    # shellcheck source=/dev/null
    source "$USER_CONFIG_DIR/config.sh"
else
    echo "Error: $USER_CONFIG_DIR/config.sh not found. Run install.sh first." >&2
    exit 1
fi

# Defaults si user config no los define
: "${WALLPAPER_DIR:=$HOME/Pictures/Wallpapers}"
: "${DEFAULT_THEME:=peach}"
: "${HYPR_CONFIG_DIR:=$HOME/.config/hypr}"
: "${WOFI_CONFIG_DIR:=$HOME/.config/wofi}"
: "${DUNST_CONFIG_DIR:=$HOME/.config/dunst}"

# Subcomandos
cmd_list() { ... }
cmd_current() { ... }
cmd_apply() { ... }      # core: source theme + envsubst loop + reload
cmd_interactive() { ... }  # wofi picker

# Routing
case "${1:-}" in
    list) cmd_list ;;
    current) cmd_current ;;
    --help|-h) cmd_help ;;
    "") cmd_interactive ;;
    *) cmd_apply "$1" ;;
esac
```

### 6.3 Pipeline de apply (core)

```bash
cmd_apply() {
    local theme="$1"
    local theme_file="$REPO_DIR/themes/${theme}.theme"

    if [[ ! -f "$theme_file" ]]; then
        echo "Error: theme '$theme' not found" >&2
        echo "Available themes:" >&2
        cmd_list >&2
        exit 1
    fi

    # Source theme (export vars)
    set -a
    # shellcheck source=/dev/null
    source "$theme_file"
    set +a

    # Verify wallpaper exists
    if [[ -n "${WALLPAPER:-}" ]] && [[ ! -f "$WALLPAPER_DIR/$WALLPAPER" ]]; then
        echo "Warning: wallpaper $WALLPAPER not found in $WALLPAPER_DIR" >&2
    fi

    # Generate all templates
    local count=0
    while IFS= read -r tmpl; do
        local rel="${tmpl#$REPO_DIR/templates/}"
        local target="$HOME/.config/${rel%.tmpl}"
        mkdir -p "$(dirname "$target")"
        # Backup
        [[ -f "$target" ]] && cp "$target" "${target}.bak"
        envsubst < "$tmpl" > "$target"
        ((count++))
    done < <(find "$REPO_DIR/templates" -type f -name "*.tmpl")

    # Update active symlink
    mkdir -p "$USER_CONFIG_DIR"
    ln -sfn "$theme_file" "$ACTIVE_LINK"

    # Reload daemons
    reload_daemons

    echo "Theme: $theme ($count templates applied)"
}

reload_daemons() {
    hyprctl reload >/dev/null 2>&1 || true
    pkill -x dunst >/dev/null 2>&1 && (sleep 0.5; setsid dunst >/dev/null 2>&1 &)
    pkill -9 -x hyprpaper >/dev/null 2>&1 && (sleep 0.5; setsid hyprpaper >/dev/null 2>&1 &)
}
```

### 6.4 cmd_interactive (wofi picker)

```bash
cmd_interactive() {
    local chosen
    chosen=$(cmd_list | wofi --dmenu --prompt "theme") || exit 0
    cmd_apply "$chosen"
}
```

### 6.5 Bind en Hyprland (no parte del repo, doc en README)

```lua
-- ~/.config/hypr/modules/binds.lua (NO templatizado, user lo añade a mano)
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("theme"))
```

---

## 7. install.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_CONFIG_DIR="$HOME/.config/hypr-themes"
BIN_DIR="$HOME/.local/bin"

# 1. Check deps
for cmd in hyprctl envsubst wofi dunst; do
    command -v "$cmd" >/dev/null || { echo "Missing: $cmd"; exit 1; }
done

# 2. Setup user config
mkdir -p "$USER_CONFIG_DIR"
[[ -f "$USER_CONFIG_DIR/config.sh" ]] || cp "$REPO_DIR/config.example.sh" "$USER_CONFIG_DIR/config.sh"

# 3. Symlink the script
mkdir -p "$BIN_DIR"
ln -sfn "$REPO_DIR/bin/theme" "$BIN_DIR/theme"

# 4. PATH check
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "Note: $BIN_DIR is not in PATH. Add it to your shell rc."
fi

# 5. Apply default theme
source "$USER_CONFIG_DIR/config.sh"
"$REPO_DIR/bin/theme" "${DEFAULT_THEME:-peach}"

echo "hypr-themes installed. Use 'theme <name>' or 'theme' for interactive picker."
```

---

## 8. uninstall.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

USER_CONFIG_DIR="$HOME/.config/hypr-themes"
BIN_DIR="$HOME/.local/bin"

rm -f "$BIN_DIR/theme"
rm -rf "$USER_CONFIG_DIR"

# Restore .bak si existen
for f in ~/.config/hypr/modules/config.lua ~/.config/hypr/hyprlock.conf ~/.config/hypr/hyprpaper.conf ~/.config/wofi/style.css ~/.config/dunst/dunstrc; do
    [[ -f "$f.bak" ]] && mv "$f.bak" "$f"
done

echo "hypr-themes uninstalled. Daemons not restarted — relaunch Hyprland session or reload daemons manually."
```

---

## 9. CI — shellcheck

`.github/workflows/shellcheck.yml`:

```yaml
name: shellcheck

on: [push, pull_request]

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run shellcheck
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: './bin'
          additional_files: 'install.sh uninstall.sh config.example.sh'
```

---

## 10. README — guion

```markdown
# hypr-themes

> One-command theme switcher for Hyprland. Define a theme once, apply across
> border, decoration, wofi, dunst, hyprlock and wallpaper.

[badge: shellcheck CI] [badge: license MIT]

[demo GIF]

## Quick start

```bash
git clone https://github.com/thenullstackdeveloper/hypr-themes ~/Projects/hypr-themes
cd ~/Projects/hypr-themes
./install.sh
theme         # interactive picker
theme peach   # apply directly
```

## Why

Changing the color palette of a Hyprland setup means editing 4+ files (border, glow,
wofi CSS, dunst, hyprlock, hyprpaper). Forgotten files = inconsistent visuals.

hypr-themes defines a single source of truth per theme and regenerates all configs
from templates. One command. No drift.

## How it works

[arquitectura simplificada — 1 párrafo]

## Themes included

- `peach` — warm orange accent, fits retro/CRT/pixel art wallpapers
- `mauve` — purple accent, fits fantasy/dreamy wallpapers
- ... (más a medida que añada)

## Creating your own theme

[2-3 párrafos con ejemplo]

## Config

[explicar config.sh y WALLPAPER_DIR]

## Adding to Hyprland binds

[snippet del bind Super+Shift+T]

## License

MIT
```

---

## 11. Plan de commits inicial

Plantilla de commits atómicos. Cada uno se puede revisar standalone:

```
1. chore: scaffold project structure
2. feat(themes): peach theme + Catppuccin Mocha palette vars
3. feat(templates): Hyprland config.lua template (border + glow)
4. feat(templates): hyprlock.conf template
5. feat(templates): hyprpaper.conf template with per-theme wallpaper
6. feat(templates): wofi style.css template
7. feat(templates): dunst dunstrc template with 3 urgency levels
8. feat(script): theme switcher CLI (apply, list, current)
9. feat(script): interactive wofi picker (theme without args)
10. feat: install.sh + uninstall.sh + config.example.sh
11. ci: shellcheck workflow
12. docs: README with quick start and architecture
13. chore: MIT license
14. feat(themes): mauve theme as second example
```

Una vez funcional, demo GIF en commit aparte:

```
15. docs(README): add demo GIF and badges
```

---

## 12. Estado actual del setup (a migrar al repo)

Archivos que se convierten en templates al arrancar:

| Origen | Destino en repo |
|--------|-----------------|
| `~/.config/hypr/modules/config.lua` | `templates/hypr/modules/config.lua.tmpl` |
| `~/.config/hypr/hyprlock.conf` | `templates/hypr/hyprlock.conf.tmpl` |
| `~/.config/hypr/hyprpaper.conf` | `templates/hypr/hyprpaper.conf.tmpl` |
| `~/.config/wofi/style.css` | `templates/wofi/style.css.tmpl` |
| `~/.config/dunst/dunstrc` | `templates/dunst/dunstrc.tmpl` |

Y el .theme actual:

| Origen | Destino |
|--------|---------|
| `~/.config/themes/peach.theme` | `themes/peach.theme` (limpiar / unificar formato) |

---

## 13. Open questions / edge cases

- [ ] **Backups**: actualmente propongo `.bak` por archivo. ¿Suficiente o queremos histórico con timestamp? Mi rec: `.bak` simple. Si quieren histórico, lo hace git en su rama.
- [ ] **Validación pre-write**: ¿comprobamos que el .tmpl rinde Lua válido antes de sobrescribir config.lua? `luac -p` post-envsubst, si falla restore .bak. Más robusto. Coste mínimo. Recomendado.
- [ ] **Detección de vars faltantes**: envsubst no falla si una var no está exportada (deja `${VAR}` como literal). Solución: pre-validar con `envsubst -v < tmpl` y comparar contra vars exportadas. Implementable en v2.
- [ ] **hyprpaper crash si wallpaper no existe**: añadir check `[[ -f $WALLPAPER_DIR/$WALLPAPER ]]` antes de aplicar. Si falta, warning + dejar el wallpaper anterior. Recomendado.
- [ ] **Demo GIF**: grabar con `wf-recorder` o `peek`. Pendiente al momento de README. No bloqueante.
- [ ] **Tests**: bats-core para unit tests del script. Overkill para v1. Diferido si el proyecto crece.

---

## 14. Próximos pasos sugeridos (orden de implementación)

1. Cerrar este DESIGN.md (review final con usuario en sesión nueva)
2. `git init` + `git remote add origin git@github.com:thenullstackdeveloper/hypr-themes.git`
3. Implementar siguiendo plan de commits sección 11
4. Probar en local: aplicar peach → verificar todo igual que antes
5. Crear `mauve.theme` con wallpaper distinto, probar switch
6. Documentar README con assets reales (screenshots de los dos temas)
7. Push a GitHub
8. Bind `Super+Shift+T` en `~/.config/hypr/modules/binds.lua` (acción manual del user, no parte del repo)

---

## 15. Referencias del setup vault

Notas relacionadas en el vault Obsidian (`~/Documents/PersonalVault/`):

- `Conocimiento/📚 Aprendizaje/Hyprland CachyOS Setup.md` — índice del journey
- `Conocimiento/📚 Aprendizaje/Hyprland CachyOS Setup/11 - Theming polish.md` — bloque 10 del journey (donde se sembró este proyecto)
- `Conocimiento/🛠 Tech/Hyprland/Setup CachyOS.md` — config actual viva

---

## 16. Contexto adicional para sesión nueva

- Usuario: `angelm` en `cachyos` (homelab personal). Memoria del agente sabe del equipo.
- Hyprland version: `0.55.2`
- Shell: `fish`
- Editor: NeoVim
- Vault Obsidian: `~/Documents/PersonalVault/`
- GitHub account: `thenullstackdeveloper`
- Wallpapers actuales en `~/Pictures/Wallpapers/` (10 archivos 7680×2160)
- Tema activo ahora: peach (con friki-salon.jpg)
