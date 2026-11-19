# Más bases de torreta en los niveles 6 a 9

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
En los niveles 6 a 9 faltan sitios para colocar torretas en zonas clave del camino. Renzo marcó en capturas dónde quiere bases nuevas.

## Qué hay que hacer
- Añadir casillas de torreta a la línea `slots` de `resources/map_data/level_6.txt` a `level_9.txt`. Las marcas de Renzo indican la zona, no la casilla exacta; estas son las casillas estimadas (columna,fila), a 2 casillas del camino como las que ya hay:
  - **Nivel 6** (4): `12,2` y `27,2` (arriba del todo, sobre el camino de la fila 4); `26,6` (fila superior, a media anchura, entre `18,6` y `35,6`); `39,13` (borde derecho, al lado del camino de la columna 37).
  - **Nivel 7** (1): `39,18` (borde derecho a media altura, junto al camino de la columna 37 por donde entran los enemigos).
  - **Nivel 8** (4): `18,13`, `24,13`, `18,20`, `24,20` (a los dos lados del pasillo central de la columna 21, en dos alturas). Mantiene la simetría.
  - **Nivel 9** (8): `13,4`, `29,4`, `13,28`, `29,28` (fuera de los caminos de las filas 6 y 26) y `14,14`, `28,14`, `14,18`, `28,18` (a los lados de los caminos de la fila 16, junto a la estación). Mantiene la simetría en los dos ejes.
- Si alguna cae sobre el pasillo, pegada a otra casilla de torreta o tapando la estación, moverla una casilla en la misma zona.
- Regenerar solo esos mapas: `godot --headless --path . -s scripts/tools/map_generator.gd -- 6`, y lo mismo con 7, 8 y 9. No tocar a mano los `.tscn`.

## Qué leer
- docs/design/niveles.md › "Mapas de los niveles" y "Generador de mapas"
- scripts/tools/map_generator.gd › cabecera (formato del `.txt`)
- resources/map_data/level_6.txt a level_9.txt

## Archivos que toca
- resources/map_data/level_6.txt, level_7.txt, level_8.txt, level_9.txt
- scenes/maps/levels/Level6.tscn a Level9.tscn (regenerados por el script)

## Cómo se prueba a mano
1. Jugar los sectores 6, 7, 8 y 9.
2. Comprobar que hay asteroides con plataforma nuevos en las zonas marcadas (nivel 6: dos arriba del todo, uno en la fila de arriba a media anchura y uno en el borde derecho; nivel 7: borde derecho a media altura; nivel 8: cuatro junto al pasillo central; nivel 9: ocho alrededor de la estación).
3. Colocar una torreta en cada una: se puede, y los enemigos siguen pasando por el pasillo sin chocar con nada.
