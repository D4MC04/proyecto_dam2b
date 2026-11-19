# El ataque orbital (tecla R) hace mucho más daño

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
El rayo orbital apenas hace daño: barre el mapa entero en 2 s con 12 px de ancho, así que cada nave está bajo el rayo unas centésimas de segundo y con `ORBITAL_DPS` = 400 recibe solo unos pocos puntos.

## Qué hay que hacer
- En `Powers.gd`, cambiar el daño por segundo por un golpe fijo: cada enemigo que toca el rayo recibe una vez por ataque `ORBITAL_DAMAGE` (p. ej. 300: mata a las naves normales y deja tocadas a las grandes como el Acorazado, 420 PV, o la Nodriza, 600 PV). Guardar los enemigos ya golpeados en ese ataque para no repetir, y vaciarlo al lanzar el siguiente.
- Quitar `ORBITAL_DPS` si deja de usarse.

## Qué leer
- docs/design/niveles.md › "Poderes" (punto "Ataque orbital")
- scripts/level/Powers.gd › `_process()` (bloque del ataque orbital) y constantes `ORBITAL_*`

## Archivos que toca
- scripts/level/Powers.gd
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar cualquier sector y lanzar varias oleadas.
2. Pulsar R y hacer clic en una fila por la que pasen naves.
3. Las naves normales que toca el rayo mueren; las grandes pierden la mayor parte de la vida.
