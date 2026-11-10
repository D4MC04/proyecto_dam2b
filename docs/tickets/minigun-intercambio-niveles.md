# La Minigun estrena aspecto casero y la pesada hereda el de ahora

Creador: Jotaro
Responsable:
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
El diseño casero de cinco tubos delgados gustó más como torreta de nivel 1, y el aspecto actual de la Minigun normal pasa a ser el de la mejora (Minigun pesada), para que se note el salto al mejorar.

## Qué hay que hacer
- En `scripts/tools/make_minigun.gd`, intercambiar qué diseño dibuja cada nivel; los dos siguen saliendo del mismo script (`godot --headless --path . -s scripts/tools/make_minigun.gd`).
- **Nivel 1 nuevo (Minigun, acento naranja):** el prototipo "Cinco tubos y lata soldada" (variante 9 de `minigun_props_casera.gd`, ver "Referencias"):
  - Haz de 5 tubos delgados: cilindro de la columna 11 a la 20 (en vez de 9 a 22), hueco entre tubos 0,4, bocas en la fila 1. Filas debajo de las bocas: 4 de tubo, abrazadera de acento (2 filas), 3 de tubo, 1 de metal, 1 de tubo. Mismo giro que ahora (4 frames, un cuarto de tubo por frame).
  - Carcasa de chapas remachadas encima de la carcasa normal: juntas oscuras en x 12 (filas 14-17), x 19 (filas 19-24) y la fila 18; remaches claros con sombra abajo a la derecha en x 9, 15, 21 de las filas 15 y 21; dos manchas de óxido `#7c5842` en (10, 22) y (20, 16).
  - Asa corta sobre la parte de atrás de la carcasa (fila 20): barra de x 10 a 21 con luz arriba, dos postes atornillados en x 9 y 21 y tres tiras de cinta en la empuñadura.
  - Lata de munición soldada a la derecha (x 25-30, filas 12-23) con tapa, cierre, franja de acento pintada (filas 18-19) y una cinta de balas de latón (naranja de la Minigun) en x 24 que avanza 1 fila por frame de giro.
- **Nivel 2 nuevo (Minigun pesada, acento rojo):** el diseño que hoy tiene la Minigun normal (carcasa `HOUSING`, `TUBE_ROWS`, haz de 6 tubos de x 9 a 22), con el rojo de la pesada.
- Cada nivel conserva su base: la normal sin aro y la pesada con su aro discontinuo rojo y luces grandes en las esquinas.
- El fogonazo, la bala y el impacto no cambian. La boca sigue en `muzzle_offset` (0, -13).
- Regenerar los sprites sin tocar nombres, tamaños, número de frames ni `uid` de los `.import` y `.tres`.
- Actualizar docs/design/art.md: la entrada "Minigun y Minigun pesada" y la fila de la Minigun pesada en la tabla de fusionadas.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/art.md › "Paleta" (entrada "Minigun y Minigun pesada" y tabla de fusionadas), "Contorno", "Luz y sombreado"
- scripts/tools/make_minigun.gd › `_make_cannon()`, `_draw_tube_row()`, `HOUSING`, `HEAVY_HOUSING`, `TUBE_ROWS`, `HEAVY_TUBE_ROWS`, `_draw_heavy_base()`

## Referencias
En la carpeta de notas de la sesión que lo diseñó (C:\Users\Jotaro\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\side-session-notes\local_6f9fb21a-cefb-448f-845f-57a32a5f0967\):
- `minigun_props_casera.gd`: script de prototipo que extiende `make_minigun.gd`; `_thin(core, frame, 11, 20, 5, true)` es el nivel 1 nuevo (funciones `_thin`, `_thin_row`, `_plates`, `_handle`).
- `propuestas_minigun_delgada.png` (fila 2) y `minigun_t9.gif`: cómo se ve y disparando.
- `minigun-intercambio.md`: resumen del pedido.

## Archivos que toca
- scripts/tools/make_minigun.gd
- assets/sprites/turrets/minigun/ (PNG generados)
- assets/sprites/turrets/minigun_fusion/ (PNG generados)
- docs/design/art.md

## Cómo se prueba a mano
1. Jugar un nivel con la Minigun desbloqueada y colocar una.
2. Debería verse con cinco tubos finos, chapas remachadas, asa atrás y la lata soldada a la derecha, en naranja; al disparar giran los tubos y avanza la cinta de balas.
3. Pulsar Mejorar en su ficha: la pesada se ve como la Minigun de antes, en rojo y con el aro de la base. Las dos disparan, giran y se sobrecalientan igual que antes.
