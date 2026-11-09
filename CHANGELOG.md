# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa
[Versionado Semántico](https://semver.org/lang/es/).

## [Unreleased]

### Added

- Toolchain de perfilado para Stardew Valley: Profiler 3.0.0-alpha5, dotnet-trace,
  dotnet-counters y dotnet-gcdump.
- Perfil de MangoHud de ejemplo en `config/MangoHud.conf` para clones sin configuración local.
- Script `launch.sh` para arrancar SMAPI con MangoHud y guardar los tiempos de frame en `traces/`.
- README con el flujo de captura, análisis y lectura de logs.
- Plan de optimización de red de Tractor Mod en `.scratch/tractor-net-optimizer/`.

### Changed

- Proyecto reubicado en `~/Documentos/srnoob2570/optimizar-stardew-valley` e inicializado
  como repositorio Git con la identidad `srnoob2570`.

### Fixed

- Corregida la duración de ejemplo de `dotnet-trace` (`00:00:05:00`) y eliminadas las rutas
  absolutas del README.
- `launch.sh` usa `config/MangoHud.conf` como fallback y fuerza la salida de tiempos de frame a
  `traces/`; `GAME_DIR` permite sobrescribir la ruta de Steam.
- Endurecidos los criterios de aceptación del plan: p99 ≤ baseline, cobertura de tiles y registro
  de descartes; el throttle ahora distingue cap de promedio y el culling no promete eliminar item
  debris.
