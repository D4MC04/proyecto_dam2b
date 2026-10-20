# Sonidos de interfaz, victoria y derrota

Estado: propuesta
Modelo recomendado: sonnet

## Por qué
`assets/audio/effects/SFXs/` tiene 5 clics, `GameOver.wav` y `Victory.wav`, y `LevelAmbience/` dos ambientes; nada los reproduce. Los botones no suenan y la derrota y la victoria llegan en silencio (aparte de la música).

## Qué hay que hacer
- Clic en los botones: un solo sitio que lo haga para todos, sin tocar cada botón (por ejemplo, un autoload pequeño que escuche `get_tree().node_added` y conecte `pressed` de cada `BaseButton`). Elegir uno de los `Click*.wav` (o dos: uno para botones normales y otro para comprar/colocar torre). Bus `SFX`, y que suene también con el árbol en pausa (`process_mode = ALWAYS`).
- `GameOver.wav` cuando aparece `GameOverScreen` y `Victory.wav` cuando entra `VictoryScreen` (tras la cámara lenta / el respiro, no antes).
- Opcional si es fácil: un ambiente de `LevelAmbience/` en bucle muy bajo durante el nivel, en el bus `SFX`. Si choca con `MusicManager`, dejarlo fuera y avisar.
- Actualizar docs/design/ui.md y docs/design/flujo.md (si se añade autoload).

## Archivos que toca
- scripts/autoloads/ (nuevo autoload de sonidos de UI) + project.godot
- scripts/level_ui/GameOverScreen.gd, VictoryScreen.gd
- docs/design/ui.md, docs/design/flujo.md

## Cómo se prueba a mano
1. F5: en el menú principal, al pulsar Jugar, un nivel u Opciones suena un clic.
2. En el nivel, comprar torre, lanzar oleada, AUTO y ×2 suenan; en pausa, los botones del menú de pausa también.
3. Perder un nivel: al salir la pantalla de derrota suena `GameOver`. Ganarlo: al entrar la victoria suena `Victory`.
4. "Efectos" a 0 en Opciones silencia todo esto.
