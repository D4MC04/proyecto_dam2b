# Quitar "OLEADA X/Y" de debajo del sector

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
La oleada se ve dos veces a la vez: arriba en el centro, debajo de "SECTOR N", y en el pie de la barra derecha ("OL. X/Y"). Sobra la de arriba.

## Qué hay que hacer
- Quitar `WaveLabel` de `LevelIndicator` (escena y script), junto con `set_wave()` y su llamada desde `LevelUI._refresh_wave_controls`. Arriba en el centro solo queda "SECTOR N".
- Si la clave de traducción `HUD_WAVE_N_OF` (y `HUD_WAVE` del texto por defecto del nodo) se queda sin uso, quitarla también.
- No tocar el pie de la barra (`FooterWaveLabel`) ni `WaveAnnouncer`.

## Qué leer
- docs/design/ui.md › "LevelIndicator"
- scripts/level_ui/LevelIndicator.gd › `set_wave()`
- scenes/level_ui/LevelIndicator.tscn › nodo `WaveLabel`
- scripts/level_ui/LevelUI.gd › `_refresh_wave_controls()`

## Archivos que toca
- scenes/level_ui/LevelIndicator.tscn
- scripts/level_ui/LevelIndicator.gd
- scripts/level_ui/LevelUI.gd
- archivo de traducciones (solo si la clave queda sin uso)
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar cualquier nivel y lanzar un par de oleadas.
2. Arriba en el centro solo debería verse "SECTOR N", sin la línea de oleada debajo.
3. El pie de la barra derecha sigue enseñando "OL. X/Y".
