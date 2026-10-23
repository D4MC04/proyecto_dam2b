# Archivo: tamaño fijo, celdas cuadradas y mejoras con flechas

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El panel del Archivo cambia de tamaño al elegir otra entidad o pestaña, las celdas no son cuadradas y cada mejora de torreta ocupa su propia celda.

## Qué hay que hacer
- Tamaño fijo: que el panel de `scenes/Navedex.tscn` no cambie de tamaño al pulsar celdas ni pestañas (NAVES, TORRETAS, LOGROS). Dar al detalle (descripción y stats) y a la zona de la cuadrícula un tamaño fijo en el que quepa la entidad con más texto y stats.
- Celdas cuadradas: las celdas `EnemyCell` de la cuadrícula del Archivo, igual de altas que de anchas. Solo en el Archivo (`EnemyCell` también se usa en la partida).
- Torretas: en `TURRET_FILES` de `scripts/screens/Navedex.gd` dejar solo las torretas base. En el detalle, flechas a los lados de la imagen de la torreta para pasar de la base a sus versiones mejoradas (`TurretData.fusion`) y volver; al cambiar se actualizan imagen, nombre, descripción y stats. Sin flechas (o desactivadas) en las naves y cuando no haya más versiones.

## Archivos que toca
- scenes/Navedex.tscn
- scripts/screens/Navedex.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. Lanzar el juego y abrir Archivo.
2. Pulsar varias naves y cambiar entre las tres pestañas: el panel no debería moverse ni cambiar de tamaño.
3. Las celdas de la cuadrícula se ven cuadradas.
4. En Torretas solo salen las base; al pulsar la flecha junto a la imagen se ve su mejora (imagen, nombre y stats nuevos) y la otra flecha vuelve a la base.
