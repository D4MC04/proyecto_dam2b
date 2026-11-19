# Nave nueva: Coraza

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Todas las naves reciben el daño entero, así que contra cualquiera da igual pegar muchos golpes pequeños (Cañón doble 5, Minigun 8) o pocos grandes. Un blindaje plano por golpe premia los golpes gordos (Cañón pesado, Tesla, Orbitador, Rail). Es distinta de la Blindada frontal (`nave-blindada`), que depende del ángulo: esta resta lo mismo venga de donde venga.

## Qué hay que hacer
- `EnemyData`: campo `armor` (0 por defecto). `take_damage()` resta `armor` a cada golpe, mínimo 1. Al haz continuo del Disintegrator se le resta `armor` por segundo, no por frame.
- Coraza: unos 160 de vida, 35 px/s, `armor` 4, 15 de daño a la estación, radio 13; botín ≈ 80 € (factor ×1,3).
- Los golpes que pierden más de la mitad del daño sacan una chispa gris en vez del destello blanco. La ficha enseña una fila BLINDAJE.
- Sprite con `scripts/tools/make_coraza.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`) y `description` para la ficha.
- Añadirla a `LEVELS` de `scripts/tools/make_waves.gd`: nueva en el nivel 4 (junto al Acorazado, cuando llega el Cañón pesado) y en las antiguas de los siguientes. Regenerar y comprobar que sale en la Navedex.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md › "Datos", "Daño y muerte", "Efectos visuales"
- docs/design/niveles.md › "Generador de oleadas"
- docs/design/art.md (sección de sprites de enemigos)
- scripts/entities/Enemy.gd › `take_damage()`
- scripts/entities/FocusBeam.gd › donde aplica el daño

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd y scripts/entities/FocusBeam.gd
- resources/enemy_data/coraza.tres
- assets/sprites/enemies/coraza/ y scripts/tools/make_coraza.gd
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- docs/design/enemigos.md y docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 4.
2. Los Cañones dobles le hacen 1 por golpe y salen chispas grises; el Cañón pesado le quita casi todo su daño.
3. La ficha de la Coraza en la pestaña Oleadas enseña BLINDAJE 4.
