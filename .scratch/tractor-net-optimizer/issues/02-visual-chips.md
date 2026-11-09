# Chips visuales: detección y supresión

Type: research
Status: resolved
Assignee: srnoob — 2026-11-09
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

## Answer

**Veredicto:** los chips del tractor son `Debris` de tipo `CHUNKS` (madera/piedra), con `item == null` e `itemId == null`, creados por `Game1.createRadialDebris(..., resource: false, item: false)`. No son efectos locales: `GameLocation.debris` es una `NetCollection<Debris>` y cada `Debris`/`Chunk` es un objeto de red. Se crean en el equipo que ejecuta la acción (el cliente del farmhand, o el host si es él quien conduce), no en un host que solo observa; el host aplica y retransmite el delta de quien conduce. Por tanto **suprimir en el host no basta** cuando conduce un farmhand: hay que suprimir en el cliente que ejecuta la acción, y el companion debe estar en el host y en todos los clientes que conducen. Recomiendo un no-op selectivo de la llamada visual (nunca de `resource: true`/`item: true`) con el buff `Pathoschild.TractorMod` como señal de contexto. El riesgo principal es acoplarse a un identificador de Tractor Mod y el corrimiento del RNG de partículas; el loot no se toca.

### Hechos verificados

Código 1.6.15 decompilado en `references/StardewValleyDecompiled/` y Tractor Mod 4.24.4 en `/tmp/opencode/StardewMods-src/TractorMod` (versión en `TractorMod.csproj:3`; el DLL instalado es la misma 4.24.4, `~/.local/share/Steam/steamapps/common/Stardew Valley/Mods/TractorMod/manifest.json:4`). Las rutas de juego de las citas son relativas a `references/StardewValleyDecompiled/Stardew Valley/`; las de Tractor Mod, a `/tmp/opencode/StardewMods-src/TractorMod/`.

#### 1. Qué distingue un chip visual del loot

`Debris` tiene estos campos relevantes (los NetFields se registran en `Debris.cs:207-227`):

| Campo | Tipo | Línea | Semántica verificada |
|---|---|---|---|
| `debrisType` | `NetEnum<DebrisType>` | `Debris.cs:101` | `CHUNKS=0` visual; `LETTERS=1`, `SPRITECHUNKS=5`, `NUMBERS=7` cosméticos; `ARCHAEOLOGY=3`, `OBJECT=4`, `RESOURCE=6` loot (`Debris.cs:14-25`) |
| `item` | `NetRef<Item>` | `Debris.cs:119` | No nulo en item debris creado desde un `Item`; nulo en resource y en visual |
| `itemId` | `NetString` | `Debris.cs:117` | No nulo en resource/object/archaeology (loot perezoso); **nulo** en visual |
| `chunks` | `NetObjectShrinkList<Chunk>` | `Debris.cs:73` | Partículas; no distingue loot de visual: ambos tienen |
| `chunkType` | `NetInt` | `Debris.cs:75` | Índice de sprite; `8` es el caso especial de monedas |
| `nonSpriteChunkColor`, `chunksColor` | `NetColor` | `Debris.cs:105,107` | Color de números/letras/chips |
| `spriteChunkSheetName` | `NetString` | `Debris.cs:113` | Hoja de textura para `SPRITECHUNKS` |
| `debrisMessage` | `NetString` | `Debris.cs:103` | Texto para `LETTERS` |
| `floppingFish`, `isFishable` | `NetBool`, `bool` | `Debris.cs:95,97` | Comportamiento de pez |
| `player`, `DroppedByPlayerID` | `NetFarmerRef`, `NetLong` | `Debris.cs:123,91` | Quién recoge / quién lo soltó |

No existen `collectable` ni `nonSpriteDebris` en 1.6.15 (búsqueda en `Debris.cs` y `Chunk.cs` sin resultados). La recogida es el método `collect(Farmer, Chunk)` (`Debris.cs:472-493`) y el flag de “item esencial” es `isEssentialItem()` (`Debris.cs:459-470`), que no sirve para distinguir visual de loot.

Los constructores fijan la semántica:

