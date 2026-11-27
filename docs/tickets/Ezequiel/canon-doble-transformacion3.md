# Cañón doble nivel 3: animación de mejora del Cañón cuádruple a la Lanza dorada

Creador: Ezequiel
Responsable: 
Estado: aceptada
Espera a: canon-doble-nivel3
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Al mejorar el Cañón cuádruple al nivel 3 ahora sale el holograma genérico. Con una transformación propia se ve cómo cada pieza del nivel 2 se convierte en una de la Lanza dorada, igual que pasa con el Cañón de asedio.

## Qué hay que hacer
Va después de `canon-doble-nivel3`, porque necesita sus sprites. Referencia del resultado final: `C:\Users\Jotaro\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\side-session-notes\local_6f9fb21a-cefb-448f-845f-57a32a5f0967\cuadruple3\cuadruple3v2_A.gif`.

- Generar la hoja con un script en `scripts/tools/` (por ejemplo, `make_quad_lance_transform.gd`), como hace `make_siege_transform.gd`:
  - Frames de 64x64 con la torreta en el centro, a 25 fps, unos 2,2 s y sin bucle.
  - Primer frame igual que el Cañón cuádruple en reposo; último frame igual que la Lanza dorada en reposo, con el cañón hacia arriba.
  - Sale en `assets/sprites/turrets/turret_level3/t1_transform_sheet.png` y `resources/sprite_frames/turret_level3_transform.tres`.
  - Ponerla como `upgrade_frames` en `resources/turret_data/turret_level3.tres`.
- Pasos. Cada pieza del nivel 2 se mueve y se convierte en una del nivel 3; nada aparece de la nada ni se disuelve, y la base no se mueve de su sitio:
  1. Las luces verdes de la base (aro discontinuo) pasan a oro una a una, en círculo.
  2. Las cuatro placas de blindaje entran en diagonal desde fuera hasta las esquinas y encajan con un "clac" de 1 px y chispas oro.
  3. En cada cápsula, el cañón de fuera (el corto) se desliza hacia dentro y se mete en el de dentro. Ese se estira hasta la fila 0 y se convierte en la lanza, y el freno de boca verde se abre en el freno oro ranurado, con chispas.
  4. Las chapas de fuera de las cápsulas se doblan hacia delante hasta quedar como cuchillas en diagonal, con vapor en las bisagras.
  5. El cuerpo central estrecho sube hasta formar la cuña en punta, y la lente verde se alarga hasta ser la franja oro.
  6. El bloque de atrás se abre en los dos cargadores. Se abren las ventanas de las cápsulas, entra el primer dardo y la abrazadera cierra con "clac" y una bocanada de vapor a cada lado.
- Pequeños golpes de 1 px, chispas y vapor en los encajes. Nada de explosiones.
- `docs/design/torretas.md` › "Animación de mejora": añadir la Lanza dorada (hoja, frames, duración y pasos). En `docs/design/art.md`, el script que la genera.

## Qué leer
- docs/design/torretas.md › párrafo de `play_upgrade()` / `upgrade_frames` (animación de mejora del Cañón de asedio)
- scripts/tools/make_siege_transform.gd (estructura, tiempos y cómo escribe la hoja y el `.tres`)
- scripts/entities/Turret.gd › `play_upgrade()`
- assets/sprites/turrets/turret_fusion/ (nivel 2) y turret_level3/ (nivel 3)

## Archivos que toca
- scripts/tools/make_quad_lance_transform.gd (nuevo)
- assets/sprites/turrets/turret_level3/t1_transform_sheet.png (nuevo)
- resources/sprite_frames/turret_level3_transform.tres (nuevo)
- resources/turret_data/turret_level3.tres
- docs/design/torretas.md, docs/design/art.md

## Cómo se prueba a mano
1. Jugar un nivel con dinero suficiente, colocar un Cañón doble y mejorarlo a Cañón cuádruple.
2. Mejorarlo otra vez: en lugar del holograma, durante unos 2,2 s se ven los pasos en orden (luces a oro, placas en las esquinas, cañones que se juntan en lanzas, cuchillas, cuña, cargadores y el primer dardo).
3. Mientras dura no dispara. Al acabar queda la Lanza dorada en reposo, sin ningún salto, y empieza a disparar.
