# Nave nueva: Magpie

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Todas las naves castigan igual: quitando vida a la estación. Ninguna amenaza el dinero. La Magpie te roba todo lo que ganes mientras está viva, y obliga a decidir: matarla ya o dejarla engordar y reventarla luego.

## Qué hay que hacer
- Mientras haya una Magpie viva, todo el dinero que ganes (bajas, Mineros, bonus de oleada perfecta) va a ella y no a `LevelState`. Con varias, se lo queda la más antigua.
- En cada robo, en vez del `+15€` dorado sale `-15€` en morado (sin icono), donde se iba a ganar: sobre la nave muerta o sobre el Minero.
- Lleva un cristal en el vientre que crece y brilla más según lo robado: 4 tamaños dibujados (de 16 a 32 px, sin escalar el sprite). Cada tamaño la hace más grande (colisión mayor) y más lenta: de 60 a 30 px/s.
- Encima de ella, el total robado.
- Al matarla, el cristal estalla y suma de golpe lo robado más su botín (texto dorado grande). Si llega a la estación, lo robado se pierde (`-X€` en rojo).
- Stats de docs/design/naves-plan.md (75 de vida, 10 de daño, botín 20).
- Sprite con `scripts/tools/make_magpie.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`), textos en `translations/textos.csv` y `description`.
- Añadirla a `LEVELS` de `scripts/tools/make_waves.gd` (nivel propuesto: 5), regenerar y comprobar la Navedex.
- Al terminar: pasarla a docs/design/enemigos.md y quitarla de naves-plan.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › Magpie
- docs/design/enemigos.md › "Datos", "Daño y muerte" y "Efectos visuales"
- docs/design/niveles.md › "LevelState" y "Generador de oleadas"
- docs/design/torretas.md › "Minero"
- scripts/autoloads/LevelState.gd (o donde esté) › `add_money()`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd y FloatingText.gd
- LevelState (donde se suma el dinero)
- resources/enemy_data/magpie.tres
- assets/sprites/enemies/magpie/ y scripts/tools/make_magpie.gd
- translations/textos.csv
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- docs/design/enemigos.md, docs/design/niveles.md y docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 5 con un Minero.
2. Con la Magpie viva, cada baja y cada cobro del Minero saca `-X€` en morado, el dinero no sube y el cristal de la Magpie crece mientras ella va más lenta.
3. Al matarla sale el total en dorado y el dinero sube de golpe. Si llega a la estación, se pierde.