- **Visual**: `Debris(int debrisType, int numberOfChunks, Vector2 debrisOrigin, Vector2 playerPosition, int groundLevel, Color? color = null)` (`Debris.cs:244-251`). Pone `debrisType=CHUNKS`, `chunkType=debrisType`, `chunksColor`; no toca `item` ni `itemId`.
- **Resource (loot)**: `Debris(int resource_type, int numberOfChunks, ...)` → `InitializeResource` (`Debris.cs:294-342`); pone `itemId` y `debrisType=RESOURCE` u `OBJECT`, pero deja `item` nulo para crearlo al recoger.
- **Item (loot)**: `Debris(Item item, Vector2 origin, ...)` (`Debris.cs:345-362`); pone `item` y `itemId`.
- **Letras/números/sprite chunks**: `Debris.cs:365-457`; cosméticos, sin `itemId`.

Por eso el discriminador robusto es **`debrisType == CHUNKS` + `item == null` + `itemId == null`** (con la excepción `chunkType == 8`), no `item == null` a secas: el resource loot también tiene `item == null` y se crea desde `itemId` en `collect()` (`Debris.cs:478-490`).

El update y el draw confirman el uso real:

- `updateChunks` elimina un `CHUNKS` a los ~600 ms (`Debris.cs:633-648`); si `chunks.Count == 0` lo elimina de inmediato (`Debris.cs:629-632`). Los `OBJECT`/`RESOURCE`/`ARCHAEOLOGY` pasan a moverse hacia el jugador (`Debris.cs:649-654`) y se recogen al acercarse (`Debris.cs:753-792`).
- `drawDebris` dibuja primero `item != null`, luego el switch de `debrisType`, luego `itemId != null` y, si no, la hoja de chunks (`GameLocation.cs:15657-15715`). **No hay culling por viewport**: itera y dibuja todos los debris de la location; el bucle de objects de abajo sí comprueba el viewport (`GameLocation.cs:15848-15851`). `drawDebris` se llama desde `draw` (`GameLocation.cs:15844`).
- `GameLocation.update` recorre y actualiza todos los debris cada tick (`GameLocation.cs:3955-3965`).

`Game1.createRadialDebris` tiene dos caminos que importan:

- Sobrecarga `int` (`Game1.cs:10300`). Si `item: true`, crea un `Debris` de loot por cada chunk (`Game1.cs:10307-10321`) y **consume el contador**; después la rama cosmética crea 4 `Debris` con `numberOfChunks/4` = 0,0,0,0 (`Game1.cs:10335-10341`), es decir, chips **invisibles**. Si `resource: true`, crea 4 `Debris` de resource con loot (`Game1.cs:10323-10332`). Solo `resource: false, item: false` crea los 4 `Debris` de chips visibles (`Game1.cs:10333-10342`), con ~N chunks en total (la división `/4` se compensa con los `numberOfChunks++`).
- Sobrecargas `string` (`Game1.cs:10355-10362` y `10378-10420`) crean `SPRITECHUNKS`. No se ha encontrado ningún path del tractor que las use: `ScytheAttachment` recolecta hierba con `TryHarvestGrass` (`ScytheAttachment.cs:356-365`), que no pasa por `Grass.reduceBy` (`Grass.cs:228-256`); `reduceBy` solo lo usa `FarmAnimal` (`FarmAnimal.cs:1448`). `CosmeticPlant` (subclase de `Grass`) sí las usa (`CosmeticPlant.cs:52-62`), pero solo con un `MeleeWeapon` que no sea de tipo 2 o con explosión, y los attachments de melee del tractor usan `damageMonster`, no `performToolAction`.

El loot va por métodos separados y **no se debe tocar**: `createItemDebris` (`Game1.cs:10245-10287`), `createMultipleItemDebris` (`Game1.cs:10289-10298`), `createDebris` (`Game1.cs:10231-10243`), y las llamadas `resource: true` (p. ej. `Tree.cs:528,1545,1569`; `FruitTree.cs:310,811,815`).

#### 2. Multijugador: quién crea, quién recibe y quién simula

