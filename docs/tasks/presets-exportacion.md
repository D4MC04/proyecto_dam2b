# Preset de exportación sin archivos de desarrollo

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
No hay `export_presets.cfg`: al exportar entraría todo, incluidos `scripts/tools/`, `docs/` y los generadores.

## Qué hay que hacer
- Crear presets de Windows (y Web si se quiere) con filtro de exclusión: `scripts/tools/*`, `docs/*`, `*.md`, `trailer/*`.
- Comprobar que ningún script de juego usa algo de `scripts/tools/`.
- Documentar en docs/DESIGN.md cómo exportar.

## Archivos que toca
- export_presets.cfg
- docs/DESIGN.md

## Cómo se prueba a mano
1. Exportar a Windows desde el editor.
2. El .exe arranca, se juega el nivel 1 y el .pck pesa menos que antes.
