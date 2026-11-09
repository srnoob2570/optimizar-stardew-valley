# Chips visuales: detección y supresión

Type: research
Status: open
Blocked by: —

## Question

¿Cómo se pueden suprimir o localizar los chips visuales que genera el tractor sin afectar el loot ni la sincronización?

Investigar en el código de Stardew Valley 1.6 y Tractor Mod 4.24.4:

- `Game1.createRadialDebris`, `Game1.createMultipleItemDebris`, `Debris` y `Chunk`: qué campos distinguen visual debris de item debris.
- Cómo detectar que la acción viene del tractor: `Game1.player.mount`, el `modData` de Tractor Mod, o el contexto de `TractorManager`.
- Si suprimir en el host es suficiente o cada cliente necesita generar el efecto localmente.
- Alternativas: no-op, `TemporaryAnimatedSprite` local, reducir la cantidad de chunks.
- Riesgos de compatibilidad con otros mods que parcheen `createRadialDebris`, `Debris` o el renderizado.

Entregar opciones con complejidad, alcance (host/cliente) y riesgo. Distinguir lo verificado en código de lo que requiere prueba en juego.
