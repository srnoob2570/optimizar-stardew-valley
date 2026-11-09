# Prototipo: throttle + supresión de chips

Type: prototype
Status: open
Blocked by: 02, 03, 04, 05, 06

## Question

Construir un prototipo mínimo con Harmony que:

- Limite los tile-actions por tick según la política del ticket de throttle.
- Suprima o localice los chips visuales según la investigación de chips.
- No implemente culling si la política de culling no lo autoriza.

Validar en single-player y con dos jugadores usando la matriz de pruebas. Medir antes/después y entregar diff y resultados. No hacer merge.
