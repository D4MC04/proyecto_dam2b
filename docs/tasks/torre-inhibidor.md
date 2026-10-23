# Torre nueva: Pulso inhibidor

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Las naves de los niveles 6 a 9 tienen habilidades (la Reparadora cura, el Espectro se camufla, la Saboteadora apaga torres con su EMP) y ninguna torre las contrarresta. El Pulso inhibidor las anula en su radio.

## Qué hay que hacer
- No gira. Cada `attack_cooldown` s lanza una onda propia (no reutilizar la de la Cryo): un anillo morado en píxeles que crece hasta el alcance. Hace un poco de daño a todas las naves del radio y las deja **inhibidas** durante `suppress_time` s.
- Estado en `Enemy`: `suppress(seconds)` y `suppressed`. Mientras dura:
  - Espectro: se hace visible al momento y no vuelve a camuflarse. Mientras está camuflado las torres no lo ven, así que el pulso le afecta igual: mira a todos los del grupo `enemies` que haya en el radio.
  - Reparadora: no cura (`_heal_nearby` no hace nada).
  - Saboteadora: si estaba cargando el EMP, la carga se cancela, y no empieza otra.
  - Otro pulso renueva la duración, no se acumula. Se ve un icono pequeño de "inhibida" en píxeles sobre la nave, o un tinte morado.
- Dejar escrito en enemigos.md que toda nave nueva con habilidad tiene que mirar `suppressed` (hay tickets propuestos de Escudera, Fásica, Regeneradora...).
- Recurso de ataque nuevo `SuppressData` (`damage`, `suppress_time`, frames de la onda); `get_attack_label()` "INHIBE"; stats: DAÑO, INHIBE (duración).
- Valores de partida (ajustables): coste 325, alcance 72 px, cada 4 s, 4 de daño, inhibe 3 s.
- Mejora (`fusion`): **Inhibidor de campo**, coste 650, alcance 96, cada 3 s, 8 de daño, inhibe 4,5 s.
- Sprites con un script nuevo en `scripts/tools/` (p. ej. `make_suppressor.gd`) siguiendo art.md: `assets/sprites/towers/suppressor/` (base y antena o emisor con animación de carga `fire_0` y su `fire_frame`, en morado) y `suppressor_fusion/`.
- Recursos: `resources/turret_data/suppressor.tres` y `suppressor_fusion.tres`, sus `SuppressData`, `SpriteFrames` y `description`.
- Sonido: probar con `Turrets/Tesla/CharginTower.wav` o `ElectricZap.wav`; si no queda bien, dejarlo vacío y decírselo al usuario.
- Añadirlo a `GameData.tscn`, a `TOWER_FILES` de `Navedex.gd` y a las `LevelData` desde el **nivel 7**, que es donde sale el Espectro (también en el 8 y el 9).

## Archivos que toca
- scripts/resources/SuppressData.gd, scripts/entities/SuppressPulse.gd, scripts/entities/Tower.gd, scripts/entities/Enemy.gd, scripts/entities/EmpWave.gd (o EmpCharge.gd), scripts/resources/TowerData.gd
- scripts/tools/make_suppressor.gd, assets/sprites/towers/suppressor/, assets/sprites/towers/suppressor_fusion/
- resources/turret_data/, resources/sprite_frames/
- scenes/GameData.tscn, resources/level_data/level_7..9.tres, scripts/screens/Navedex.gd
- docs/design/torres.md, docs/design/enemigos.md, docs/design/niveles.md, docs/design/art.md

## Cómo se prueba a mano
1. Jugar el nivel 7: en la tienda sale el Pulso inhibidor.
2. Colocarlo junto al camino: cada pocos segundos suelta un anillo morado. Un Espectro camuflado que lo cruce vuelve a verse y no desaparece hasta que se le pasa el efecto.
3. En el nivel 8, una Saboteadora dentro del radio no llega a soltar su EMP mientras está inhibida.
4. Con una Reparadora inhibida, las naves de alrededor no se curan (no sale su anillo verde).
5. Pulsar "Mejorar": pasa a Inhibidor de campo, con más radio y pulsos más seguidos.
