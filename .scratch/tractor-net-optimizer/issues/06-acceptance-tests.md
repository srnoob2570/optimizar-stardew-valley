# Criterios de aceptación y matriz de pruebas

Type: grilling
Status: open
Blocked by: —

## Question

Definir cómo se demuestra que el paquete funciona:

- Escenarios: campo de cultivos, bosque/tala, mina densa.
- Host + dos clientes; misma save, hora, clima y configuración.
- Métricas: frame time p99/máx del cliente, upload bytes/s del host, kicks/desconexiones, latencia percibida, pérdida de loot, **cobertura de tiles** (cosechados/talados vs esperados) y sincronización visual.
- Duración, repeticiones y baseline antes/después.
- Instrumentación: MangoHud/Performance HUD, Profiler, `nethogs`/`iftop`, logs de SMAPI.

Recomendación: 10 minutos por escenario, 3 repeticiones. Éxito = 0 kicks + p99 del cliente **≤ baseline** (objetivo: ≥20% menos) + sin pérdida de loot + cobertura de tiles ≥ 99%, con cada descarte registrado. Un p99 de hasta 2× baseline es **límite de aborto**, no criterio de éxito. Si tras throttle + supresión de chips el p99 no mejora, abrir ticket de auto-collect/merge de item debris.
