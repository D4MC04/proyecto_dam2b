# Base: estación espacial

## Escena y script

`scenes/entities/Base.tscn` + `scripts/entities/Base.gd` (clase `Base`).

- Raíz `SpaceStation`: `Sprite2D` con `assets/sprites/base/station.png`.
- `Shield`: `Sprite2D` con `assets/sprites/base/shield.png`, escalado a 1,25.

Está instanciada como nodo `SpaceStation` en `scenes/maps/Map.tscn` y en los mapas que usan los 6 niveles, con una posición distinta en cada mapa.

## Qué hace el script

- `max_health` (exportado, 100) y `health`, que empieza al máximo.
- `take_damage(amount)`:
  - Resta vida sin bajar de 0 y emite `health_changed(health, max_health)`.
  - Si la vida llega a 0, oculta el escudo y emite `destroyed`.
  - Si no, el escudo parpadea 0,5 s con la textura `shield_debil.png`. Con la vida al 50 % o menos se queda con esa textura; por encima vuelve a `shield.png`.
- Con la vida ya a 0, `take_damage` no hace nada.

## Comunicación con el resto

Ninguna en el código actual: es un elemento visual del mapa.

## Dudas

- Ningún script llama a `Base.take_damage` ni se conecta a `health_changed` o `destroyed`. La derrota la decide `Level` cuando el `Spawner` emite `enemy_reached_end`, con el primer enemigo que llega.
- La vida de la base no se muestra en la interfaz.
- Los caminos no terminan en la posición de la base. En `Level1.tscn` el camino acaba en (376, 216) y la base está en (440, 216); no he comprobado el resto de mapas.
- `assets/sprites/base/space_station.png` (48x48) solo lo usan mapas que no están en ningún nivel (`Level6.tscn` a `Level10.tscn`).
