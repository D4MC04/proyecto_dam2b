# 10 oleadas por nivel con dificultad creciente

Creador: David
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Los niveles tienen de 5 a 10 oleadas. Con 10 en todos, una curva que empiece fácil y se complique, variedad de naves, todos los caminos en uso y grupitos bien repartidos, cada nivel se juega como una partida completa.

## Qué hay que hacer
- Va después de desbloqueo-torretas y balance-economia: usa las torretas de cada nivel y las recompensas y vidas nuevas.
- Retocar la tabla `LEVELS` de `scripts/tools/make_waves.gd` (y su lógica si hace falta) y volver a generar las oleadas; no escribir los `.tres` a mano.
- 10 oleadas en cada nivel. Cada nivel empieza fácil y se pone difícil; ajustado al dinero inicial y a las torretas que tiene.
- Buena variedad de naves en cada nivel, con las nuevas del nivel como protagonistas.
- Que se usen todos los caminos del mapa, no siempre por turnos fijos.
- Naves en grupitos bien repartidos en el tiempo y entre caminos.
- Si el nivel 5 sigue como subrecurso en `GameData.tscn`, el script ya lo trata.
- Los jefes de jefe-nivel-3/5/8/9 y jefe-final-* tocan oleadas: si alguno ya está en main, respetar lo que haya puesto.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Datos de nivel", "Generador de oleadas", "Mapas de los niveles"
- docs/design/enemigos.md › "Datos"
- scripts/tools/make_waves.gd › `LEVELS` y la generación de grupos, tiempos y caminos

## Archivos que toca
- scripts/tools/make_waves.gd
- resources/wave_data/*.tres, resources/level_data/level_*.tres, scenes/GameData.tscn (los reescribe el script)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 1: 10 oleadas; las primeras se pasan fácil con el Cañón doble y las últimas aprietan.
2. Jugar un nivel con varios caminos (p. ej. el 7): salen naves por todos los caminos, en grupitos y con varios tipos.
3. La pestaña Oleadas enseña 10 oleadas en cada nivel.
