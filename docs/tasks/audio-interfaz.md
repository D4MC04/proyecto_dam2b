# Sonidos de interfaz, victoria, derrota y ambiente

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Nada reproduce `SFXs/` (los clics, `GameOver` y `Victory`) ni `LevelAmbience/`: los botones no suenan, la victoria y la derrota llegan en silencio y los niveles no tienen ambiente.

## Qué hay que hacer
- **Antes de implementar, preguntar al usuario** qué clic usar entre `Click3`, `Click4` y `Click5` (`Click1` y `Click2` ya se probaron el 2026-10-21 y no gustaron), y qué ambiente va en los niveles (`DarkestVoid`, `EchoOfTheVoid` o alternarlos).
- **Clic:** un autoload nuevo (`UiSounds`) que escuche `get_tree().node_added` y conecte `pressed` de cada `BaseButton`. Bus `SFX` y `process_mode = ALWAYS`, para que suene también con el juego en pausa.
- **Derrota y victoria:** `GameOver` cuando se muestra `GameOverScreen` (`_on_visibility_changed`) y `Victory` al empezar la intro de `VictoryScreen` (`_start_intro`, tras la cámara lenta). Bus `SFX`.
- **Ambiente:** un `AudioStreamPlayer` en el nivel, en bucle, a volumen bajo (por ejemplo -18 dB, ajustar de oído) y en el bus `SFX`. Arranca en `Level._ready` y se para solo al salir de la escena. Se pausa con el juego.
- Docs: ui.md (clic, victoria y derrota), niveles.md (ambiente) y flujo.md (autoload nuevo). Quitar de menu.md la frase "Es el único audio del juego...".

## Archivos que toca
- scripts/autoloads/UiSounds.gd (nuevo) + project.godot
- scripts/level_ui/GameOverScreen.gd, VictoryScreen.gd
- scripts/level/Level.gd (o su escena)
- docs/design/ui.md, niveles.md, flujo.md, menu.md

## Cómo se prueba a mano
1. F5: en el menú principal, al pulsar Jugar, un nivel u Opciones suena el clic.
2. En el nivel suenan comprar torre, lanzar oleada, AUTO y ×2, y en pausa también los botones del menú de pausa.
3. Durante el nivel se oye el ambiente bajo, en bucle, sin tapar la música ni los disparos.
4. Perder: al salir la pantalla de derrota suena `GameOver`. Ganar: suena `Victory` cuando entra la pantalla de victoria.
5. "Efectos" a 0 en Opciones silencia los clics, el ambiente, la victoria y la derrota.