- `GameLocation.debris` es `NetCollection<Debris>` (`GameLocation.cs:290`) y está en los NetFields de la location (`GameLocation.cs:760`). `Debris` mete en red los campos listados, incluidos `chunks`, `debrisType`, `item`, `itemId` y colores (`Debris.cs:207-227`). `Chunk` también es NetObject con posición/velocidad/escala/alpha (`Chunk.cs:11-45,89-96`); su `DeltaAggregateTicks` es 30 (10 en multijugador local) (`Chunk.cs:97-104`). Los chips, por tanto, **viajan por red**; no se regeneran en cada cliente.
- Un cliente que cambia la location envía su delta al host: `broadcastLocationDeltas` recorre `activeLocations()` y llama a `broadcastLocationDelta` si `Root.Dirty` (`Multiplayer.cs:362-383`); `broadcastLocationMessage` usa `Game1.client.sendMessage` cuando `Game1.IsClient` (`Multiplayer.cs:400-406`). El host aplica el mensaje tipo 6 en `Multiplayer.processIncomingMessage` (`Multiplayer.cs:1560-1565`) y lo retransmite porque el tipo 6 está en `isClientBroadcastType` (`Multiplayer.cs:201-224`, `GameServer.cs:679-715`). Los clientes receptores lo aplican en el mismo case 6.
- El host **solo crea** el debris de sus propias acciones de herramienta. Las acciones de un farmhand se ejecutan en el cliente del farmhand: `TractorManager` es `PerScreen` (`ModEntry.cs:68`), `Update` se llama en cada cliente (`ModEntry.cs:396-417`) y `UpdateAttachmentEffects` usa `Game1.player` y `Game1.currentLocation` (`TractorManager.cs:327-331`). El host no vuelve a ejecutar el `DoFunction` del farmhand: recibe el delta.
- `Debris.shouldControlThis` devuelve true en el master (y en clientes solo si la location es temporal) (`Debris.cs:618-625`), pero eso controla la **simulación** (movimiento/recogida), no la creación. No convierte la creación en host-only.
- Consecuencia: si el host suprime sus propias llamadas, solo elimina los chips del host cuando es él quien conduce. Los chips de un farmhand siguen saliendo de su cliente, el host los aplica y los retransmite. Un filtro solo-host no reduce ni el upload del farmhand ni el relay del host. Filtrar el delta en el host exigiría parsear/reescribir el paquete; no es viable con un prefix simple.

#### 3. Señales para detectar que la llamada viene del tractor

Ni `TractorManager`, ni `BaseAttachment`, ni los attachments de `Framework/Attachments` llaman a `createRadialDebris`: `BaseAttachment.UseToolOnTile` (`BaseAttachment.cs:110-117`) invoca `tool.DoFunction`, y el debris nace en el vanilla (`Pickaxe.cs:141,150`, `Tree.cs:528-529`, `Object.cs:1056`). `Framework/ModAttachments/SeedBagAttachment` solo aplica la herramienta/objeto (`SeedBagAttachment.cs:49-57`). Por eso la señal no puede estar en el código del mod que llama, sino en el contexto de ejecución.

| Señal | Dónde | ¿Prueba que la llamada es del tractor? | Uso |
|---|---|---|---|
| `Game1.player.mount` / `TractorManager.IsTractor(Game1.player.mount)` | `TractorManager.cs:79,120-123` | **No durante el sweep**: `TemporarilyFakeInteraction` pone `netMount` a `null` (`TractorManager.cs:476-478`) y lo restaura en el `finally` (`:489-490`) | No usar |
| `Game1.player.mount.modData["Pathoschild.TractorMod"]` | `TractorManager.cs:33,109` | Mismo problema: el mount está desmontado durante el sweep | No usar |
| Buff `Pathoschild.TractorMod` en `Game1.player.buffs.AppliedBuffs` | `TractorManager.cs:27,275-303`; `BuffManager.cs:18-19,179-185,208-223` | Prueba que el jugador local está montado (el buff se aplica mientras conduce sin menú y se quita al desmontar o abrir menú); no prueba que esta llamada concreta sea del sweep. Sí cubre llamadas diferidas y efectos de proyectiles | Proxy recomendado; heurística |
| Flag Harmony en `TractorManager.UpdateAttachmentEffects()` | `TractorManager.cs:327-387`; llamada en `:201-204` | Sí para todo lo que se ejecute dentro del sweep; no cubre `DelayedAction` posterior (p. ej. `Object.cs:1303-1306`) | Señal exacta si se acepta el acoplamiento al método privado |
| `Game1.player.CurrentTool` | `TractorManager.cs:332` | No: el mismo tool se usa a mano; el tractor también usa items (semillas, fertilizante) | No usar |
| Pila de llamadas | — | Sí, pero asigna y cuesta por llamada; con cientos de llamadas por tick no es viable | Solo diagnóstico |

