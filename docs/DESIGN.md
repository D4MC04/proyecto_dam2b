# Astro Artillery: diseño actual

Describe lo que hace el código hoy. El detalle de cada sistema está en `docs/design/`.

## Visión general

Tower defense 2D hecho en Godot 4.7 con GDScript. El jugador elige un nivel, compra torres con dinero y las coloca en casillas fijas del mapa. Los enemigos llegan por oleadas, que el jugador lanza con un botón (o solas en modo AUTO); dentro de cada oleada salen según una lista de tiempos y recorren caminos fijos. Matar enemigos da dinero. Cada enemigo que llega al final de su camino quita vida a la estación espacial; si la estación llega a 0, se pierde la partida; si se limpia la última oleada, se gana el nivel.

- Resolución base: 960x540 px (ventana 1920x1080, escala ×2, escalado `canvas_items` con `scale_mode` entero y aspecto `keep`: en pantallas mayores salen bandas negras en vez de estirar), filtro de texturas "nearest".
- Tamaño de casilla: 16x16 px.
- Escena inicial: `scenes/MainMenu.tscn`.
- Los datos de juego (niveles, oleadas, enemigos, torres, ataques) son `Resource` en `resources/`; los scripts de `scripts/resources/` definen sus campos.

## Flujo de pantallas

1. `MainMenu`: pantalla de título y selección de nivel.
2. `Game`: contiene un `Level` (mapa, enemigos, torres) y un `LevelUI` en tres columnas: barra izquierda de 128 px, área de juego de 704x540 px con el mapa centrado en los dos ejes (y la pausa, la derrota y la victoria) y barra derecha de 128 px.
3. Desde pausa o derrota se reinicia el nivel o se vuelve a la selección de nivel; la derrota llega tras una cámara lenta y un glitch, con un resumen de la partida. Al limpiar la última oleada, tras un breve respiro, entra la victoria deslizando, con un resumen que cuenta hacia arriba, "Siguiente nivel" (monta el siguiente nivel sin pasar por el menú; no sale en el último) y "Menú".

## Sistemas principales

- [Flujo y autoloads](design/flujo.md): autoloads `GameData`, `GameState`, `Settings` y `MusicManager`, y la escena `Game` que monta, reinicia y cierra un nivel.
- [Niveles](design/niveles.md): `Level`, dinero, cuadrícula de construcción, mapas, caminos y aparición de enemigos por oleadas.
- [Enemigos](design/enemigos.md): movimiento por el camino, vida, ralentización, recompensa y los tipos definidos.
- [Torres](design/torres.md): colocación, apuntado, los 5 tipos de ataque y las 7 torres definidas.
- [Base](design/base.md): la estación espacial que hay en los mapas, con vida y escudo.
- [UI de nivel](design/ui.md): columnas, ficha de la barra izquierda, barra lateral de compra, menú de pausa, pantallas de derrota y victoria y resumen de partida.
- [Menú principal](design/menu.md): título, selección de nivel, opciones (audio, pantalla y juego, guardadas en disco), música y fondo animado.
- [Arte](design/art.md): tamaños, paleta, contorno, luz y nombres de los sprites de `assets/`.

## Decidido

- Las oleadas no se solapan: la siguiente solo se puede lanzar (con el botón o con AUTO) cuando no quedan enemigos de la anterior por salir ni vivos.
- Los caminos de los mapas no se dibujan (ni carriles, ni bandas, ni flechas): los marca el espacio libre por donde se ve que pueden pasar las naves entre asteroides y planetas.

## Abierto
