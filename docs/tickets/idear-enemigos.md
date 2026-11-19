# Idear enemigos nuevos y mejoras de los que hay

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Queremos más variedad de enemigos con mecánicas que aporten algo, y saber qué nichos están flojos (por ejemplo, muchos tanques y pocos rápidos) antes de seguir añadiendo naves.

## Qué hay que hacer
Es un ticket de diseño: no se toca código, escenas ni recursos.
- Repasar los enemigos que hay (`resources/enemy_data/`, la tabla y las mecánicas de docs/design/enemigos.md) y los tickets de naves que ya existen (`docs/tickets/nave-*.md` y `jefe-*.md`), para no repetirlos.
- Analizar la variedad: qué nichos tienen muchas naves y cuáles pocas o ninguna (tanques, rápidas, enjambres, soporte, evasión, contra ciertas torretas...), en qué niveles salen y qué combinaciones de stats (vida, velocidad, botín, daño a la estación, tamaño) faltan y podrían ser interesantes. Tener en cuenta las torretas (docs/design/torretas.md) para que cada propuesta pida usar torretas distintas.
- Proponer enemigos nuevos con mecánicas que aporten y mejoras a enemigos que ya existen (stats, habilidad, papel en las oleadas).
- Escribir cada propuesta como ticket en `docs/tickets/` con el formato de `docs/tickets/_plantilla.md` y `Estado: propuesta` (`Creador` y `Responsable`: David), con su "Por qué" diciendo qué nicho cubre. Los enemigos nuevos con nombre `nave-<nombre>.md`, como los que ya hay.
- En la respuesta final, el análisis de nichos en pocas líneas y una línea por ticket nuevo.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md (entero)
- docs/design/torretas.md › tabla y papel de cada torreta
- docs/design/niveles.md › oleadas (qué enemigos salen en cada nivel)
- resources/enemy_data/*.tres
- docs/tickets/nave-*.md y docs/tickets/jefe-*.md (solo título y "Por qué")

## Archivos que toca
- docs/tickets/ (tickets nuevos en `Estado: propuesta`)

## Cómo se prueba a mano
1. Leer el análisis de nichos de la respuesta final.
2. Revisar los tickets nuevos en `docs/tickets/`: cada uno cubre un hueco y no repite un ticket que ya existía.
3. Aceptar los que gusten con `/board` o `/accept`.
