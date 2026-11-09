# Política de culling

Type: grilling
Status: open
Blocked by: 02, 03

## Question

¿Qué se culla y con qué autoridad?

- Solo visual debris, o también item debris.
- Distancia/umbral y si es por jugador o global.
- ¿Se puede hacer interés por cliente con SMAPI/`NetCollection`, o solo borrar/despawnear en el host?
- Cómo evitar pérdida de loot o desincronización; qué pasa cuando un jugador se acerca.
- Alternativa segura: no culling de loot; solo chips visuales y limpieza de debris viejos.

Recomendación: v1 solo visual debris; no tocar item debris. El culling v1 **no elimina el burst de cultivos**, que son item debris; el throttle lo suaviza, no lo borra. Si tras throttle + chips el p99 no mejora, abrir ticket de auto-collect/merge. Si hace falta limpiar loot, hacerlo por timeout con aviso, nunca borrado silencioso.
