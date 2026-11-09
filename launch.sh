#!/usr/bin/env bash
set -euo pipefail

GAME_DIR="${GAME_DIR:-$HOME/.local/share/Steam/steamapps/common/Stardew Valley}"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HUD_CONFIG="$GAME_DIR/MangoHud.conf"
FALLBACK_HUD_CONFIG="$PROJECT_DIR/config/MangoHud.conf"

if [[ ! -x "$GAME_DIR/StardewValley" ]]; then
  echo "No encuentro el lanzador de Stardew Valley en: $GAME_DIR" >&2
  exit 1
fi

if ! command -v mangohud >/dev/null 2>&1; then
  echo "MangoHud no está instalado." >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR/traces"

# Perfil junto al juego; si no existe, el del repo. MANGOHUD_CONFIG manda sobre el archivo.
if [[ -f "$HUD_CONFIG" ]]; then
  export MANGOHUD_CONFIGFILE="$HUD_CONFIG"
elif [[ -f "$FALLBACK_HUD_CONFIG" ]]; then
  export MANGOHUD_CONFIGFILE="$FALLBACK_HUD_CONFIG"
else
  echo "Aviso: no encuentro MangoHud.conf; MangoHud usará su configuración global." >&2
fi
export MANGOHUD_CONFIG="output_folder=$PROJECT_DIR/traces"

# Lanza SMAPI en esta terminal (sin abrir otra) y conserva los logs.
export SMAPI_USE_CURRENT_SHELL=true

cd "$GAME_DIR"
exec mangohud ./StardewValley "$@"
