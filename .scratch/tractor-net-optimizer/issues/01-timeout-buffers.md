# Timeout y buffers: knobs seguros

Type: research
Status: resolved
Blocked by: —

## Question

¿Qué knobs existen para aumentar la tolerancia de red en Stardew Valley 1.6 con SMAPI 4.5.2, host Linux nativo (a confirmar), y cuáles son seguros?

Cubrir:

- Timeouts de SMAPI/multijugador y dónde se configuran (archivo, clave, default).
- Buffers UDP del sistema (`net.core.rmem_max`, `net.core.wmem_max`, `net.core.rmem_default`, `net.core.wmem_default`) y si Steam/Stardew los usan realmente.
- Opciones de Steam Networking / relay que afecten al host.
- Defaults, rangos recomendados, efectos secundarios y si requieren reiniciar juego, Steam o el sistema.
- Si el ajuste es por host, por cliente o por ambos.

Entregar una tabla con: knob, archivo/comando, default, valor recomendado, riesgo y ámbito. Distinguir hechos verificados de suposiciones.

Estos knobs **no reducen el trabajo del cliente ni la creación de objetos**; solo toleran picos. No cuentan como criterio de éxito del paquete. Antes de asumir Linux, verificar el SO real del host; en Windows `net.core.*` no aplica.

## Answer

**Veredicto:** en Stardew Valley 1.6.15 + SMAPI 4.5.2 **no existe ningún knob de configuración soportado** para timeouts o buffers de red. Los timeouts de Lidgren y el timeout de handshake están hardcodeados en el código del juego; los de Steam no se fijan y quedan en los defaults de Steamworks. SMAPI solo expone `LogNetworkTraffic`, que es diagnóstico. En este host Linux los buffers del kernel ya tienen holgura. La única palanca real es un patch Harmony del companion, y no debe ser criterio de éxito: no reduce el trabajo del cliente ni la creación de objetos.

### Hechos verificados

Código 1.6.x decompilado (`references/StardewValleyDecompiled/`), SMAPI 4.5.2 instalado y este host.

- **SMAPI no tiene timeouts de red.** `smapi-internal/config.json` no contiene claves de timeout ni de buffers. La única clave relacionada con red es `LogNetworkTraffic` (default `false`), que solo escribe el tráfico en el log. `smapi-internal/config.user.json` solo tenía `ConsoleColorScheme`.
- **Handshake del cliente:** `Client.connectionTimeout = 45000` ms (`StardewValley.Network/Client.cs:12`). `connect()` fija `timeoutTime` a 45 s (`:88`) y lo limpia al completar el handshake (`:97-99`). Es un timeout de protocolo de juego, no del transporte.
- **Lidgren (IP directa):** `ConnectionTimeout = 30f`, `PingInterval = 5f`, `MaximumTransmissionUnit = 1200` en servidor (`LidgrenServer.cs:108-112`) y cliente (`LidgrenClient.cs:49-51`). No hay archivo de configuración: son locales del método.
- **Buffers de Lidgren:** los defaults upstream de `NetPeerConfiguration` son `ReceiveBufferSize = SendBufferSize = 131071` bytes; `NetPeer.Internal` los aplica al socket (`SO_RCVBUF`/`SO_SNDBUF`) y además asigna buffers de usuario del mismo tamaño (`NetPeer.Internal.cs:131-132`, `:194-195`). Stardew no los cambia.
- **Steam (invitaciones/amigos):** `SteamSocketUtils.GetNetworkingOptions()` (`SteamSocketUtils.cs:13-22`) devuelve **solo** `k_ESteamNetworkingConfig_SendBufferSize = 1048576` (1 MiB). Se usa tanto en `CreateListenSocketP2P` (host) como en `ConnectP2P` (cliente). No fija `TimeoutInitial`, `TimeoutConnected`, `RecvBufferSize`, `SendRateMin/Max` ni `NagleTime`.
- **Un fallo de envío de Steam cierra la conexión:** `SteamSocketUtils.SendMessage` llama a `SendMessageToConnection` con flags reliable (8); si el resultado no es `k_EResultOK`, escribe `Failed to send message (...). Closing connection.` y cierra (`SteamSocketUtils.cs:70-80`). `k_EResultLimitExceeded` (buffer de envío lleno) entra por ahí.
- **Steam oculta el motivo del timeout al cliente:** `SteamNetClient.OnDisconnected` pone `pendingDisconnect = HostLeft` tanto para `ClosedByPeer` como para `ProblemDetectedLocally` (`SteamNetClient.cs:70-80`). Un timeout de transporte de Steam se ve como «HostLeft» en el cliente, no como timeout.
- **Lidgren también confunde motivos:** `LidgrenClient.clientRemotelyDisconnected` asigna `LidgrenTimeout` a cualquier `Disconnected` que no sea un kick (`LidgrenClient.cs:165-181`). `LidgrenTimeout` no prueba por sí solo que haya habido un timeout de red.
- **Lidgren sin reintentos automáticos:** `maxRetryAttempts` se inicializa a 0 y no se asigna en el código mostrado (`LidgrenClient.cs:20`); tras fallar el descubrimiento no reintenta.
- **Buffers del kernel en este host:** `net.core.rmem_max = wmem_max = 4194304` (4 MiB), `rmem_default = wmem_default = 212992` (208 KiB), `net.ipv4.udp_mem = 1123905 1498543 2247810`, kernel `7.0.0-43-generic`.
- **El pedido de Lidgren ya cabe:** 131071 B duplicado por Linux son ~262142 B, por debajo del máximo de 4 MiB. `rmem_default`/`wmem_default` no aplican a Lidgren porque el juego fija `SO_RCVBUF`/`SO_SNDBUF` explícitamente.
- **SO del servidor real:** no está documentado en el repo. El host de pruebas es Linux. Si el servidor es Windows, `net.core.*` no aplica; el resto de conclusiones sobre el juego/Steam sí.

