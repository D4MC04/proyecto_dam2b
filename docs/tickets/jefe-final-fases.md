# Fases del jefe final: se vuelve inmune a las torretas usadas

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Si el jefe deja de recibir daño de las torretas que el jugador estaba usando, este tiene que cambiar su defensa a mitad de la batalla.

## Qué hay que hacer
- **Hacerlo después de `jefe-final-batalla`**, que crea `FinalBoss.gd`.
- Al empezar, preguntar al usuario:
  - A qué se vuelve inmune en cada fase: a la versión (normal o mejorada) con la que más daño le han hecho, o a los tipos de torreta concretos que se usaban.
  - Cuánta vida hay que bajarle para cambiar de fase.
- Al bajarle esa vida, el jefe cambia de fase con un aviso visible. Desde entonces y hasta el final de la batalla, esas torretas ya no le hacen daño, y al golpearle se ve que es inmune.
- Saber quién le hace daño con el `source` que ya recibe `take_damage` (las torretas ya cuentan su daño con `register_damage`).

## Archivos que toca
- scripts/entities/FinalBoss.gd
- scripts/level_ui/LevelUI.gd
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Nivel 10 solo con torretas normales: al bajarle la vida pactada, cambia de fase con aviso.
2. Desde entonces las torretas normales no le quitan vida y se ve que es inmune. Con las otras (mejoradas u otro tipo, según lo decidido) sí.