El buff es seguro de leer: `AppliedBuffs` es un diccionario local no sincronizado (`BuffManager.cs:18-19`) y `Apply`/`Remove` solo lo tocan si `IsLocallyControlled()` (`BuffManager.cs:179-185,208-223`). Tractor Mod lo aplica en `UpdateBuff(true)` antes de `UpdateAttachmentEffects` (`TractorManager.cs:198-204`) y lo quita en `UpdateBuff(false)` al desmontar o abrir menú (`TractorManager.cs:208,280`). En un cliente que conduce, el buff está presente durante el sweep; si el jugador no conduce, no lo está.

#### 4. Opciones

| # | Opción | Parche exacto | Ámbito | Complejidad | Loot | Riesgo |
|---|---|---|---|---|---|---|
| A | No-op total de `createRadialDebris` en contexto tractor | Sobrecarga `int` + `string`, `return false` | Cliente que actúa | Baja | **Rompe** `resource:true` e `item:true` | Inaceptable |
| B | No-op solo visual (recomendada) | `Game1.createRadialDebris(GameLocation,int,int,int,int,bool,int,bool,Color?)`; `return false` solo si `!resource && !item` | Cliente que actúa | Baja-Media | Intacto | Sin chips; corrimiento de `recentMultiplayerRandom`; los `item:true` conservan loot (y sus 4 Debris vacíos) |
| C | Reducir chunks | misma sobrecarga `int` con `ref int numberOfChunks`; `Math.Min(N, 8)` solo si `!resource && !item` | Cliente que actúa | Baja | Intacto | Ahorro parcial: siguen 4 Debris; corrimiento de RNG; visual reducido |
| D | `TemporaryAnimatedSprite` local | misma sobrecarga `int`; crear TAS en `location.temporarySprites` y `return false` | Cliente que actúa (solo quien conduce lo ve) | Media-Alta | Intacto | Fidelidad visual distinta; código extra; corrimiento de RNG |
| E | Filtro en `NetCollection<Debris>.Add` | prefix en `Add(Debris)`, filtrando por tipo/campos | Cliente que actúa | Media; requiere prototipo | Intacto (con filtro) | Harmony sobre método genérico; cubre más; suprime visuales de otros mods; preserva RNG |
| F | Filtro solo de dibujo | `GameLocation.drawDebris` | Cada cliente | Media | Intacto | No ahorra red ni update; no ataca los kicks |

**A — no-op total.** El método es `public static void createRadialDebris(GameLocation location, int debrisType, int xTile, int yTile, int numberOfChunks, bool resource, int groundLevel = -1, bool item = false, Color? color = null)` (`Game1.cs:10300`). Un prefix que devuelva `false` siempre en contexto tractor salta también `resource:true` (madera/piedra de `Tree.cs:528,1545,1569` y `FruitTree.cs:310,811,815`) e `item:true` (`ResourceClump.cs:324`, `MineShaft.cs:3071`): **pierde loot**. Descartada.

**B — no-op solo visual.** Mismo método; el prefix comprueba el contexto y devuelve `false` únicamente cuando `resource == false && item == false` (además de excluir `debrisType == 8`, monedas). No toca `createItemDebris`, `createMultipleItemDebris`, `createDebris`, `resource:true` ni `item:true`. Es la opción con mejor relación seguridad/simplicidad: el loot no puede romperse por construcción. Lo que se pierde son solo los chips cosméticos; el `item:true` conserva su loot y sus 4 Debris vacíos (invisibles, overhead menor). En multijugador, la piedra grande usa `createMultipleObjectDebris` (`ResourceClump.cs:317-321`); el `item:true` de `ResourceClump.cs:324` es la rama single-player, y el de `MineShaft.cs:3071` es una caja de mina, no una acción del tractor. No cubre chips de mods que añadan `Debris` directamente (p. ej. la implementación propia de ItemExtensions) ni las sobrecargas `string`; para el tractor vanilla no hacen falta.

