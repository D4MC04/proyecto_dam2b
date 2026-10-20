# Quitar el sonido de muerte de las naves

Estado: aceptada
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Al usuario no le gusta: cuando muere una nave suena muy fuerte y tapa el resto. De momento solo deben sonar las torres.

## Qué hay que hacer
- En los 12 `resources/enemy_data/*.tres`, quitar la línea `death_sound = ExtResource("death_sound")` y su `[ext_resource ... id="death_sound"]`. No tocar ningún otro uid ni id.
- No tocar `Enemy.gd` ni `EnemyData.gd`: sin `death_sound`, `_play_death_sound()` ya no hace nada (y así no choca con `dinero-flotante`, que toca `Enemy.gd`). Los `.wav` de `assets/audio/effects/SpaceShips/` se quedan en `assets/`.
- Actualizar docs/design/enemigos.md ("Daño y muerte"): las naves no suenan al morir; el campo y el código siguen por si se quiere volver a poner.

## Archivos que toca
- resources/enemy_data/*.tres
- docs/design/enemigos.md

## Cómo se prueba a mano
1. F5, nivel 1, colocar torres y lanzar la oleada.
2. Las torres suenan al disparar; las naves mueren sin sonido.
