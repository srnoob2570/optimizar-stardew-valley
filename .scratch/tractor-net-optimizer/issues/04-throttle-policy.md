# Política de throttle de tiles

Type: grilling
Status: open
Blocked by: 03

## Question

Definir la política del throttle:

- ¿Se aplica en `TractorManager.UpdateAttachmentEffects` de forma global o por attachment?
- Presupuesto de tile-actions por tick: 12, 20, 27, 40 u otro; latencia máxima aceptable.
- ¿Cola FIFO, rotación de la rejilla o deduplicación?
- ¿Qué pasa si el tractor se mueve o cambia de herramienta antes de procesar la cola?
- ¿Prioridad por herramienta (hacha/guadaña) o política global?
- Cómo convive con `TicksPerAction = 12` y los 81 tiles de `Distance: 4`.

Recomendación: cola global acotada, 20 tile-actions por tick, FIFO, descartar entradas obsoletas si el tractor se aleja más de 2 tiles, sin prioridad por herramienta en la v1.
