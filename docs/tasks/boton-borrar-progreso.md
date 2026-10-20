# Botón "Borrar progreso" en Opciones

Estado: aceptada
Modelo recomendado: sonnet

## Por qué
Desde que se guarda el progreso, la única forma de volver a empezar es borrar `user://progress.cfg` a mano (docs/design/flujo.md lo deja como pendiente). Hace falta para jugar desde cero y para probar el desbloqueo de niveles.

## Qué hay que hacer
- En `OptionsMenu`, una fila "Borrar progreso" con el botón de esquinas recortadas que ya usa la UI.
- Al pulsarlo, pedir confirmación en el mismo botón (el texto cambia a "¿Seguro? Pulsa otra vez" durante unos segundos) para no borrarlo sin querer.
- Al confirmar, una función tipada en `GameState` vuelve `current_level` a 1, guarda y el menú de selección de nivel se actualiza al volver.
- Actualizar docs/design/flujo.md (quitar el pendiente) y docs/design/menu.md.

## Archivos que toca
- scripts/screens/OptionsMenu.gd
- scenes/OptionsMenu.tscn
- scripts/autoloads/GameState.gd
- docs/design/flujo.md, docs/design/menu.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` (F5), ganar el nivel 1 para desbloquear el 2.
2. Ir a Opciones → "Borrar progreso": cambia a "¿Seguro?". Pulsar otra vez.
3. Volver y entrar en selección de nivel: solo el nivel 1 abierto, "SECTORES 1/…".
4. Cerrar y abrir el juego: sigue solo el nivel 1.
