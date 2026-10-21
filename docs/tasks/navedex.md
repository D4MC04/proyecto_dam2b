# Navedex: archivo de enemigos en el menú

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
Los 12 enemigos tienen sprite, descripción y stats, pero solo se ven en la ficha durante la partida. Un archivo tipo "pokédex" en el menú da ganas de descubrirlos todos.

## Qué hay que hacer
- Botón "ARCHIVO" en `ButtonsPanel` del título (mismo tamaño y estilo que "Jugar"/"Opciones"), con el mismo fundido para entrar y salir.
- Panel holograma (`OverlayFrame`) con cabecera `// ARCHIVO` (`ScreenHeader`), una cuadrícula de los 12 enemigos (celdas como `EnemyCell`) y, al lado, el detalle del elegido: sprite animado (`up`) a ×2, nombre, `description` y stats con `get_stats()` y `StatRow`. Botón "Volver".
- Los enemigos que aún no han salido en una partida se ven como silueta negra (`modulate` negro) y el detalle dice "???".
- `GameState`: guardar los enemigos vistos junto al progreso (por nombre de archivo del `EnemyData`); `Spawner._spawn` los marca. `reset_progress` los borra.

## Archivos que toca
- scenes/MainMenu.tscn, scripts/screens/MainMenu.gd
- scenes/Navedex.tscn + scripts/screens/Navedex.gd (nuevos)
- scripts/autoloads/GameState.gd, scripts/level/Spawner.gd
- docs/design/menu.md, docs/design/flujo.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y pulsar ARCHIVO: salen 12 celdas; las no vistas, en silueta.
2. Jugar la primera oleada del nivel 1 y volver: los Dart y el Wasp ya se ven en color.
3. Elegir uno: sale animado con su nombre, descripción y stats.
