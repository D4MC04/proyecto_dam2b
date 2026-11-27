# Panel de balanceo: pestaña Diálogos

Estado: aceptada
Espera a: panel-balance-niveles
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Los diálogos (la llamada de NOVA, los tutoriales) están en `translations/textos.csv` y editarlos a mano en un CSV es incómodo. Una pestaña del panel de balanceo para leerlos y editarlos en español y en inglés.

## Qué hay que hacer
- Requiere el panel de `panel-balance-torretas-enemigos` (base en `tools/balance/`, ya en main).
- Rellenar la pestaña Diálogos: leer `translations/textos.csv` (columnas `keys,es,en`) con un parser de CSV de verdad (comillas, comas y saltos de línea dentro de un texto).
- Agrupar las claves por prefijo de diálogo, en el orden de sus números: `INTRO_CALL_*` (llamada de NOVA), `TUTORIAL_*` y sus variantes (`TUTORIAL_STATION_`, `TUTORIAL_UPGRADE_`, `TUTORIAL_POWERS_`...) y `OFFICE_TUTORIAL_*`. Cada grupo enseña sus líneas en orden, con `es` y `en` lado a lado y editables (textarea).
- Un buscador por texto o clave y un interruptor "Todos los textos" que enseña también el resto de claves del CSV, para editarlas igual.
- Contador de caracteres por texto. Avisar si una línea es bastante más larga que las demás de su diálogo (el recuadro es fijo; ver menu.md › `IntroDialog`).
- Guardar reescribe el CSV conservando el orden de las filas, las comillas donde hacían falta y el final de línea del archivo original. `git diff` solo debe enseñar las filas cambiadas.
- Godot genera los `.translation` al importar el CSV. Comprobar si el juego abierto con `/test` (sin editor) coge el texto nuevo. Si no lo coge, que el panel avise de que hay que reimportar y apuntar en docs/CLAUDE-CODE.md cómo hacerlo.
- Ampliar la sección del panel en docs/CLAUDE-CODE.md con la pestaña Diálogos.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Idioma" (párrafo de `textos.csv`) y el párrafo de `IntroDialog`
- docs/design/ui.md › "Tutorial del nivel de emergencia"
- tools/balance/ (lo que dejó el ticket de la base)

## Archivos que toca
- tools/balance/*.js, tools/balance/index.html
- docs/CLAUDE-CODE.md

## Cómo se prueba a mano
1. Abrir el panel, elegir la carpeta del juego y entrar en Diálogos: deberían salir la llamada de NOVA (4 líneas) y los tutoriales en orden.
2. Cambiar `INTRO_CALL_1` en español y guardar. `git diff translations/textos.csv` debería cambiar solo esa fila.
3. Empezar partida nueva en una ranura vacía: la primera frase de NOVA debería ser la nueva.
