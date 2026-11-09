# Política de throttle de tiles

Type: grilling
Status: open
Blocked by: 03

## Question

Definir la política del throttle:

- ¿Se aplica en `TractorManager.UpdateAttachmentEffects` de forma global o por attachment?
- Presupuesto de tile-actions por tick: 12, 20, 27, 40 u otro; latencia máxima aceptable. Distinguir **cap** (techo por tick) de **promedio** (6.75 con 81 tiles / 12 ticks): un cap de 20 todavía permite 20 acciones con debris en un tick.
- ¿Cola FIFO, rotación de la rejilla o deduplicación?
- ¿Qué pasa si el tractor se mueve o cambia de herramienta antes de procesar la cola?
- ¿Prioridad por herramienta (hacha/guadaña) o política global?
- Cómo convive con `TicksPerAction = 12` y los 81 tiles de `Distance: 4`.

Recomendación: cola global acotada con **cap configurable**; valor inicial 12 tile-actions/tick y medir 7/12/20. Un cap de 20 no debe drenar el sweep en 5 ticks y dejar 7 ticks idle; el objetivo es suavizar el pico, no solo moverlo. FIFO, descartar entradas obsoletas si el tractor se aleja más de 2 tiles, **registrar cada descarte** y medir cobertura; sin prioridad por herramienta en v1.
