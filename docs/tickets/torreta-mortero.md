# Torreta de área en anillo (tipo mortero)

Creador: David
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Una torreta que solo alcanza a los enemigos en un anillo a cierta distancia (rango mínimo y máximo) obliga a pensar dónde colocarla. Funciona como un mortero, pero en el espacio no hay gravedad: el tema tiene que hacer intuitivo por qué no puede tocar lo que tiene cerca.

## Qué hay que hacer
Por fases, parando a preguntar al usuario entre una y otra (AskUserQuestion). No implementar en el juego hasta que el usuario elija prototipo.
1. **Ideas**: pensar qué es temáticamente (no un mortero literal ni nada que dependa de la gravedad) de forma que se entienda solo con verla que su área es un anillo lejos de ella y que cerca no llega. Proponer 3-4 ideas al usuario con aspecto, cómo dispara, cómo se ve el impacto y cómo se muestra el anillo de alcance. Esperar a que elija.
2. **Prototipos**: con la idea elegida, dibujar 2-3 variantes de sprite (base + cañón/emisor, 16x16) respetando estrictamente el estilo de las torretas existentes: misma paleta, contorno, luz y proporciones (ver `assets/sprites/turrets/` y docs/design/art.md). Cada variante con su animación de disparo e impacto.
3. **Verlo en un nivel**: que el usuario pueda ver cada prototipo colocado dentro de un nivel real en Godot, disparando a enemigos en el anillo (provisional en la barra de compra de un nivel o una escena de prueba). Abrir el editor y decirle cómo verlo. Esperar a que elija.
4. **Implementar** la elegida:
   - Rango en anillo: radio mínimo y máximo en `TurretData`. Solo elige objetivos entre ambos (`Turret._get_target`, `enemies_in_range`).
   - Ataque de área (nuevo tipo o `BulletData` con `splash_radius`, lo que encaje con la idea) con su proyectil e impacto.
   - El rango se dibuja como anillo en la vista previa de `BuildManager`, al pasar el ratón, seleccionada y con la opción de mostrar alcances, con el estilo de `BuildManager.draw_range_circle`.
   - Ficha: ALCANCE como mínimo-máximo y las filas de su ataque (`get_stats`, `get_attack_label`).
   - Su efecto de Amplificador (`amp_effect`, ver docs/design/torretas.md › "Amplificador").
   - Fusión si el usuario la quiere. Añadirla a los niveles que diga el usuario. Quitar los prototipos descartados y lo provisional.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/art.md › "Tamaños", "Paleta", "Contorno", "Luz y sombreado", "Animación", "Convención de nombres"
- docs/design/torretas.md › "Escena y script", "Objetivo", "Disparo", "Datos", "Amplificador", "Tipos de ataque"
- docs/design/niveles.md › "Datos de nivel"
- scripts/entities/Turret.gd › `_get_target()`, `_draw()`, `_shoot()`
- scripts/level/BuildManager.gd › `draw_range_circle()`
- scripts/resources/TurretData.gd › `get_stats()`, `get_attack_label()`
- scripts/entities/Bullet.gd (área de explosión)

## Archivos que toca
- assets/sprites/turrets/<nueva>/
- resources/turret_data/<nueva>.tres (y fusión), resources/amp_effects/, resources/sprite_frames/, resources/collision_shapes/
- scripts/entities/Turret.gd, scripts/resources/TurretData.gd, scripts/level/BuildManager.gd
- scripts/entities/ y scripts/resources/ (proyectil o tipo de ataque nuevo, si hace falta)
- resources/level_data/ (niveles donde se desbloquea)
- docs/design/torretas.md, docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar un nivel donde esté desbloqueada y colocarla junto a un camino.
2. La vista previa y el rango al pasar el ratón se ven como un anillo.
3. No dispara a enemigos pegados a ella; sí a los que pasan por el anillo, con daño en área al impactar.
4. Con un Amplificador cerca, la ficha enseña lo que gana.