```csharp
[HarmonyPatch(typeof(Game1), "createRadialDebris", new[] {
    typeof(GameLocation), typeof(int), typeof(int), typeof(int), typeof(int),
    typeof(bool), typeof(int), typeof(bool), typeof(Color?)
})]
static bool Prefix(GameLocation location, int debrisType, int xTile, int yTile,
                   int numberOfChunks, bool resource, int groundLevel, bool item, Color? color)
{
    if (!IsTractorContext()) return true;  // null-safe: Game1.player?.buffs.AppliedBuffs.ContainsKey("Pathoschild.TractorMod") == true
    if (resource || item) return true;     // loot
    if (debrisType == 8) return true;      // monedas
    return false;                          // chips
}
```

Si se prefiere la señal exacta, el flag se engancha con `AccessTools.Method(AccessTools.TypeByName("Pathoschild.Stardew.TractorMod.Framework.TractorManager"), "UpdateAttachmentEffects")`; el prefix pone el flag a true, el postfix a false y un finalizer lo limpia si el método lanza.

**C — reducir chunks.** Prefix con `ref int numberOfChunks` sobre la misma sobrecarga; si el contexto es tractor y `!resource && !item`, `numberOfChunks = Math.Min(numberOfChunks, 8)`. No se puede aplicar a `resource:true`/`item:true` porque ahí `numberOfChunks` también determina la cantidad de loot (`Game1.cs:10323-10332` y `10307-10321`). Sigue creando 4 `Debris` por llamada; solo baja el número de `Chunk`. Útil si se quiere conservar el efecto visual; no es la solución máxima.

**D — TAS local.** En el prefix, crear uno o pocos `TemporaryAnimatedSprite` con la hoja `TileSheets\debris` (`Game1.cs:439,521`) y el rect de `Game1.getSourceRectForStandardTileSheet` (`Game1.cs:15400`), añadirlos a `location.temporarySprites` (`GameLocation.cs:255`) y devolver `false`. Si se añaden directamente, no se sincronizan; solo se sincronizan si se usa `Game1.multiplayer.broadcastSprites` (`Multiplayer.cs:445-466`). Quien conduce recupera feedback, pero los demás no lo ven y la física no es la de los chunks; el TAS sigue costando update/draw. Complejidad media-alta para un efecto cosmético.

**E — filtro en `debris.Add`.** Prefix sobre `NetCollection<Debris>.Add(Debris)` (`Netcode/NetCollection.cs:114-118`) con el filtro: `debris.GetType() == typeof(Debris)`, `debrisType == CHUNKS`, `chunkType != 8`, `item == null`, `itemId == null`. Ventajas: preserva el RNG (el `Debris` se construye igual), cubre cualquier creación visual (incluida la de mods que añaden `Debris` a mano) y no hay que reimplementar la rama `item:true`. Desventajas: es un método genérico (`NetCollection<T>.Add`) y Harmony puede aplicar el patch a la definición genérica; hay que probarlo en el prototipo. Además suprime cualquier `Debris` visual creado durante el contexto, aunque no sea del tractor, y no dispara los handlers de `OnValueAdded` (el evento `DebrisListChanged` de SMAPI/BirbCore dejaría de ver esos chips). Es la opción más completa si el prototipo confirma que el patch genérico es seguro.

**F — filtro de dibujo.** No merece la pena: `drawDebris` no tiene culling (`GameLocation.cs:15657-15715`), así que ocultar chips ahorra draw calls, pero el objeto sigue en la `NetCollection`, se actualiza (`GameLocation.cs:3955-3965`) y se sincroniza. No reduce el upload del host ni el trabajo de red, que es el objetivo del ticket.

**Otras variantes que sugiere el código.** (a) Sustituir los 4 `Debris` por uno solo con todos los chunks reduce headers de red, pero cambia el reparto visual y no elimina los chunks; (b) en `item:true`, reimplementar solo el bucle de items y saltar los 4 `Debris` vacíos ahorra 4 objetos de red por piedra grande/caja de mina, pero es un caso raro y añade código; (c) limitar la supresión a “más de un jugador en la location” no filtra nada útil: el caso que duele es precisamente host + un farmhand.

