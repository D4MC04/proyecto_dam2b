# Rail Gauss nuevo: riel doble blindado con condensadores y canal que se enfría

Creador: Ezequiel
Responsable: Ezequiel
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Ahora la Rail Gauss es el Rail recoloreado de ámbar a cian: misma silueta. Tiene que verse a simple vista como un nivel 2, más blindada y brusca, y su carga y recarga tienen que verse en el sprite. Es un cambio solo estético: el ataque y los números no cambian.

## Qué hay que hacer
- El Rail (nivel 1) no cambia.
- Aspecto nuevo de la Rail Gauss en `assets/sprites/turrets/rail_fusion/` (32x32, art.md), generado con un script en `scripts/tools/` (`make_rail_gauss.gd`, como `make_siege_cannon.gd`), que también escribe `resources/sprite_frames/rail_fusion_cannon.tres`:
  - Cañón **riel doble blindado**: dos rieles gruesos con placas de blindaje a los lados y un canal ancho entre ellos. Detrás, dos condensadores con un medidor de 4 celdas cada uno. Es la plantilla `TWIN_RAIL` de la referencia (la mitad izquierda, reflejada): `g`/`h` son el canal, `p`-`s` las celdas.
  - Base: la de la Rail Gauss actual **sin los dos cuadrados de las esquinas delanteras** (filas 3-6, columnas 3-6 y 25-28), con el borde del octógono cerrado como en la base del Cañón doble.
  - Icono `rail_full_up.png` acorde (base + cañón en reposo).
- Carga y recarga a la vista (animación `fire_0` del cañón, sincronizada con `fire_frame` 8 y la carga de 1,6 s):
  - Carga (1,6 s): sale la mira de siempre; el canal pasa de apagado a dorado en 5 pasos y las celdas de los condensadores se encienden una a una (1 → 4).
  - Disparo (`fire_frame`): el canal queda blanco-dorado, los condensadores se vacían de golpe (celdas apagadas) y el cañón retrocede 1 px durante 0,3 s.
  - Enfriado: el canal pasa a naranja (0,5 s), luego a marrón (0,5 s) y vuelve al reposo. En reposo las celdas apagadas parpadean en cian, una tras otra.
- Haz: el mismo de ahora (texturas `rail_beam_0..3`, dorado 32x15, impacto `rail_fusion_impact`). Sin bala ni marca.
- Números sin cambios: 800 de daño a toda la línea, 900 px de largo, `half_width` 16, recarga 4,5 s, giro 45°/s, coste y alcance actuales, mismo `amp_effect`. (La nota y el GIF de referencia dicen 900 de daño: no hacer caso, se queda en 800.)
- Referencia visual (carpeta de notas de la sesión que lo diseñó, si sigue existiendo): `C:\Users\Jotaro\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\side-session-notes\local_6f9fb21a-cefb-448f-845f-57a32a5f0967\`
  - `rail_gauss_E2.gif`: ciclo completo de carga, disparo y enfriado.
  - `rail_gauss_base_sin_cuadrados.png`: la base nueva.
  - `rail_gauss_rail2.py` (`TWIN_RAIL`, `METAL`, `CYAN`, `GOLD`) y `rail_gauss_proto_e2.py` (`turret()`: colores del canal, celdas, calor `HOT`/`WARM` y retroceso). `proto_e2` carga `rail2.py` por ese nombre.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Mejorar (fusión)", "Tipos de ataque" › "Haz"
- docs/design/art.md › "Tamaños", "Paleta", "Contorno", "Luz y sombreado", "Animación", la fila de Rail Gauss y el párrafo del Cañón de asedio (ejemplo de sprites generados por script)
- scripts/tools/make_siege_cannon.gd (cómo se generan sprites y SpriteFrames)
- scripts/entities/Turret.gd › `_shoot()` (cuándo se reproduce `fire_0`)
- resources/sprite_frames/rail_fusion_cannon.tres

## Archivos que toca
- scripts/tools/make_rail_gauss.gd (nuevo)
- assets/sprites/turrets/rail_fusion/ (base, hojas del cañón, icono)
- resources/sprite_frames/rail_fusion.tres, resources/sprite_frames/rail_fusion_cannon.tres
- docs/design/art.md

## Cómo se prueba a mano
1. Jugar un nivel con el Rail desbloqueado, colocarlo y pulsar Mejorar.
2. Se ven dos rieles gruesos blindados con un canal ancho entre ellos y dos condensadores detrás. La base ya no tiene los cuadrados de las esquinas delanteras.
3. Al cargar, el canal se llena de dorado y las celdas se encienden una a una. Al disparar, el haz sale como antes, las celdas se apagan de golpe y el cañón retrocede 1 px.
4. Tras el disparo, el canal pasa de naranja a marrón y vuelve al reposo antes del siguiente disparo (4,5 s).
5. La ficha enseña los mismos números de antes (800, 900 px, 4,5 s).
