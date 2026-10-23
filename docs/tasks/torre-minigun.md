# Torre nueva: Minigun (sustituye al Láser)

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
El sobrecalentamiento (empieza lento, acelera, aguanta a tope, se sobrecalienta y para) se entiende mucho mejor en una minigun que en un láser. La Minigun ocupa el sitio del Láser, que desaparece del juego.

## Qué hay que hacer
- Mecánica: torre de bala que usa el sobrecalentamiento que ya existe (`TowerData.overheat_*`, `HeatGlow`, ver torres.md). Sin código de ataque nuevo. Valores de partida (ajustables al probar): coste 200, alcance 80 px, giro 270 °/s, bala de 4 de daño a 400 px/s, cooldown 0,4 → 0,05 s, 60 disparos de aguante, parada de 3 s y enfriado en 3 s. El halo de calor sale en la boca de los cañones.
- Mejora (campo `fusion`, botón "Mejorar" de la ficha): **Minigun pesada**, coste 400, 6 de daño, alcance 96, 0,3 → 0,04 s, 90 disparos, parada de 2 s.
- Sprites con un script nuevo en `scripts/tools/` (p. ej. `make_minigun.gd`), siguiendo art.md: `assets/sprites/towers/minigun/` (base, cañón de tubos rotativos mirando hacia arriba con `fire_0`/`fire_1`, fogonazo, bala corta tipo trazadora y su impacto) y `minigun_fusion/` con los mismos tamaños, frames y nombres, más detallada y con un acento nuevo.
- Recursos: `resources/turret_data/minigun.tres` y `minigun_fusion.tres`, sus `BulletData` y sus `SpriteFrames`, con `description`.
- Sonido: no hay assets de minigun. Usar `Turrets/Turret/DobleLaserShoot.wav` como provisional y decírselo al usuario.
- Quitar el Láser: sacarlo de `GameData.tscn`, de las `LevelData` (en el nivel 1 la Minigun entra en su sitio), de `TOWER_FILES` en `scripts/screens/Navedex.gd` y del `Outpost` del menú (`scripts/main_menu/Outpost.gd`: usar la Minigun). `Skirmish.gd` precarga `laser_impact.tres`: pasarlo al impacto de la Minigun. Después borrar `turret_data/laser*.tres`, `bullet_data/laser*_bolt.tres`, los `sprite_frames/laser*` y `assets/sprites/towers/laser*/` solo si nada más los usa (comprobarlo con grep).
- Comprobar que ningún logro de `GameState.ACHIEVEMENTS` ni el tutorial nombran al Láser.

## Archivos que toca
- scripts/tools/make_minigun.gd, assets/sprites/towers/minigun/, assets/sprites/towers/minigun_fusion/
- resources/turret_data/, resources/bullet_data/, resources/sprite_frames/
- scenes/GameData.tscn, resources/level_data/
- scripts/screens/Navedex.gd, scripts/main_menu/Outpost.gd, scripts/main_menu/Skirmish.gd
- docs/design/torres.md, docs/design/art.md, docs/design/niveles.md, docs/design/menu.md

## Cómo se prueba a mano
1. Jugar el nivel 1: en la tienda está la Minigun donde estaba el Láser; el Láser ya no sale en ningún nivel ni en el Archivo.
2. Colocar una Minigun: dispara despacio, acelera, a tope brilla y echa chispas, y al rato se sobrecalienta, parpadea en rojo y para. Luego vuelve a empezar despacio.
3. Dejarla sin naves a mitad de calor: se enfría poco a poco.
4. Pulsar "Mejorar" en su ficha: pasa a Minigun pesada.
5. En el menú principal, la estación del fondo lleva una Minigun.