#### 5. Compatibilidad con los mods instalados

Verificado desensamblando los 106 DLLs de `~/.local/share/Steam/steamapps/common/Stardew Valley/Mods` con `ikdasm` (dumps en `/tmp/opencode/modildump/`):

- **Ningún mod parchea `Game1.createRadialDebris`.** Solo lo llaman FarmTypeManager, ItemExtensions y TrinketTinker (llamadas, no patches). Tampoco hay evidencia de patches sobre `Debris` ni sobre `NetCollection<Debris>.Add`.
- **SpaceCore** parchea `Game1.createItemDebris` con un prefix que puede suprimir item debris por ID (`SpaceCore.Dungeons.GameCreateDebrisPreventionPatch`, IL `SpaceCore_SpaceCore.dll.il:99721-99758`). No se toca en la opción B; no hay conflicto.
- **Stardew Valley Expanded** parchea `Game1.createMultipleItemDebris` (`SuppressPrismaticShardPatch3`; IL `...StardewValleyExpanded.dll.il:23803`). Es loot; la opción B no lo toca.
- **LoveOfCooking** parchea `GameLocation.drawDebris` con un postfix que dibuja sus `CoinDebris` (IL `LoveOfCooking_...dll.il:57393,57902-57947`). Menos chips = menos iteraciones; no se rompe. Su `CoinDebris` es una subclase de `Debris` con `debrisType=CHUNKS` y `chunkType=8` (IL `...:14100-14120`) y sobreescribe `collect` (`:14227`); la opción B no la toca porque no pasa por `Game1.createRadialDebris`. Si se eligiera E, el filtro debe excluir subclases y `chunkType == 8` para no comerse esas monedas.
- **ItemExtensions** tiene su propia copia privada de `CreateRadialDebris` (IL `ItemExtensions_ItemExtensions.dll.il:47266`) que añade `Debris` directamente; la opción B no la suprime. En la config instalada de Tractor Mod `CustomAttachments` está vacío (`.../Mods/TractorMod/config.json:114`), así que hoy no se usa desde el tractor.
- **Ningún mod instalado toca `TractorManager`**; el único DLL que lo referencia es el propio Tractor Mod (búsqueda en los IL).

### Suposiciones

- El ID de buff `Pathoschild.TractorMod` (`TractorManager.cs:27`) se mantiene estable en futuras versiones de Tractor Mod. Si cambia, la supresión deja de aplicarse (fallo seguro: vuelve el comportamiento vanilla), pero no hay garantía escrita.
- Suprimir chips no cambia el loot ni la sincronización. Es cierto para el vanilla verificado; un mod que espere encontrar `Debris` visuales en `location.debris` para su propia lógica podría notar la ausencia. No se ha encontrado ninguno instalado que lo haga.
- El corrimiento de `Game1.recentMultiplayerRandom` al saltarse `Debris.InitializeChunks` (`Debris.cs:565`) no cambia cantidades de loot. No verificado con A/B; la mayoría de tiradas de loot usan `Game1.random` o `Utility.CreateRandom` por tile, pero hay consumidores de `recentMultiplayerRandom` que sí podrían cambiar.
- El ahorro de CPU/red es suficiente para justificar el cambio. No medido en este ticket; hay que hacer A/B con el Profiler y una captura de red (ver ticket 01).
- El patch de la opción E sobre un método genérico funciona con la versión de Harmony de SMAPI 4.5.2. No probado; requiere el prototipo.
- Que la fidelidad visual de la opción D sea aceptable. No probada.

### Lo que requiere prueba en juego

