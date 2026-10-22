# Láser: mecánica propia

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
El Láser (`laser`) es una bala normal más rápida que el Cañón doble (15 de daño, 250 px/s, cadencia 0,5 s) y no tiene nada que lo distinga. Su fusión, el Láser doble, solo añade `pierce` 1.

## Qué hay que hacer
- **Primero decidir la mecánica con el usuario.** Proponerle 3 o 4 opciones que no repitan lo que ya hacen otras torres: área (Cañón pesado), cadena (Tesla), haz en línea (Rail), haz que sube de nivel (Disintegrator) y frenar (Cryo). Explicar cada una en una línea, con lo que costaría implementarla. Algunas ideas para empezar:
  - perforar a todas las naves en línea;
  - barrido en arco (venía del ticket descartado torre-laser-barrido);
  - cadencia que sube mientras dispara y luego se sobrecalienta;
  - rebotes contra el borde del alcance.
- No implementar nada hasta que el usuario elija.
- Implementar la elegida en el Láser y adaptar la fusión (Láser doble) para que sea la misma mecánica, pero mejor. Si hace falta, campos opcionales nuevos en `BulletData` o `TowerData` que, sin configurar, no cambian nada en las demás torres.
- Si la mecánica lo pide, una fila nueva en la ficha (`get_stats`).
- Actualizar docs/design/torres.md (tablas de torres y de fusiones, y el apartado del ataque que toque).

## Archivos que toca
- resources/turret_data/laser.tres, laser_fusion.tres
- resources/bullet_data/laser_bolt.tres, laser_fusion_bolt.tres
- scripts/entities/Bullet.gd y/o scripts/entities/Tower.gd (según la mecánica)
- scripts/resources/BulletData.gd o TowerData.gd (si hacen falta campos)
- docs/design/torres.md

## Cómo se prueba a mano
1. F5, nivel 1; colocar un Láser junto al camino.
2. Se ve y se nota la mecánica elegida (los pasos concretos se escriben al decidirla).
3. Fusionar dos Láseres: el Láser doble hace lo mismo, pero mejor.
4. Las demás torres disparan como antes.
