# Panel de balanceo: pestaña Sprites

Estado: aceptada
Espera a: panel-niveles-copiar-oleadas
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
Para balancear ayuda ver cada torreta y cada nave junto a sus números sin abrir Godot.

## Qué hay que hacer
- Nueva pestaña **Sprites** en el panel, con una cuadrícula de torretas (base, fusión y nivel 3 juntos) y otra de naves. Cada una con su nombre traducido.
- El sprite sale de su `TurretData` / `EnemyData` (`sprite_frames`, `icon` o lo que use cada una). Leer los `SpriteFrames` del `.tres` (animaciones, `AtlasTexture` con su `region`, `speed` y `loop`) y los PNG de la carpeta elegida.
- Pintar en `<canvas>` a escala entera (×2, ×4…) con `image-rendering: pixelated`. Selector de zoom.
- **Animaciones**: cada `SpriteFrames` se puede reproducir con sus fps y su bucle, y con un desplegable para elegir la animación. Es reproducir frames, así que va incluido.
- **No** hacer una simulación de torretas disparando a una nave en movimiento: es mucho trabajo y no se pide.
- Solo se ven, no se edita nada.
- Ampliar docs/CLAUDE-CODE.md › "Panel de balanceo" con la pestaña Sprites.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/art.md › tamaños de sprites
- tools/balance/app.js (lista `TABS`), tools/balance/project.js (leer archivos y nombres traducidos), tools/balance/tres.js
- scripts/resources/TurretData.gd y EnemyData.gd (solo los `@export` de sprites)
- Un ejemplo: resources/turret_data/minigun.tres y el `SpriteFrames` al que apunta

## Archivos que toca
- tools/balance/sprites.js (nuevo), tools/balance/app.js, tools/balance/index.html, tools/balance/style.css
- docs/CLAUDE-CODE.md

## Cómo se prueba a mano
1. Abrir el panel, elegir la carpeta del juego y entrar en Sprites: deberían salir todas las torretas con sus tres niveles y todas las naves, nítidas y sin difuminar.
2. Pulsar reproducir en la Minigun y en una nave: la animación debería ir a la velocidad del juego.
3. Cambiar el zoom: los píxeles siguen nítidos.
