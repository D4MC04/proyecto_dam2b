# La skill /mejora también diseña el nivel 3

Creador: Ezequiel
Responsable: Ezequiel
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
El nivel 3 de cada torreta se diseña torreta a torreta, con mecánica nueva y aspecto nuevo, igual que se hizo el nivel 2 con `/mejora`. Hoy la skill solo sirve para el nivel 2.

## Qué hay que hacer
- Que `/mejora` acepte el nivel a diseñar: `/mejora <torreta>` sigue siendo el nivel 2; `/mejora <torreta> nivel 3` diseña el nivel 3. Actualizar `description` y `argument-hint` (añadir los nombres de las torretas y "nivel 3").
- Reglas para el nivel 3 (además de las del nivel 2):
  - El nivel 1 y el nivel 2 no cambian; la referencia es el nivel 2.
  - Siempre con mecánicas: se mantiene el tipo de ataque y se añade **otra** mecánica que se vea y se sienta, distinta de la que ganó en el nivel 2. Silueta nueva, todavía más brusca que el nivel 2.
  - Números a la altura del coste: 2 × el del nivel 2 (ver docs/design/torretas.md › "Mejorar (fusión)").
  - Animación de transformación del nivel 2 al 3 (`upgrade_frames` en `<x>_level3.tres`), con las mismas reglas de coherencia: cada pieza del nivel 2 se convierte en una del nivel 3.
  - Datos en `resources/turret_data/<x>_level3.tres` y sprites en `assets/sprites/turrets/<x>_level3/`.
- En el nivel 3 la pregunta inicial solo pregunta cuántos diseños (por defecto 3); no pregunta el tipo, porque siempre son con mecánicas.
- Paso a tickets en el nivel 3: `<torreta>-nivel3` (Opus, esfuerzo high) y `<torreta>-transformacion3` (Opus, medium, va después del primero).
- Requiere que esté hecho `nivel3-sistema` (los `<x>_level3.tres` provisionales).

## Qué leer
- .claude/skills/mejora/SKILL.md (entero, es corto)
- docs/design/torretas.md › "Mejorar (fusión)"

## Archivos que toca
- .claude/skills/mejora/SKILL.md

## Cómo se prueba a mano
1. En un chat nuevo en main, escribir `/mejora cañón doble nivel 3`.
2. Debería preguntar solo cuántos diseños y luego proponer diseños con mecánicas que parten del Cañón cuádruple, con su coste (400€) y sin tocar archivos del proyecto.
3. `/mejora minigun` sigue funcionando como antes (nivel 2).
