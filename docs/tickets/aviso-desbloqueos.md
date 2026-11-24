# Aviso de desbloqueos reutilizable

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
Cuando el jugador desbloquea algo (una torreta nueva, un sector...) no se le enseña: tiene que darse cuenta solo. Como la forma de desbloquear puede cambiar (por ejemplo, poderes de pago en `poderes-desbloqueables`), hace falta una mini pantalla de aviso que valga para cualquier contexto.

## Qué hay que hacer
- Una mini pantalla de aviso reutilizable (escena propia): un desbloqueo con icono, nombre, tipo ("TORRETA NUEVA", "SECTOR NUEVO"...) y una frase; varios seguidos se enseñan uno tras otro. Que no dependa de qué se desbloquea ni de dónde se abre: recibe los datos y avisa cuando se cierra.
- Una cola de desbloqueos pendientes de enseñar (en `GameState` o donde encaje) que se llena donde se desbloquean las cosas (`GameState.complete_level()`: la torreta de `GameData.turret_order` del nivel siguiente y el sector siguiente) y se vacía al enseñarlos, para que cada uno se vea una sola vez. Si hay que guardarla, que sobreviva a cerrar el juego.
- Usarla al volver a la oficina tras ganar un sector (la victoria ya lleva a la oficina; ver ticket `fin-partida-mejorado`), sin chocar con la llamada de socorro ni con el tutorial de la oficina.
- Estilo de la interfaz del juego (docs/design/art.md y los colores de ui.md).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/flujo.md › "Autoloads" (`GameState`) y "Victoria"
- docs/design/niveles.md › "Datos de nivel" (orden de desbloqueo de torretas)
- docs/design/menu.md › "Oficina", "Comportamiento", "Llamada de socorro" y "Tutorial de la oficina"
- docs/design/art.md
- scripts/autoloads/GameState.gd › `complete_level()`, `is_unlocked()`, guardado de la ranura
- scripts/screens/MainMenu.gd › arranque de la oficina (`_ready()` y lo que lanza la llamada de socorro o el tutorial)

## Archivos que toca
- scenes/ y scripts/ nuevos de la mini pantalla
- scripts/autoloads/GameState.gd
- scripts/screens/MainMenu.gd y scenes/MainMenu.tscn
- docs/design/menu.md, docs/design/flujo.md

## Cómo se prueba a mano
1. Empezar una partida nueva y ganar el sector 1.
2. Al volver a la oficina sale el aviso de la torreta nueva (Minigun) y del sector nuevo, uno tras otro.
3. Cerrarlos y volver a entrar en la oficina: no vuelven a salir.
