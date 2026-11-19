# Rediseño de las naves base y 3 nuevas (Streak, Vanguard, Cruiser)

Creador: David
Responsable: David
Estado: propuesta
Prioridad: alta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Las naves sin mecánica no siguen un orden claro (la Wasp va más rápida que el Dart, la Nave agresiva es más lenta que la normal, el Ariete y el Acorazado solo se distinguen en los números) y dan demasiado botín. Con 10 naves base ordenadas por nichos y escalones, cada una tiene su papel, y faltan las rápidas en los niveles altos.

## Qué hay que hacer
- Seguir la tabla "Naves base" de docs/design/naves-plan.md: vida, velocidad (1,0 = 60 px/s), daño a la estación y botín de Dart, Wasp, Corsair (Nave normal), Frigate (Nave agresiva), Ram (Ariete), Juggernaut (Acorazado) y Mothership (Nodriza). Los 4 Dart siguen iguales.
- Nombres en inglés en `translations/textos.csv` (columnas `es` y `en`) y descripciones nuevas que digan su papel. No renombrar los archivos `.tres` ni las claves (para no tocar uid ni referencias).
- Naves nuevas Streak, Vanguard y Cruiser: `EnemyData`, sprite con su script en `scripts/tools/` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`), textos y Navedex. Niveles propuestos: Streak en el 2, Cruiser en el 4 y Vanguard en el 8; las tres en las antiguas de los siguientes.
- Botín: aplicar la fórmula de naves-plan.md también a las naves con mecánica que ya hay (Espectro, Saboteadora, Reparadora, Divisora y sus trozos), con los valores de su tabla.
- Bajar los presupuestos de `LEVELS` en `scripts/tools/make_waves.gd` en la misma proporción que el botín, para que salgan más o menos las mismas naves. Revisar la tabla "Dificultad frente a dinero" de niveles.md y ajustar `health` si un nivel queda roto.
- Mothership de miniboss: quitarle la marca de jefe (sin `BossAlert` ni la señal `boss_died`; revisar `Spawner.NODRIZA` y `wave_has_boss`) y meterla como mucho una por oleada en las últimas oleadas de los niveles 8 y 9.
- Regenerar las oleadas.
- Al terminar: pasar estas naves a docs/design/enemigos.md y quitarlas de naves-plan.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › "Reglas" y "Naves base"
- docs/design/enemigos.md › "Datos"
- docs/design/niveles.md › "Generador de oleadas" y "Dificultad frente a dinero"
- docs/design/art.md (sección de sprites de enemigos)
- scripts/level/Spawner.gd › `NODRIZA`, `wave_has_boss()` y `boss_died`

## Archivos que toca
- resources/enemy_data/*.tres
- translations/textos.csv
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- scripts/level/Spawner.gd y scripts/level_ui/ (aviso de jefe)
- assets/sprites/enemies/ y scripts/tools/ (las 3 nuevas)
- docs/design/enemigos.md, docs/design/niveles.md, docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 1: los Dart van más rápidos que las Wasp y dan "+5€".
2. Jugar el nivel 2: sale la Streak, la más rápida de todas.
3. Jugar el nivel 9: la Mothership sale en las últimas oleadas sin aviso de jefe, y la Vanguard pasa rápida y aguanta.
4. En la Navedex salen los nombres en inglés.
