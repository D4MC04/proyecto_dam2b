# Botón de velocidad ×2

Estado: aceptada
Modelo recomendado: sonnet

## Por qué
Ahora no se puede acelerar el juego. En las oleadas fáciles, o cuando ya tienes las defensas puestas, toca esperar mucho. Un botón ×2 hace las partidas más ágiles.

## Qué hay que hacer
- En la barra derecha (`Sidebar`), al lado del botón AUTO, un botón "×1 / ×2" con el mismo estilo (borde ámbar cuando está activo).
- Pide el cambio con una señal (como `auto_waves_toggled`), y `LevelUI` aplica `Engine.time_scale = 2.0`.
- `LevelUI` ya es la única que toca `Engine.time_scale` (pausa, derrota, victoria): la velocidad elegida tiene que respetarse al volver de la pausa y volver a 1 al reiniciar, perder, ganar o salir al menú.
- Actualizar docs/design/ui.md.

## Archivos que toca
- scripts/level_ui/Sidebar.gd
- scenes/level_ui/Sidebar.tscn
- scripts/level_ui/LevelUI.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` (F5) y entrar al nivel 1.
2. Lanzar una oleada y pulsar "×2": los enemigos y las torres van el doble de rápido.
3. Pausa (Esc) y volver: sigue a ×2.
4. Perder o reiniciar: vuelve a ×1.
