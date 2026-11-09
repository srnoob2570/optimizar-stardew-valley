#!/usr/bin/env bash
set -euo pipefail

GAME_DIR="$HOME/.local/share/Steam/steamapps/common/Stardew Valley"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HUD_CONFIG="$GAME_DIR/MangoHud.conf"

if [[ ! -x "$GAME_DIR/StardewValley" ]]; then
  echo "No encuentro el lanzador de Stardew Valley en: $GAME_DIR" >&2
  exit 1
fi

if ! command -v mangohud >/dev/null 2>&1; then
  echo "MangoHud no está instalado." >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR/traces"

# El perfil de MangoHud vive junto al juego; lo fijamos para no depender del cwd.
if [[ -f "$HUD_CONFIG" ]]; then
  export MANGOHUD_CONFIGFILE="$HUD_CONFIG"
fi

# Lanza SMAPI en esta terminal (sin abrir otra) y conserva los logs.
export SMAPI_USE_CURRENT_SHELL=true

cd "$GAME_DIR"
exec mangohud ./StardewValley "$@"
