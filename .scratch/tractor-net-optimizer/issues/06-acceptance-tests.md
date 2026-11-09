# Criterios de aceptación y matriz de pruebas

Type: grilling
Status: open
Blocked by: —

## Question

Definir cómo se demuestra que el paquete funciona:

- Escenarios: campo de cultivos, bosque/tala, mina densa.
- Host + dos clientes; misma save, hora, clima y configuración.
- Métricas: frame time p99/máx del cliente, upload bytes/s del host, kicks/desconexiones, latencia percibida, pérdida de loot y sincronización visual.
- Duración, repeticiones y baseline antes/después.
- Instrumentación: MangoHud/Performance HUD, Profiler, `nethogs`/`iftop`, logs de SMAPI.

Recomendación: 10 minutos por escenario, 3 repeticiones, éxito = 0 kicks + p99 del cliente menor que 2× el baseline + sin pérdida de loot.
