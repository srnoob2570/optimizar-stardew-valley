# Convenciones de commit

## Por qué

- Las entradas del changelog viven bajo `## [Unreleased]`; todavía no hay herramienta de releases.
- Mensajes en Conventional Commits: tipo y scope en inglés, resumen en español.

## Gotchas

- `references/` y `traces/` están ignorados: son código externo y salidas de perfilado.
- `.scratch/tractor-net-optimizer/` es el plan de trabajo y sí se versiona.
- El proyecto aún no es un mod: es el toolchain de medición y el plan de optimización.

## Preferencias

- Changelog en español con los encabezados de Keep a Changelog.
- Commits pequeños y cohesionados; no mezclar toolchain con cambios de gameplay.
