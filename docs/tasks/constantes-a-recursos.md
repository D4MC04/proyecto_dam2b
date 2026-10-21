# Valores de equilibrio en un Resource

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Valores como dinero inicial (5000) o premio de oleada perfecta (25) están en código.

## Qué hay que hacer
- Crear `BalanceData` (Resource) con esos valores y leerlo desde `LevelState`/`Level`.
- Documentar en niveles.md.

## Archivos que toca
- scripts/resources/BalanceData.gd
- resources/balance.tres
- scripts/level/LevelState.gd
- scripts/level/Level.gd

## Cómo se prueba a mano
1. Cambiar el dinero inicial en `balance.tres`: el nivel empieza con ese dinero.
