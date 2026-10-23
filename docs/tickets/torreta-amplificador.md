# Torreta nueva: Amplificador

Creador: David
Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Todas las torretas atacan; no hay ninguna de apoyo. El Amplificador no dispara: mejora a las torretas que tiene alrededor, y eso hace pensar dónde poner cada una.

## Qué hay que hacer
- Torreta sin ataque: su `TurretData` no tiene `bullet_data`, `pulse`, `chain`, `beam` ni `focus_beam`. `Turret` tiene que funcionar así: no apunta, no arranca el temporizador, no tiene sonido de disparo y el EMP la apaga igual (con la torreta apagada, el aura se corta).
- Aura: las torretas de las 8 casillas vecinas (por `Grid`, no por distancia) tienen más daño y más cadencia. Dos Amplificadores no se suman: cuenta el mejor. Se vuelve a calcular al colocar, vender o mejorar cualquier torreta y cuando un Amplificador se apaga o vuelve.
- En `Turret`: `damage_multiplier` y `rate_multiplier` (1,0 por defecto). Los usan todos los ataques: bala (y su área), onda, cadena, haz, haz continuo (dps) y los que añadan otros tickets (llama y quemadura, inhibidor). La cadencia divide el cooldown, también los valores del sobrecalentamiento. El daño amplificado cuenta en `damage_dealt` de la torreta que dispara.
- Visual: el Amplificador pinta en píxeles un borde suave alrededor de sus 8 casillas, que palpita despacio, y las torretas amplificadas llevan una marca pequeña (p. ej. un chevrón ámbar). En la ficha de una torreta amplificada sale una fila más, AMPLIF. `+20%`.
- Su ficha: `get_attack_label()` "APOYO"; stats: DAÑO `+20%`, CADENCIA `+15%`, y sin ALCANCE ni CADENCIA en segundos (el `get_stats()` común no puede romperse cuando no hay ataque).
- Valores de partida (ajustables): coste 400, +20 % de daño y +15 % de cadencia.
- Mejora (`fusion`): **Amplificador mayor**, coste 800, +35 % de daño y +25 % de cadencia.
- Sprites con un script nuevo en `scripts/tools/` (p. ej. `make_amplifier.gd`) siguiendo art.md: `assets/sprites/turrets/amplifier/` (base y un núcleo o antena que brilla, en ámbar, sin cañón que gire) y `amplifier_fusion/`.
- Recursos: `resources/turret_data/amplifier.tres` y `amplifier_fusion.tres`, `SpriteFrames` y `description`.
- Sin sonido de disparo; si hace falta uno al colocarlo, avisar al usuario de que no hay asset.
- Añadirlo a `GameData.tscn`, a `TURRET_FILES` de `Navedex.gd` y a las `LevelData` desde el **nivel 8** (también en el 9).

## Archivos que toca
- scripts/entities/Turret.gd, scripts/entities/Bullet.gd, Pulse.gd, Chain.gd, Beam.gd, FocusBeam.gd (y Flame.gd si ya existe), scripts/resources/TurretData.gd
- scripts/level/BuildManager.gd, scripts/level/Grid.gd, scripts/level/LevelState.gd
- scripts/tools/make_amplifier.gd, assets/sprites/turrets/amplifier/, assets/sprites/turrets/amplifier_fusion/
- resources/turret_data/, resources/sprite_frames/
- scenes/GameData.tscn, resources/level_data/level_8.tres, level_9.tres, scripts/screens/Navedex.gd
- docs/design/torretas.md, docs/design/ui.md, docs/design/niveles.md, docs/design/art.md

## Cómo se prueba a mano
1. Jugar el nivel 8: en la tienda sale el Amplificador.
2. Colocarlo junto a otras torretas: se ve el borde de su aura en las 8 casillas y las torretas de dentro llevan la marca.
3. Hacer clic en una torreta amplificada: la ficha enseña AMPLIF. +20 %, y dispara más rápido que una igual fuera del aura.
4. Vender el Amplificador: las torretas pierden la marca. Con dos Amplificadores al lado de una torreta, la mejora no se suma.
5. Pulsar "Mejorar" en el Amplificador: pasa a Amplificador mayor y la ficha de las vecinas sube a +35 %.
