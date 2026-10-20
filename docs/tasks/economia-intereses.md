# Intereses y bonus de oleada perfecta

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El dinero solo sale de matar enemigos, así que da igual gastarlo todo enseguida o ahorrar. Con intereses y un premio por no recibir daño, ahorrar y defender bien tienen recompensa.

## Qué hay que hacer
- Al limpiar cada oleada (`Spawner.wave_cleared`), menos la última:
  - **Intereses**: +10 % del dinero que se tiene, redondeado hacia abajo, con un máximo de 50 € por oleada.
  - **Oleada perfecta**: +25 € si en esa oleada no llegó ningún enemigo a la estación.
- Constantes con nombre claro en un solo sitio para poder ajustarlas.
- Que se vea: un `+X€` flotante (`FloatingText`, ya existe) sobre la estación por cada premio, con texto corto ("INTERÉS +12€", "PERFECTA +25€").
- No cambia "Decidido": la oleada siguiente sigue sin poder lanzarse antes de que acabe la anterior.
- Actualizar docs/design/niveles.md (LevelState).

## Archivos que toca
- scripts/level/Level.gd (conectar `wave_cleared` y los golpes a la estación)
- scripts/level/LevelState.gd
- docs/design/niveles.md

## Cómo se prueba a mano
1. F5, nivel 1. Colocar una torre y guardar el resto del dinero.
2. Al acabar la oleada 1 sin que entre nadie: salen "INTERÉS +X€" y "PERFECTA +25€" sobre la estación y el dinero sube eso.
3. Dejar pasar un enemigo en la oleada 2: al acabarla solo sale el interés.
4. Con mucho dinero ahorrado, el interés no pasa de 50 €.
