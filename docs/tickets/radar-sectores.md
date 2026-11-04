# Selección de nivel con radar de sectores

Creador: Renzo
Responsable: Renzo
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
La selección de nivel es una cuadrícula de botones numerados. Un radar de sectores con la estación en el centro da sensación de avance (el alcance crece con el progreso) y enseña de un vistazo qué hay en cada nivel.

Depende del ticket `estrellas-nivel` (la ficha enseña las estrellas).

## Qué hay que hacer
Seguir el boceto `docs/bocetos/radar-sectores.html`. Solo la parte normal; el modo corrupto del jefe es el ticket `radar-corrupto-jefe`.

- Cambiar `LevelButtonsContainer` (cuadrícula de `LevelButton`) de `LevelSelectionScreen` por un radar redondo de tamaño fijo y, a la derecha, una ficha. Mantener el botón "Volver".
- Radar: estación en el centro, anillos y radios, y un barrido que gira y enciende cada contacto al pasar (luego se apaga poco a poco).
- Cada nivel es un contacto, cada uno más lejos del centro que el anterior. Ningún icono toca el borde del radar.
- El alcance del radar crece con el progreso (`GameState.current_level`) y solo deja ver hasta el nivel desbloqueado; fuera del alcance, oscuro con ruido. Borde del alcance en línea discontinua animada.
- Anillos con textos de km (radio total 4.000 km) en una zona donde nunca haya contactos.
- Iconos: las naves pixel del boceto (incursor, colmillo, triturador y espectro: `PATTERNS` del boceto), con ojos rojos que parpadean. Generarlas como sprites con un script nuevo en `scripts/tools/` (como los `make_*.gd` que ya hay). Cada nivel usa la de su enemigo más peligroso.
- Colores: verde completado, amarillo pendiente, azul al pasar el ratón o seleccionado (pequeño salto y una onda circular).
- Clic = seleccionar, con una ruta discontinua animada desde la estación hasta el contacto. Para jugar: botón DESPLEGAR (REPETIR si ya está completado) en la ficha, o doble clic en el contacto, con el salto al hiperespacio que ya existe (`_open_level`).
- Ficha estilo HUD con esquinas: "SEC-0N · nombre", estado, rumbo, distancia, oleadas, amenaza en texto (Baja, Media, Alta; Extrema solo para el jefe) y MEJOR con las estrellas del ticket `estrellas-nivel` (☆☆☆ vacías si no está completado).
- Datos nuevos de cada nivel en `LevelData`: nombre, posición en el radar (distancia y ángulo), amenaza y nave del icono. Rellenarlos en los `level_N.tres` y en el nivel 5 de `scenes/GameData.tscn`. Rumbo y distancia salen de la posición; oleadas, de `waves.size()`.
- Textos nuevos con claves en `translations/textos.csv` (es y en), incluidos los nombres de los sectores.
- Respetar `GameState.is_unlocked()` (ahora devuelve siempre `true` para probar).
- No tocar nada de `scenes/maps/`.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Escena y script", "Comportamiento", "Salto al hiperespacio", "Idiomas"
- docs/design/niveles.md › "Datos de nivel"
- docs/design/art.md › "Paleta", "Fuente"
- scripts/screens/MainMenu.gd › `_build_level_buttons()`, `_open_level()`, `_on_volver_pressed()`
- scenes/MainMenu.tscn › nodo `LevelSelectionScreen`
- scripts/level_ui/LevelButton.gd
- scripts/resources/LevelData.gd
- scripts/autoloads/GameState.gd › `is_unlocked()`, `current_level` y la función de estrellas del ticket `estrellas-nivel`

## Archivos que toca
- scripts/screens/MainMenu.gd
- scenes/MainMenu.tscn
- scripts/level_ui/ (scripts nuevos del radar y de la ficha; `LevelButton.gd` se borra si deja de usarse)
- scripts/resources/LevelData.gd
- resources/level_data/level_1.tres … level_9.tres
- scenes/GameData.tscn (nivel 5)
- scripts/tools/ (script nuevo que genera los sprites de las naves)
- assets/sprites/ (sprites generados)
- translations/textos.csv
- docs/design/menu.md, docs/design/niveles.md

## Cómo se prueba a mano
1. Abrir el juego, elegir ranura y pulsar "Jugar".
2. Debería verse el radar con la estación en el centro, el barrido girando y los contactos encendiéndose al pasar; fuera del alcance, oscuro con ruido.
3. Pasar el ratón por un contacto: se pone azul. Clic: salta un poco, sale la onda y la ruta discontinua desde la estación; la ficha cambia.
4. Nivel completado: verde, botón REPETIR y sus estrellas. Pendiente: amarillo, DESPLEGAR y ☆☆☆.
5. Doble clic en un contacto o DESPLEGAR: salto al hiperespacio y empieza el nivel.
6. "Volver" regresa al título. Con el idioma en inglés (Opciones), los textos del radar y de la ficha salen en inglés.
