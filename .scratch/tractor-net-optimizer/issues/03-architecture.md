# Arquitectura y distribución del mod

Type: grilling
Status: resolved
Assignee: srnoob — 2026-11-09
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

## Answer

**Veredicto:** mod companion standalone con Harmony (el que ya trae SMAPI), dependencia suave de `Pathoschild.TractorMod`, instalado en el host y en todos los clientes, con `config.json` y registro automático en GMCM. v1 se distribuye como zip de release en GitHub, instalación manual, sin Nexus ni auto-actualización. Todo fallo de compatibilidad degrada con log, nunca bloquea el arranque ni el guardado.

### Decisiones

| Pregunta | Decisión |
|---|---|
| Empaquetado | (a) Companion standalone. No se forks el monorepo de Pathoschild ni se espera a un PR upstream. |
| Instalación | Host y **todos** los clientes. El throttle corre donde se conduce y los chips se crean en el cliente que conduce (ticket 02); instalación uniforme evita comportamiento por rol. |
| Versiones | Tractor Mod `>= 4.24.4` (validado 4.24.4), SMAPI `>= 4.1.10` (validado 4.5.2). Sin techo; por encima de lo probado, aviso de "versión no probada" y parches defensivos. |
| Configuración | Un `config.json` con una sección por optimización (throttle, chips, culling, timeout) y GMCM opcional si está instalado. Los valores concretos los fijan los tickets 04 y 05. |
| Modo degradado | Carga siempre. Sin Tractor Mod: una línea INFO y cero parches. Método objetivo ausente: ERROR nombrando el método, se desactiva solo esa función. |
| Distribución | Release zip en GitHub, instalación manual. Sin `UpdateKeys`, sin Nexus y sin auto-actualización en v1. |

### Hechos verificados

- Instalado: Tractor Mod 4.24.4 (`UniqueID: Pathoschild.TractorMod`, `MinimumApiVersion: 4.1.10`, `UpdateKeys: Nexus:1401`), SMAPI 4.5.2, Stardew Valley 1.6.15 build 24356, GMCM 1.16.0.
- Harmony viaja dentro de SMAPI: `smapi-internal/0Harmony.dll`; el companion no necesita redistribuirlo.
- El código de Tractor Mod está en el monorepo `Pathoschild/StardewMods` (rama `develop`, carpeta `TractorMod`), licencia MIT. Forkear o parchear upstream es legal, pero arrastra mantenimiento o calendario ajeno.
- La dependencia dura se descarta: en un cliente sin Tractor Mod el companion debe ser un no-op, no un error de carga.

### Contrato de compatibilidad

Manifest del companion:

```json
{
  "MinimumApiVersion": "4.1.10",
  "Dependencies": [
    {
      "UniqueID": "Pathoschild.TractorMod",
      "MinimumVersion": "4.24.4",
      "IsRequired": false
    }
  ]
}
```

- `MinimumApiVersion` del companion: 4.1.10, el mismo suelo que exige Tractor Mod 4.24.4; el companion no usa APIs más nuevas. Lo validado es SMAPI 4.5.2.
- Antes de cada `harmony.Patch`, resolver el método con `AccessTools` y comprobar la firma. Si no existe, no se parchea y se registra el error; las demás optimizaciones siguen.
- Si `TractorMod` está presente con versión `> 4.24.4`, un WARN único al arrancar. Sin bloqueo.
- GMCM es dependencia blanda: si está, se registra el menú; si no, `config.json` sigue funcionando.

### Implicaciones para el mapa

- Desbloquea los tickets 04 (política de throttle) y 05 (política de culling). El 06 ya estaba libre; el 07 sigue esperando a todos.
- El prototipo (07) debe poder instalarse en host y clientes con el mismo zip y arrancar sin Tractor Mod.
- La distribución no genera tickets nuevos: build local + zip es ejecución, no una decisión pendiente.
- La niebla no cambia: el SO del servidor real y la compatibilidad Windows/Linux siguen sin resolverse y no bloquean 04/05.

### Suposiciones

- Las versiones posteriores a 4.24.4 mantienen los métodos y el buff usados por los parches; el aviso y la comprobación defensiva cubren el caso contrario, pero no hay garantía escrita.
- El zip de GitHub es suficiente para el uso real (host + clientes conocidos); si el mod se comparte, se reevalúa Nexus.
- Un solo `config.json` sirve para host y clientes aunque los roles difieran; los toggles permiten desactivar una optimización por máquina.

### Qué implica para la siguiente sesión

El primer ticket de la frontera pasa a ser **04 — Política de throttle de tiles**. El 05 queda también libre. Este ticket no implementa nada: el código y la medición son del 07.
