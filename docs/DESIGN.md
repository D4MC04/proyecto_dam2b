# Astro Artillery: diseño actual

Describe lo que hace el código hoy. El detalle de cada sistema está en `docs/design/`.

## Visión general

Tower defense 2D hecho en Godot 4.7 con GDScript. El jugador elige un nivel, compra torres con dinero y las coloca en casillas fijas del mapa. Los enemigos salen según una lista de tiempos y recorren caminos fijos. Matar enemigos da dinero. Si un enemigo llega al final de su camino, se pierde la partida.

- Resolución base: 592x272 px (ventana 1776x816, escalado `canvas_items`, aspecto `keep_width`), filtro de texturas "nearest".
- Tamaño de casilla: 16x16 px.
- Escena inicial: `scenes/MainMenu.tscn`.
- Los datos de juego (niveles, oleadas, enemigos, torres, ataques) son `Resource` en `resources/`; los scripts de `scripts/resources/` definen sus campos.

## Flujo de pantallas

1. `MainMenu`: pantalla de título y selección de nivel.
2. `Game`: contiene un `Level` (mapa, enemigos, torres) y un `LevelUI` (barra lateral, pausa, game over).
3. Desde pausa o game over se reinicia el nivel o se vuelve a la selección de nivel.

## Sistemas principales

- [Flujo y autoloads](design/flujo.md): autoloads `GameData`, `GameState` y `MusicManager`, y la escena `Game` que monta, reinicia y cierra un nivel.
- [Niveles](design/niveles.md): `Level`, dinero, cuadrícula de construcción, mapas, caminos y aparición de enemigos por oleadas.
- [Enemigos](design/enemigos.md): movimiento por el camino, vida, ralentización, recompensa y los 12 tipos definidos.
- [Torres](design/torres.md): colocación, apuntado, los 5 tipos de ataque y las 7 torres definidas.
- [Base](design/base.md): la estación espacial que hay en los mapas, con vida y escudo.
- [UI de nivel](design/ui.md): barra lateral de compra, menú de pausa y pantalla de game over.
- [Menú principal](design/menu.md): título, selección de nivel, control de música y fondo animado.
- [Arte](design/art.md): tamaños, paleta, contorno, luz y nombres de los sprites de `assets/`.

## Decidido

## Abierto
