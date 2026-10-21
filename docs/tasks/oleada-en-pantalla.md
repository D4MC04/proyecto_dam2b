# "OLEADA N" en pantalla

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
La oleada en curso solo se ve en la barra lateral ("OLEADA N" en la pestaña Oleadas y "OL. X/Y" en el pie). Al jugar se mira el mapa, así que no se sabe en qué oleada estás.

## Qué hay que hacer
- Al lanzar cada oleada (`Spawner.wave_started`), aviso en el centro del área de juego: "OLEADA N" grande (48 px, Monogram) y debajo "N / TOTAL" pequeño; en la última, "ÚLTIMA OLEADA". Entra, se queda ~1,5 s y se desvanece, en tiempo real, sin pausar ni tapar las barras ni recibir el ratón. Estilo de los colores de la UI (`#40e0f0` / `#cce6ff`), sin antialiasing.
- En las oleadas con Nodriza no se enseña: ya sale el `BossAlert`.
- Indicador fijo: debajo de "NIVEL N" en `LevelIndicator`, una línea pequeña "OLEADA X/Y" (misma regla que el pie: antes de empezar, 1/Y). Se desvanece junto con el "NIVEL N".
- Nodo nuevo `WaveAnnouncer` (script propio), al lado de `BossAlert` en `GameArea`. Lo llama `LevelUI._on_wave_started`.
- Actualizar docs/design/ui.md (apartados nuevos y "LevelIndicator").

## Archivos que toca
- scripts/level_ui/WaveAnnouncer.gd (nuevo)
- scripts/level_ui/LevelUI.gd + la escena donde está `BossAlert`
- scripts/level_ui/LevelIndicator.gd, scenes/level_ui/LevelIndicator.tscn
- docs/design/ui.md

## Cómo se prueba a mano
1. F5, nivel 1: arriba se ve "NIVEL 1" y debajo "OLEADA 1/Y".
2. Pulsar INICIAR: en el centro sale "OLEADA 1" y se desvanece; el indicador fijo sigue diciendo 1/Y.
3. Al lanzar la siguiente: "OLEADA 2" y el indicador pasa a 2/Y. En la última sale "ÚLTIMA OLEADA".
4. En el nivel 6, la oleada con Nodriza enseña solo la alerta roja.
