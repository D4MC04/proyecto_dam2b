# Apagar _process cuando no hay trabajo

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Varios nodos (UI, efectos, poderes) ejecutan `_process` cada frame aunque no tengan nada que hacer.

## Qué hay que hacer
- Revisar los `_process` del proyecto (grep).
- Usar `set_process(false)` cuando no hay nada pendiente y activarlo cuando haga falta.
- No cambiar el comportamiento.

## Archivos que toca
- scripts/level/Powers.gd
- scripts/level_ui/*.gd
- scripts/entities/*.gd

## Cómo se prueba a mano
1. Jugar el nivel 3 entero: los poderes, la UI y los efectos funcionan igual.