- Host + dos clientes, con un farmhand conduciendo y con el host conduciendo: confirmar que los chips desaparecen para todos y que el loot (madera, piedra, fibra, semillas, musgo, fruta, piedra grande) sigue apareciendo y se puede recoger.
- Medir antes/después: frame time del cliente y del host, y tráfico con `LogNetworkTraffic` o el Profiler. No dar por hecho que los chips son el cuello; este ticket solo elimina una carga cosmética.
- Repetir en una tala grande (30-40 chips por árbol), piedra (2-5), arbusto (20-30), giant crop (4-9), resource clump (6-12) y en la mina.
- Probar el modo hold-to-activate: el buff está presente aunque no se esté aplicando el tractor; confirmar que suprimir chips de otras fuentes en ese estado es aceptable.
- Probar montar/desmontar, abrir menús, eventos y cambios de location: el buff debe desaparecer al desmontar y no debe quedar supresión residual.
- Verificar que el patch se aplica con Tractor Mod 4.24.4 y que, si el método/ID no existe, el mod no suprime nada y escribe un warning.
- Si se elige E: verificar que Harmony parchea `NetCollection<Debris>.Add` sin afectar a otras `NetCollection<T>`, que el RNG queda intacto y que `CoinDebris` y los item debris siguen funcionando.

### Recomendación

1. **v1: opción B, con el buff como señal de contexto y solo la sobrecarga `int`.** Es el cambio más pequeño que elimina los chips visibles del tractor sin poder tocar el loot: el prefix devuelve `false` solo si `!resource && !item`; `resource:true` (madera/piedra) e `item:true` (piedra grande/caja de mina) quedan intactos. No hace falta parchear las sobrecargas `string`: no se ha encontrado ningún path del tractor vanilla que las use.
2. **Instalar en host y en todos los clientes que conducen.** En el host solo no sirve para farmhands; el cliente que ejecuta la acción es el único que puede no crear el objeto. Si el host también conduce, su propia copia lo suprime.
3. **Señal:** el buff `Pathoschild.TractorMod` es el proxy más simple y cubre también llamadas diferidas (`DelayedAction`) y efectos de proyectiles. Si se quiere atribución exacta y evitar suprimir chips ajenos mientras se conduce, sustituir la señal por un flag Harmony en `TractorManager.UpdateAttachmentEffects()` (prefix/postfix, con finalizer para limpiar si el método lanza). No usar `Game1.player.mount` ni el `modData` del caballo: durante el sweep el mount está a `null`.
4. **Si el resultado visual sin chips no gusta:** usar C (clamp a 8) como paso intermedio, o D (TAS local) detrás de un toggle. No implementar ambas a la vez.
5. **No usar A** (rompe loot) ni un filtro solo-host (no cubre farmhands). **E** queda como mejora opcional si el prototipo demuestra que el patch genérico es seguro y se quiere cubrir también debris visual de mods; no es necesaria para el vanilla.
6. **No tocar** `createItemDebris`, `createMultipleItemDebris`, `createDebris`, `resource:true` ni `item:true`. Añadir un test de aceptación que cuente loot antes/después.

### Qué implica para el mapa

- El companion **debe estar en todos los clientes que conducen**, no solo en el host. El mapa ya dice “host y clientes”; este ticket lo convierte en requisito funcional: con una instalación solo-host, esta optimización no reduce nada del tráfico de los farmhands.
- La supresión de chips es independiente del throttle de tiles y del culling: elimina objetos cosméticos que hoy se sincronizan, se actualizan y se dibujan sin culling por distancia. No requiere cambiar `Distance`, `TractorSpeed` ni `MagneticRadius`.
- La detección depende de un contrato de Tractor Mod (el ID del buff o el nombre del método privado). Hay que implementar fallo seguro: si no está, no se suprime y se avisa en el log; nunca romper el arranque por un patch que no aplica.
- El ticket de culling no puede asumir que `GameLocation.debris` se pueda cullar por jugador: es una `NetCollection` de la location y el draw no comprueba viewport. La supresión en origen es la palanca segura para los chips; el culling de loot es otro problema.
- El baseline local de Tractor Mod tiene `Distance: 16` (`~/.local/share/Steam/steamapps/common/Stardew Valley/Mods/TractorMod/config.json:2`), no 4 como el servidor real (`map.md:9`). Los tests locales generan muchas más acciones y chips por sweep; no extrapolar el ahorro directamente al servidor.
- Para el mapa: los chips pasan de “pendiente de investigación” a “suprimibles en origen, ámbito cliente que conduce, sin tocar loot”. La implementación y la medición quedan para el prototipo (07) y la aceptación (06).
