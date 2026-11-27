# Jefe final para el nivel 9

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El último nivel acaba con la misma Nodriza que el 6.

## Qué hay que hacer
- Jefe propio (fases: escudo, suelta naves, EMP) para el final del nivel 9, en su última oleada (con el panel de balanceo (pestaña Niveles)).
- Sprite grande con script de `scripts/tools/`; aviso de jefe.

## Archivos que toca
- scripts/tools/make_jefe_final.gd
- resources/enemy_data/jefe_final.tres
- scripts/entities/Enemy.gd
- resources/wave_data/ (última oleada del nivel 9, editada con el panel)
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Última oleada del nivel 9: sale el jefe final y cambia de fase al bajar su vida.
