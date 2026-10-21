# Fondo vivo en los niveles: cometas y satélites

Estado: aceptada
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
El fondo del menú tiene cometas y satélites que lo hacen vivo; el de los niveles es estático.

## Qué hay que hacer
- Añadir a `scenes/Level.tscn` (no a `scenes/maps/`, que no se toca) instancias de los nodos que usan `scripts/main_menu/Comets.gd` y `Satellites.gd`, detrás del mapa.
- Si los scripts tienen el área o la frecuencia fijas, exportarlas para que en los niveles salgan menos a menudo (para que no distraigan).
- No tocar `scenes/maps/`.

## Archivos que toca
- scenes/Level.tscn
- scripts/main_menu/Comets.gd, scripts/main_menu/Satellites.gd (exports si hace falta)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y entrar en cualquier nivel.
2. Esperar unos segundos: detrás del mapa cruza de vez en cuando un cometa o un satélite, sin tapar a las naves.