### Suposiciones (no confirmadas en Steamworks propietario)

- Los defaults de Steamworks para `TimeoutInitial` y `TimeoutConnected` son 10 000 ms. La cabecera pública de Steamworks no documenta el default; la referencia open-source GameNetworkingSockets usa 10 000 ms para ambos (`csteamnetworkingsockets.cpp:76-77`). Steamworks propietario podría diferir.
- `RecvBufferSize` de Steam es 1 MiB por defecto y el juego no lo cambia (default GNS). No verificado en el Steamworks del juego.
- `SendRateMin/Max` (256 KiB/s) y `NagleTime` (5000 µs) son defaults GNS; el juego no los fija. No verificado en Steamworks propietario.
- Qué buffers de socket pide Steamworks al SO: no se puede ver desde el código del juego. Los `net.core.*` pueden afectar al transporte de Steam, pero no hay evidencia de que sean el cuello.
- Forzar relay de Steam añade latencia; no hay evidencia de que ayude a este problema.

### Tabla de knobs

| Knob | Dónde | Default | Recomendado | Riesgo | Ámbito | Reinicio | Estado |
|---|---|---|---|---|---|---|---|
| `LogNetworkTraffic` | `smapi-internal/config.json` | `false` | `false`; `true` solo para una captura diagnóstica corta | Log grande y overhead; no arregla nada | Host y clientes | Juego | Verificado |
| Timeouts de SMAPI | — | No existen | No aplica | — | — | — | Verificado |
| Handshake del cliente | `Client.cs:12` (hardcoded) | 45 s | 45 s; 60–90 s solo si clientes lentos no completan el handshake | Alarga la detección de un cliente colgado | Cliente | Juego | Verificado |
| Lidgren `ConnectionTimeout` | `LidgrenServer.cs:108`, `LidgrenClient.cs:49` | 30 s | 30 s; 60 s solo si los logs muestran `LidgrenTimeout` con parones >30 s | Tarda más en detectar desconexiones reales; mantiene estado obsoleto | Ambos | Juego | Verificado |
| Lidgren `PingInterval` / MTU | `LidgrenServer.cs:109-111`, `LidgrenClient.cs:50-51` | 5 s / 1200 B | 5 s / 1200 B | Bajar ping sube tráfico; subir MTU puede fragmentar y empeorar pérdidas | Ambos | Juego | Verificado |
| Lidgren `ReceiveBufferSize` / `SendBufferSize` | Defaults upstream; Stardew no los toca | 131071 B cada uno | 131071 B; 1 MiB solo si `/proc/net/snmp` muestra `RcvbufErrors`/`SndbufErrors` creciendo | Memoria; sin evidencia no hay ganancia; el DLL del juego no se decompiló | Ambos | Juego | Defaults upstream verificados; patch no probado |
| Steam `SendBufferSize` | `SteamSocketUtils.cs:13-22` | 1 MiB | 1 MiB; 4 MiB solo si los logs muestran `k_EResultLimitExceeded` | Más cola y latencia; no reduce el burst | Ambos | Juego | Verificado |
| Steam `TimeoutInitial` / `TimeoutConnected` | No los fija el juego | ~10 s / ~10 s (GNS; supuesto) | No tocar; 30 s solo si hay `ProblemDetectedLocally` o «HostLeft» con el host vivo | Alarga la detección de conexiones muertas; puede retener clientes colgados | Ambos | Juego | Default GNS verificado; Steamworks supuesto |
| Steam `RecvBufferSize` | No la fija el juego | ~1 MiB (GNS) | No tocar | Memoria; sin evidencia de pérdida | Ambos | Juego | Supuesto |
| Steam `SendRateMin/Max` / `NagleTime` | No los fija el juego | 256 KiB/s / 5000 µs (GNS) | No tocar | No es el cuello; bajar Nagle sube paquetes | Ambos | Juego | Supuesto |
| Relay de Steam (`SDRClient_ForceRelayCluster`, etc.) | API de Steam; sin archivo de juego | Automático | No forzar | Añade latencia; no arregla CPU | Ambos | — | El juego no lo expone; resto supuesto |
| `ServerBufferSize` / `ClientBufferSize` | `SteamNetServer.cs:13`, `SteamNetClient.cs:13` | 256 mensajes/frame | No tocar | Si se llena, backlog/latencia; no es un timeout | Ambos | Juego | Verificado |
| `net.core.rmem_max` / `wmem_max` | `sysctl` / `/etc/sysctl.d/99-stardew.conf` | 4 MiB en este host | No tocar | Ninguno; no hay ganancia porque el request es 128 KiB | Host (SO) | No para el valor; juego para sockets nuevos | Verificado |
| `net.core.rmem_default` / `wmem_default` | `sysctl` | 208 KiB en este host | No tocar | Irrelevante para Lidgren: fija `SO_RCVBUF`/`SO_SNDBUF` | Host (SO) | No | Verificado |
| `net.ipv4.udp_mem` | `sysctl` | 1123905 / 1498543 / 2247810 páginas | No tocar | Solo importa bajo presión de memoria | Host (SO) | No | Verificado |

