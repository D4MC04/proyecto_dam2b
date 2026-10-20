# Tipar los scripts del fondo del menú

Estado: aceptada
Modelo recomendado: sonnet

## Por qué
Los scripts de `scripts/main_menu/` (asteroides, cometas, satélites, estrellas) tienen variables y funciones sin tipo, al contrario de lo que pide CLAUDE.md (docs/design/menu.md, "Dudas"). Sin tipos, Godot no avisa de errores hasta que fallan en juego.

## Qué hay que hacer
- Añadir tipos a todas las variables, parámetros y retornos de `Asteroids.gd`, `Comets.gd`, `Satellites.gd`, `SpaceBody.gd` y `Starfield.gd`. Los diccionarios de asteroides pueden seguir siendo `Dictionary` si cambiarlos complica el código.
- Si hay nombres en español, pasarlos al inglés y actualizar sus referencias en los .tscn.
- No cambiar el comportamiento: el fondo tiene que verse igual.
- Quitar la duda de docs/design/menu.md.

## Archivos que toca
- scripts/main_menu/*.gd
- scenes/SpaceBody.tscn, scenes/MainMenu.tscn (solo si se renombra algo)
- docs/design/menu.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` (F5).
2. El fondo se ve igual que antes: estrellas, asteroides con estela, cometas y satélites.
3. En la pestaña Depurador de Godot no salen errores ni avisos nuevos.
