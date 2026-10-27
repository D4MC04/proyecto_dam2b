# Batalla final contra el jefe que envía las naves

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El juego acaba en el nivel 9 sin un cierre. Una batalla final contra quien manda todas las naves da un final al juego.

## Qué hay que hacer
- Al empezar, preguntar al usuario qué forma tiene el jefe (nave gigante, ente…). Mientras no se decida, sprite provisional grande con un script de `scripts/tools/` siguiendo art.md.
- Nivel nuevo tras el 9: `level_10.tres` con su mapa generado con `map_generator.gd` y todas las torretas del juego. Añadirlo a `GameData.levels` (el botón 10 sale solo en el menú y se desbloquea al ganar el 9).
- Jefe con su `EnemyData` y su propio script `FinalBoss.gd` (hereda de `Enemy`, sin tocar `Enemy.gd`). Sale por el portal con `BossAlert`, avanza y se para frente a la base, sin recorrer todo el camino.
- Barra de vida grande del jefe arriba de la pantalla mientras viva.
- Mientras el jefe vive, salen naves que ya existen (`resources/enemy_data/`) cada cierto tiempo para defenderlo.
- Se gana al bajarle toda la vida al jefe (`Level` emite `won`). Es el último nivel: la victoria no ofrece "Siguiente nivel".
- Los ataques del jefe a torretas y a la base van en `jefe-final-ataques`, y las fases en `jefe-final-fases`.

## Archivos que toca
- scripts/entities/FinalBoss.gd y scenes/entities/FinalBoss.tscn (nuevos)
- scripts/tools/make_final_boss.gd (nuevo)
- resources/enemy_data/final_boss.tres (nuevo)
- resources/level_data/level_10.tres y scenes/maps/levels/Level10.tscn (nuevos, generados)
- scenes/GameData.tscn
- scripts/level/Spawner.gd
- scripts/level/Level.gd
- scripts/level_ui/LevelUI.gd
- docs/design/enemigos.md, docs/design/niveles.md, docs/design/flujo.md

## Cómo se prueba a mano
1. Ganar el nivel 9: se desbloquea el nivel 10 en el menú.
2. Jugar el nivel 10: el jefe sale con su aviso, se para frente a la base y se ve su barra de vida grande arriba.
3. Mientras vive van saliendo naves que lo defienden.
4. Bajarle toda la vida: victoria sin botón de "Siguiente nivel".
