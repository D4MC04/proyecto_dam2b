# Ataque orbital más vistoso

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El rayo del ataque orbital se ve muy simple: un zigzag cian dibujado con líneas. Ni el efecto ni el icono del botón llaman la atención.

## Qué hay que hacer
- **Rehacer el rayo entero**, no retocar el actual: ahora es un zigzag fino de líneas con un punto blanco abajo y se ve pobre.
- **Carga:** antes de caer, un destello o retícula en lo alto de la fila elegida (como un satélite apuntando), durante `ORBITAL_FALL_TIME`.
- **Rayo:** más grueso y con capas (halo, cuerpo y núcleo blanco que vibra), con chispas y ramas que saltan a los lados mientras barre la fila.
- **Suelo:** donde toca el rayo, un brillo y una estela quemada que se queda detrás un momento y se apaga.
- **Final:** un destello al terminar el barrido.
- **Icono del botón:** rehacer `power_orbital.png` (16x16) con más detalle y en el estilo de los iconos de interfaz.
- Pixel art sin antialiasing, como el resto (ver docs/design/art.md). No cambiar daño, tamaño del área, duración ni recarga.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Poderes" (tabla y "Ataque orbital")
- docs/design/art.md › paletas y "Iconos de interfaz"
- scripts/level/Powers.gd › `_fire_orbital()`, `_beam_position()`, `_draw_bolt()`, constantes `ORBITAL_*`

## Archivos que toca
- scripts/level/Powers.gd
- assets/ui/power_orbital.png
- assets/sprites/effects/ (si hacen falta sprites) y scripts/tools/ (su generador)
- docs/design/niveles.md, docs/design/art.md

## Cómo se prueba a mano
1. Jugar el nivel 1 y lanzar una oleada.
2. Pulsar R (o el botón del ataque orbital) y hacer clic en una fila con naves.
3. Debería verse la carga arriba, el rayo grueso con chispas cayendo y barriendo la fila, la estela quemada detrás y el destello final. Las naves de la fila reciben el mismo daño que antes.
4. El icono del botón se ve más detallado.
