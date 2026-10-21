# Multiplicador de vida por oleada

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Para que las oleadas y los niveles pesen cada vez más no basta con meter más naves: hace falta un mando para que las mismas naves aguanten más, sin tocar sus `.tres`. Lo aprovecha `oleadas-escalonadas` (y luego `modo-infinito`).

## Qué hay que hacer
- Añadir `@export var health_multiplier: float = 1.0` a `WaveData` (sin él, todo queda como ahora).
- `Spawner` pasa el multiplicador de la oleada en curso al crear cada enemigo (también a los trozos de la Divisora que salen en esa oleada).
- `Enemy.setup` acepta el multiplicador (parámetro opcional, por defecto 1.0) y arranca con `max_health * multiplicador`; la barra de vida se calcula sobre esa vida máxima.
- La recompensa no cambia.
- La ficha (`InfoPanel`) de una nave en juego enseña su vida real; la de la pestaña Oleadas puede seguir enseñando la base.
- Actualizar docs/design/niveles.md ("Datos de nivel" y "Spawner") y docs/design/enemigos.md ("Daño y muerte").

## Archivos que toca
- scripts/resources/WaveData.gd
- scripts/level/Spawner.gd
- scripts/entities/Enemy.gd
- docs/design/niveles.md, docs/design/enemigos.md

## Cómo se prueba a mano
1. En el editor, abrir `resources/wave_data/level_1_2.tres` y poner `health_multiplier = 3` (sin guardar el cambio al acabar la prueba).
2. F5, nivel 1: en la oleada 1 las naves mueren como siempre; en la 2 aguantan unas 3 veces más y su barra de vida baja más despacio.
3. Con el multiplicador en 1, todo igual que antes.
