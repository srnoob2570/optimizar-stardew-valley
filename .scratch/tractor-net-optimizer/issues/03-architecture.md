# Arquitectura y distribución del mod

Type: grilling
Status: open
Blocked by: —

## Question

¿Cómo se empaqueta e instala la optimización?

Opciones:

- (a) Mod companion standalone con Harmony y dependencia suave de Tractor Mod.
- (b) Fork de Tractor Mod.
- (c) PR upstream a Tractor Mod.

Definir:

- Si debe instalarse solo en el host o en host y clientes.
- Versiones soportadas de Tractor Mod y SMAPI.
- Configuración: GMCM, `config.json`, toggles por optimización.
- Logging y comportamiento si Tractor Mod no está instalado.
- Distribución y actualización.

Recomendación: companion standalone, dependencia suave, instalado en host y clientes, con una sola configuración de referencia.
