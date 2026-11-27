# Nuevo orden de desbloqueo de las torretas

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Se quiere cambiar el orden en que se desbloquean las torretas.

## Qué hay que hacer
- **Antes de tocar nada, pedir al usuario el orden nuevo** y esperarlo. Ahora es: Cañón doble, Minigun, Cryo, Cañón pesado, Minero, Tesla, Orbitador, Amplificador, Disintegrator y Rail.
- Cambiar `GameData.turret_order` (en `scenes/GameData.tscn`) a ese orden.
- Revisar lo que depende del orden y ajustarlo:
  - Las torretas que ofrece cada sector (`resources/level_data/`), si están puestas a mano.
  - El desbloqueo al ganar cada sector (`GameState.complete_level()`).
  - Las oleadas o tutoriales que den por hecho que una torreta ya está.
  - Los costes, que en `docs/design/torretas.md` siguen el orden de desbloqueo: preguntar al usuario si se reordenan o se quedan como están.

## Qué leer
- docs/design/torretas.md › lo que hable del orden de desbloqueo y los costes (sacarlo con Grep "desbloq")
- scenes/GameData.tscn › `turret_order`
- scripts/autoloads/GameState.gd › `complete_level()`

## Archivos que toca
- scenes/GameData.tscn
- resources/level_data/*.tres (si hace falta)
- resources/turret_data/*.tres (solo si el usuario quiere reordenar costes)

## Cómo se prueba a mano
1. Partida nueva: ganar el tutorial y los primeros sectores.
2. Las torretas deberían desbloquearse en el orden nuevo, y cada sector ofrecer las que tocan.
