# Balance de stats y de dinero

Creador: David
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Las stats, los costes y el dinero se fueron poniendo torreta a torreta y el dinero inicial es 5000 en todos los niveles. Hace falta una base razonable antes de rehacer las oleadas, para que luego el usuario la pruebe y la ajuste.

## Qué hay que hacer
- Revisar las stats de las torretas (daño, cadencia, alcance) y de los enemigos (vida, velocidad, daño a la estación) y ajustar las que estén descompensadas. Que cada torreta valga lo que cuesta.
- Coste de cada torreta coherente con lo que hace y con el orden en que se desbloquea (ver docs/tickets/desbloqueo-torretas.md o, si ya está hecho, docs/design/niveles.md).
- Mejora (fusión): `fusion.cost` = 2 × coste de la base, en todas. Vender sigue siendo la mitad de lo invertido (ya es así).
- Recompensa (`reward`) de cada enemigo, en proporción a lo que cuesta matarlo.
- Dinero inicial por nivel: un campo en `LevelData` (en vez del 5000 fijo de `LevelState.money`), con un valor por nivel.
- Dejar en la tabla de docs/design/torretas.md y enemigos.md los valores nuevos para que el usuario pueda ajustarlos.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Mejorar (fusión)", "Vender", "Datos", "Amplificador"
- docs/design/enemigos.md › "Datos"
- docs/design/niveles.md › "Datos de nivel", "Generador de oleadas" (presupuesto)
- scripts/level/LevelState.gd › `money`, `add_money()`
- scripts/resources/LevelData.gd

## Archivos que toca
- resources/turret_data/*.tres, resources/bullet_data/, resources/pulse_data/, resources/chain_data/, resources/beam_data/, resources/focus_beam_data/
- resources/enemy_data/*.tres
- scripts/resources/LevelData.gd, scripts/level/LevelState.gd (y quien monte el nivel, para pasarle el dinero inicial)
- resources/level_data/level_*.tres (y el nivel 5 de `GameData.tscn`)
- docs/design/torretas.md, docs/design/enemigos.md, docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 1: empieza con el dinero inicial nuevo, no con 5000.
2. Seleccionar una torreta colocada: "Mejorar" cuesta el doble que la torreta y vender devuelve la mitad de lo invertido.
3. Matar enemigos: el `+X€` flotante enseña las recompensas nuevas.
