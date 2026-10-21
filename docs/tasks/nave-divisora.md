# Nave nueva: Divisora, que se parte en naves pequeñas al morir

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Una nave nueva, con su propio dibujo, que al morir suelta otras más pequeñas: castiga las torres de un solo disparo fuerte y premia las de área.

## Qué hay que hacer
- **Sprite nuevo** en `assets/sprites/enemies/divisora/`:
  - Pixel art de 32x32 mirando hacia arriba, con 2-4 frames, como `nave_normal_up_1.png`.
  - Seguir `docs/design/art.md`. Tonos naranjas, con aspecto de nave nodriza pequeña (compartimentos o tres módulos unidos).
  - Generarlo con un script de `scripts/tools/`. Solo hacia arriba: `rotate_sprite = true`.
- **Datos:** `resources/enemy_data/divisora.tres`:
  - Vida 120, velocidad 35, recompensa 30, daño 15.
  - Añadirla al ARCHIVO.
- **Habilidad:**
  - Al morir crea 3 Dart (`dart_rojo.tres`) en su mismo punto del camino, que salen con un destello.
  - Tienen que contar como vivos en el `Spawner`, para que la oleada no se dé por limpia antes de tiempo.
- **Oleadas:** añadirla a las del nivel 5.

## Archivos que toca
- assets/sprites/enemies/divisora/ (nuevo), resources/sprite_frames/ (nuevo), scripts/tools/ (generador)
- resources/enemy_data/divisora.tres (nuevo), resources/wave_data/level_5*.tres
- scripts/entities/Enemy.gd, scripts/resources/EnemyData.gd, scripts/level/Spawner.gd, scripts/screens/Navedex.gd
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Jugar el nivel 5.
2. Al matar una Divisora salen 3 Dart rojos de donde estaba.
3. INICIAR no se vuelve a activar hasta matar también los Dart.
