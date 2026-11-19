# Repartir los huecos de torreta de forma uniforme

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
En varios niveles hay muchos más huecos de torreta junto a unos caminos que junto a otros, o en unas zonas de la pantalla que en otras. Queremos un reparto uniforme.

## Qué hay que hacer
- Revisar los `slots` de los 9 niveles y repartirlos de forma uniforme: cantidades parecidas junto a cada camino (o rama) y por zonas de la pantalla, sin zonas vacías ni amontonadas.
- Mantener el número de huecos de cada nivel (17-24, ver docs/design/torretas.md) salvo que haga falta tocarlo para el reparto, y la simetría de los niveles 4, 8 y 9.
- Cada hueco fuera del pasillo y lo bastante cerca de un camino para que valga la pena.
- Va después de `caminos-curvos`, porque los huecos dependen de la forma de los pasillos.
- Regenerar los mapas con el generador; no escribir `tile_map_data` a mano.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Mapas de los niveles" y "Generador de mapas"
- scripts/tools/map_generator.gd › cabecera (formato), `_place_turret_slots()`
- resources/map_data/level_1.txt a level_9.txt (`slots`)

## Archivos que toca
- resources/map_data/level_1.txt a level_9.txt
- scenes/maps/levels/Level1.tscn a Level9.tscn (regenerados)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar cada nivel (al menos 2, 6 y 9) y mirar el mapa entero.
2. Los huecos están repartidos por igual entre los caminos y por la pantalla, sin zonas vacías ni amontonadas.
3. Todos los huecos se pueden usar y quedan cerca de algún camino.
