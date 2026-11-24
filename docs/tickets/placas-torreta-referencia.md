# Recolocar las placas de torreta a partir del nivel 2

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Las placas de torreta (los asteroides con plataforma) siguen sin estar bien colocadas: su posición, cantidad y reparto no convencen. El usuario dará una captura del nivel 2 con las placas como deberían quedar, y el resto de niveles tiene que seguir el mismo criterio.

## Qué hay que hacer
- Antes de tocar nada, pedir al usuario la captura del nivel 2 y esperar a tenerla.
- Pasar el nivel 2 a lo que enseña la captura: ajustar sus `slots` en `resources/map_data/level_2.txt` hasta que el mapa generado coincida con la captura en posición, cantidad y reparto de las placas.
- Sacar de esa referencia el criterio (cuántas placas por camino o tramo, distancia al pasillo, separación entre ellas, cómo se reparten por la pantalla) y explicárselo al usuario en pocas líneas antes de seguir.
- Aplicar ese criterio a los niveles 1 y 3 a 9 y al nivel de emergencia, manteniendo la simetría de los niveles 4, 8 y 9.
- Si hace falta, ajustar el generador (`_place_turret_slots()`, comprobaciones de casillas mal puestas) para que el criterio se cumpla; los mapas se regeneran con él, no se escribe `tile_map_data` a mano.
- Va antes de `curvas-orilla-natural`, que toca el mismo generador.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Mapas de los niveles" y "Generador de mapas"
- scripts/tools/map_generator.gd › cabecera (formato), `_place_turret_slots()` y la comprobación de casillas de torreta mal puestas
- resources/map_data/level_1.txt a level_9.txt y emergency.txt (`slots`)
- La captura del nivel 2 que dé el usuario

## Archivos que toca
- resources/map_data/level_*.txt y emergency.txt
- scripts/tools/map_generator.gd (si hace falta)
- scenes/maps/levels/Level1.tscn a Level9.tscn y Emergency.tscn (regenerados)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 2: las placas están como en la captura.
2. Jugar los niveles 1, 5 y 9: las placas siguen el mismo criterio que el nivel 2 (cantidad, distancia al camino y reparto por la pantalla).
3. Poner torretas en varias placas y lanzar una oleada: todas se pueden usar y las naves no las pisan.
