# Timeout y buffers: knobs seguros

Type: research
Status: open
Blocked by: —

## Question

¿Qué knobs existen para aumentar la tolerancia de red en Stardew Valley 1.6 con SMAPI 4.5.2, host Linux nativo, y cuáles son seguros?

Cubrir:

- Timeouts de SMAPI/multijugador y dónde se configuran (archivo, clave, default).
- Buffers UDP del sistema (`net.core.rmem_max`, `net.core.wmem_max`, `net.core.rmem_default`, `net.core.wmem_default`) y si Steam/Stardew los usan realmente.
- Opciones de Steam Networking / relay que afecten al host.
- Defaults, rangos recomendados, efectos secundarios y si requieren reiniciar juego, Steam o el sistema.
- Si el ajuste es por host, por cliente o por ambos.

Entregar una tabla con: knob, archivo/comando, default, valor recomendado, riesgo y ámbito. Distinguir hechos verificados de suposiciones.
