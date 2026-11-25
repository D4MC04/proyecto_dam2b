# Mejora: la Saboteadora pasa a ser la Payload, una bomba que explota al morir

Estado: aceptada
Espera a: mejora-mender
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Ahora la Saboteadora suelta un pulso EMP cada 5 s y solo queda matarla rápido. Si el EMP sale al morir, importa dónde la matas: dentro de un grupo de naves las daña, pero cerca de tus torretas te las apaga.

## Qué hay que hacer
- **Rediseño visual del sprite:** que se vea a simple vista su mecánica (es una bomba que explota al morir) y que encaje con las naves ya bien establecidas: las naves base de `make_base_ships.gd` (Streak, Vanguard, Cruiser...), con su mismo estilo y nivel de pulido. Los diseños antiguos de la Reparadora, la Divisora y la Saboteadora no sirven de referencia. Nada descabellado: igual que la Streak parece rápida sin nada especial, esta tiene que dar el aire de su mecánica. Generarlo con un script en `scripts/tools/` (no a mano) y enseñar el boceto ampliado al usuario antes de integrarlo.
- Quitar el pulso periódico (`emp_interval`). Al morir (no al llegar a la estación) explota: el anillo EMP de ahora (`emp_radius` 96 px, `emp_disable_time` 3 s) y 50 de daño a las naves que estén dentro del radio (campo nuevo, p. ej. `death_damage`).
- Mientras avanza, late cada vez más rápido según `progress_ratio` (reutilizar la carga de `EmpCharge`, sin tirones de velocidad), para que se vea que es una bomba a punto de reventar.
- (Con el criterio del rediseño visual de arriba) Rediseñar el sprite como bomba (pixel art según docs/design/art.md, con su script en `scripts/tools/`; manteniendo el núcleo azul eléctrico del EMP).
- Stats y botín de docs/design/naves-plan.md (100 de vida, 45 px/s, 25 de daño a la estación, botín 25), nombre Payload y `description`.
- Al terminar: pasarla a docs/design/enemigos.md y quitarla de naves-plan.md.

## Qué leer
- docs/design/art.md › la línea de las **Naves base** (estilo de referencia) y la de esta nave
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › Payload
- docs/design/enemigos.md › "Habilidades" y "Daño y muerte"
- docs/design/art.md (sección de sprites de enemigos)
- scripts/entities/EmpWave.gd y scripts/entities/EmpCharge.gd
- scripts/entities/Enemy.gd › `die()`

## Archivos que toca
- assets/sprites/enemies/saboteadora/ y su script de `scripts/tools/`
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd, EmpWave.gd y EmpCharge.gd
- resources/enemy_data/saboteadora.tres
- translations/textos.csv
- docs/design/enemigos.md y docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 8.
2. La Payload late más rápido según se acerca a la estación y ya no suelta pulsos mientras vive.
3. Al matarla junto a tus torretas, sale el anillo EMP y se apagan 3 s; si muere en medio de otras naves, a ellas les baja la vida.
