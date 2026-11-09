# Mapa: optimización de red del tractor en multijugador

## Destination

Un spec técnico aprobado para un mod companion de Tractor Mod que reduzca los kicks de clientes al cosechar o talar en multijugador mediante throttle de tiles, supresión o localización de chips visuales, culling seguro y ajustes de timeout/buffers, sin bajar la frecuencia de red ni romper la sincronización.

## Notes

- Dominio: Stardew Valley 1.6.15, SMAPI 4.5.2, Tractor Mod 4.24.4, .NET 6, host Linux nativo (a confirmar). El servidor real usa `Distance: 4`, `TractorSpeed: 2`, `MagneticRadius: 420`; el archivo local de pruebas está en `16 / 4 / 421`.
- Paquete elegido por el usuario: throttle de tiles + supresión de chips visuales + culling + timeout/buffers.
- Restricción explícita: **no** bajar la frecuencia de red a 20 Hz ni desactivar la interpolación; la prioridad es reducir la sensación de lag sin romper la sincronización.
- No tocar código, configuración del juego ni del servidor hasta que el mapa esté aprobado.
- Toda decisión debe poder validarse con host + al menos dos clientes.
- Términos:
  - **tile-action**: una llamada de un attachment a `UseToolOnTile` para un tile.
  - **sweep**: una pasada de `TractorManager.UpdateAttachmentEffects` sobre la rejilla.
  - **item debris**: loot recogible.
  - **visual debris**: chips cosméticos de madera/piedra, no recogibles.
  - **culling**: dejar de sincronizar/renderizar objetos lejanos; no significa borrar loot.
- Skills: `grilling`, `domain-modeling`; `prototype` para el ticket de prototipo.
- Tracker local: `.scratch/tractor-net-optimizer/`.

## Decisions so far

- [Timeout y buffers: knobs seguros](issues/01-timeout-buffers.md): no hay knobs soportados; los timeouts y buffers están hardcodeados o en defaults de Steamworks, y los sysctl del host ya tienen holgura. Solo un patch Harmony opcional, fuera del criterio de éxito.

## Not yet specified

- Cómo medir el cuello real (upload del host vs CPU del cliente) con el host y los clientes concretos; el baseline se concreta en el ticket de aceptación.
- SO real del host: el host de pruebas es Linux (`7.0.0-43-generic`; `net.core.rmem_max`/`wmem_max` = 4 MiB). El SO del servidor real sigue sin confirmar. Si es Windows, `net.core.*` no aplica.
- Si el culling por jugador es viable con SMAPI sin tocar el `NetCollection`; depende de la investigación de chips visuales.
- Cómo evitar doble procesamiento o pérdida de tiles cuando el tractor se mueve durante la cola; depende de la política de throttle.
- Compatibilidad con Stardropium y otros mods que ya tocan debris o renderizado; no se ha revisado.
- Si hace falta un modo de compatibilidad distinto para clientes Windows y Linux.

## Out of scope

- Bajar la frecuencia de red a 20 Hz o desactivar la interpolación: rechazado por el usuario; rompería la sensación de sincronización.
- Auto-collect o merge de loot: no forma parte del paquete elegido; se reevalúa como esfuerzo aparte si el mapa no alcanza.
- Cambiar `Distance`, `TractorSpeed` o `MagneticRadius` del servidor: es tuning operativo, no el mod.
- Reescribir el netcode de SMAPI o el protocolo de Steam.
- Optimizar renderizado/GPU, el tick del reloj o mods ajenos.
