# Mejora: cada color de Dart con su rasgo

Creador: David
Responsable: David
Estado: propuesta
Prioridad: baja
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Los cuatro Dart son iguales salvo el color, y desaparecen de las oleadas del 5 al 8 (en las naves antiguas de esos niveles solo queda la Wasp como nave rápida). Con un rasgo pequeño por color, el enjambre del nivel 1 ya enseña que no todas las naves son iguales, y vuelven a servir de relleno rápido en niveles altos.

## Qué hay que hacer
- Rojo: +25 % de velocidad (112) y −20 % de vida (20).
- Verde: +40 % de vida (35) y −15 % de velocidad (76).
- Hielo: la ralentización le dura la mitad (si ya existe `slow_resist` de `nave-interceptora`, usarlo; si no, crearlo aquí en `EnemyData` y `slow()`).
- Morado: el de referencia, sin cambios.
- Recompensas con la fórmula de enemigos.md (redondeadas a 5) y `description` de cada uno.
- Volver a meter `DART` en las naves antiguas de los niveles 5 a 8 en `make_waves.gd` y regenerar.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md › "Datos", "Ralentización"
- docs/design/niveles.md › "Generador de oleadas"
- scripts/entities/Enemy.gd › `slow()`

## Archivos que toca
- resources/enemy_data/dart_*.tres
- scripts/resources/EnemyData.gd y scripts/entities/Enemy.gd (solo si hay que crear `slow_resist`)
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- docs/design/enemigos.md y docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 1: los Dart rojos se adelantan y los verdes aguantan más disparos.
2. En el nivel 3, los Dart de hielo se quitan la escarcha antes.
3. En los niveles 5-8 vuelven a salir Darts.