### Recomendación

1. **v1 del companion: no tocar timeouts ni buffers.** No hay knob soportado, los sysctl de este host no aportan y el problema central es CPU del cliente + upload del host. Meter estos cambios en v1 añade riesgo de compatibilidad sin atacar la causa.
2. **Si los tests de aceptación muestran desconexiones por timeout** (no por falta de cobertura o pérdida de loot), añadir un patch **opcional, apagado por defecto**, con configuración explícita:
   - Lidgren: `ConnectionTimeout` 60 s y buffers 1 MiB, en host y clientes.
   - Steam: `TimeoutInitial`/`TimeoutConnected` 30 s, en host y clientes, vía postfix de `GetNetworkingOptions`.
   - No tocar MTU, `PingInterval`, `NagleTime` ni relay.
   - Medir de nuevo; si no baja la tasa de kicks, revertir.
3. **`LogNetworkTraffic` solo para diagnosis.** Activarlo, reproducir un sweep, apagarlo. No dejarlo encendido.
4. **Confirmar el SO del servidor real.** El host de pruebas es Linux; si el servidor es Windows, ignorar las filas de `net.core.*`, pero el resto aplica igual.

### Cómo diagnosticar si el timeout importa

- Cliente con `LidgrenTimeout`: puede ser timeout real o un cierre no-kick; mirar el timestamp y si el host seguía vivo.
- Cliente con «HostLeft» y host vivo: sospechar `ProblemDetectedLocally` de Steam, que el código mapea a `HostLeft`.
- Cliente con `ClientTimeout`: puede ser el handshake de 45 s o un fallo de `_newDayTask`; no es el kick típico de cosecha.
- Si el frame time máximo del cliente supera el timeout del transporte (10 s en Steam, 30 s en Lidgren), el timeout es un síntoma, no la causa; ningún knob de red lo arregla.
- `grep 'Udp:' /proc/net/snmp` antes/después de un sweep: si `RcvbufErrors` o `SndbufErrors` suben, los buffers importan; si quedan en 0, no.
- `k_EResultLimitExceeded` en el log del host: el `SendBufferSize` de Steam se llenó; el throttle de tiles es la solución, no agrandar el buffer.

### Qué implica para el mapa

- El host de pruebas es Linux; el SO del servidor real sigue sin confirmar. Ese punto se mantiene en «Not yet specified» con el dato nuevo.
- Este ticket no cambia el destino ni el alcance: timeouts/buffers quedan como mitigación opcional, no como criterio de éxito.

