# Perfilado de Stardew Valley

Herramientas instaladas para medir qué ralentiza el juego, separando mods de código vanilla.

## Qué hay instalado

- **Profiler 3.0.0-alpha5** (`SinZ.Profiler`) compilado desde el repositorio oficial y desplegado en
  `~/.local/share/Steam/steamapps/common/Stardew Valley/Mods/Profiler`.
  Mide el tiempo de cada handler de eventos de SMAPI y los eventos completos que superan el umbral.
- **dotnet-trace / dotnet-counters / dotnet-gcdump 10.0.750501**, en `~/.dotnet/tools` (ya en PATH).
- **MangoHud 0.8.1**, con perfil por juego en
  `~/.local/share/Steam/steamapps/common/Stardew Valley/MangoHud.conf`.
- Carpeta de salida: `traces/`.

## 1. Lanzar el juego con MangoHud

Desde el proyecto:

```bash
./launch.sh
```

El script arranca SMAPI con MangoHud, usando `MangoHud.conf` de la carpeta del juego y dejando los
logs en la terminal. El overlay aparece arriba a la izquierda.

- `Shift + F12` muestra/oculta el overlay.
- `Shift + F2` inicia/para el log de frame times en `traces/`.
- Lanza el ejecutable directamente, sin pasar por Steam; si quieres que Steam cuente las horas,
  añade `mangohud %command%` en las opciones de lanzamiento del juego y arranca desde Steam.

## 2. Capturar una traza de .NET

Con el juego ya en la partida que quieres medir:

```bash
cd "/home/srnoob/.local/share/Steam/steamapps/common/Stardew Valley"
dotnet-trace ps
```

Busca el proceso `StardewModdingAPI` y usa su PID:

```bash
dotnet-trace collect -p <PID> --duration 00:05:00 \
  -o /home/srnoob/Documentos/srnoob2570/optimizar-stardew-valley/traces/gameplay.nettrace
```

- `00:05:00` es el formato `dd:hh:mm:ss`; cinco minutos suele ser suficiente.
- No hace falta indicar perfil: usa `dotnet-common` + `dotnet-sampled-thread-time` (~100 Hz).
- La traza puede ocupar cientos de MB y tardar en cerrarse; es normal.
- Repite la captura con el mismo guardado, ubicación, hora y clima para comparar A/B.

## 3. Analizar la traza

Primero el resumen rápido:

```bash
dotnet-trace report traces/gameplay.nettrace topN -n 40 --inclusive
```

Después, para ver el árbol de llamadas:

```bash
dotnet-trace convert traces/gameplay.nettrace --format Speedscope
```

Abre `https://www.speedscope.app/` y carga `traces/gameplay.speedscope.json`.

> No ejecutes `report` y `convert` a la vez sobre la misma traza: comparten un archivo temporal
> `.etlx` y fallan. Hazlo en secuencia.

## 4. Memoria y contadores

Con el juego en marcha y el PID a mano:

```bash
dotnet-counters monitor -p <PID> --counters System.Runtime
dotnet-gcdump collect -p <PID> -o traces/memoria.gcdump
```

`dotnet-counters` sirve para ver CPU, heap, GC gen0/1/2, velocidad de asignación, excepciones y
threadpool en tiempo real. `gcdump` sirve para buscar objetos retenidos (texturas, mapas, mods).

## 5. Log de Profiler (mods)

Cada partida escribe:

```
~/.config/StardewValley/ErrorLogs/SMAPI-latest.txt
```

Busca `[Profiler]`, `[BigLoop]` o `[RawLog]`. Los eventos que superan los umbrales aparecen con el
desglose por mod. La configuración está en `Mods/Profiler/config.json`:

```json
{
  "BigLoopThreshold": 50,
  "BigLoopInnerThreshold": 0.01,
  "EventThreshold": 5,
  "LoggerDurationOuterThreshold": 5.0,
  "LoggerDurationInnerThreshold": 0.1
}
```

- `EventThreshold: 5` avisa de cualquier handler de mod que tarde más de 5 ms.
- `BigLoopThreshold: 50` registra el evento completo cuando pasa de 50 ms.
- Si el log crece demasiado, sube `EventThreshold` a 10 y `BigLoopThreshold` a 100.
- Para volver a los valores por defecto, borra `config.json` y arranca el juego.

## 6. Qué mide cada cosa

| Herramienta | Alcance |
| --- | --- |
| Profiler (SinZ) | Handlers de eventos de SMAPI, por mod y evento completo |
| dotnet-trace | Todo el código .NET, incluido el vanilla: `Game1.Update`, `GameLocation.draw`, NPCs, objetos |
| dotnet-counters | CPU, GC, heap, asignaciones, excepciones, threadpool |
| dotnet-gcdump | Memoria retenida por tipo y referencia |
| MangoHud | FPS, frame time, percentiles, CPU/GPU |

El juego corre sobre .NET 6. `dotnet-trace` se conecta sin PDBs: verás nombres de métodos, pero no
líneas de código. Bajo Proton no se puede adjuntar desde Linux; esta instalación es nativa y sí
funciona.
