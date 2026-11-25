# Mapa del tutorial más presentable

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
El nivel de emergencia (el del tutorial) ya tiene curvas, pero se ve muy mal. Las curvas en U son tan cerradas y los tramos verticales están tan juntos que hay partes con filas enteras de piedrecitas pequeñas. El problema es solo visual: las curvas ya funcionan.

## Qué hay que hacer
- Cambiar el camino de `resources/map_data/emergency.txt` separando más los tramos verticales (ahora van cada 4 casillas: x = 30, 26, 22, 18), para que las curvas en U no sean tan cerradas y entre los tramos quepa una decoración como la de los demás niveles.
- Recolocar sus tres `slots` para que se siga cumpliendo lo que pide el tutorial: una casilla de torreta dentro de cada curva cerrada, y que cada torreta alcance las dos pasadas y la curva (ver la cabecera de `emergency.txt`). Mirar si el tutorial depende de dónde están esas casillas.
- Regenerar el mapa con el generador (`godot --headless --path . -s scripts/tools/map_generator.gd -- emergency`), nunca a mano. Que no queden filas de piedrecitas pequeñas: debería verse como los niveles 1 a 9.
- Si con el cambio de camino no basta y hace falta tocar el generador, que no cambie los niveles 1 a 9 ni los mapas de la Navedex.

## Qué leer
- resources/map_data/emergency.txt (entero, es corto)
- scripts/tools/map_generator.gd › cabecera (formato de los datos) y `_place_bend_edges()`
- docs/design/niveles.md › la sección del nivel de emergencia (sacarla con Grep `^#`)
- docs/design/ui.md › "Tutorial del nivel de emergencia" (solo si el tutorial apunta a casillas concretas)

## Archivos que toca
- resources/map_data/emergency.txt
- scenes/maps/levels/Emergency.tscn (lo regenera el generador)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Abrir el nivel de emergencia (`/test` en el chat del ticket lo abre ya empezado).
2. Las curvas en U deberían ser más abiertas y no deberían verse filas de piedrecitas pequeñas: debería parecer tan cuidado como el nivel 2.
3. Jugar el tutorial: cada torreta en su casilla debería alcanzar las dos pasadas de su curva, y el tutorial debería seguir funcionando igual.
