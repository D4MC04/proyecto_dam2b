# Más oleadas por nivel, que escalan y con naves distintas por nivel

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Ahora cada nivel tiene 3 oleadas que son una sola oleada partida en tres trozos, así que se sienten iguales; los niveles 7, 8 y 9 copian las del 6, y casi todos los niveles mezclan los mismos Dart y Wasp. Espectro y Saboteadora no salen en ningún nivel. Queremos más oleadas, que cada una apriete más que la anterior, que cada nivel empiece más fuerte que el anterior y que cada nivel tenga sus propias naves.

## Qué hay que hacer
- Script generador `scripts/tools/make_waves.gd` (como los demás de `scripts/tools/`, se lanza en headless) que escribe las `WaveData` a partir de una tabla por nivel. No escribir las oleadas a mano.
- Tabla por nivel: número de oleadas (unas 5 en el nivel 1, subiendo hasta unas 10 en el 9), naves que puede sacar, "presupuesto" de la primera oleada y cuánto crece por oleada. Cada nave cuesta según su `reward` (o vida). Cada oleada: más naves, más juntas y, si está `vida-por-oleada`, `health_multiplier` que sube poco a poco.
- Cada nivel empieza por encima de donde empezó el anterior (la oleada 1 del nivel N+1 más dura que la 1 del N).
- Naves por nivel (orientativo, ajustar): 1 Darts y Wasp (como ahora, le gusta al usuario); 2 + Nave normal y UFO; 3 + Nave agresiva y Spikey; 4 + Acorazado; 5 + Ariete y Divisora; 6 + Reparadora y Nodriza; 7 + Espectro; 8 + Saboteadora; 9 todas. Las nuevas de cada nivel deben ser protagonistas, no 1 suelta. La Nodriza solo en la última oleada de los niveles donde salga.
- Respetar: torres disponibles de cada nivel (que se pueda ganar con ellas), los caminos por turnos (`path_index` = posición % caminos; el nivel 4 con su reparto) y que los tiempos empiecen a 3 s (primera) o 2 s (resto).
- Archivos: `resources/wave_data/level_N_K.tres`. Conservar los `uid=` de los que ya existen (sobrescribir contenido, no el uid) y añadir los nuevos a `resources/level_data/level_N.tres` y al nivel 5 de `scenes/GameData.tscn` (sin cambiar uid ni id de ext_resource existentes).
- Dinero inicial y premios: comprobar que los niveles se pueden ganar; ajustar solo la tabla del generador, no `LevelState`.
- No tocar mapas.
- Actualizar la tabla y el texto de "Datos de nivel" en docs/design/niveles.md.

## Archivos que toca
- scripts/tools/make_waves.gd (nuevo)
- resources/wave_data/*.tres (nuevos y regenerados)
- resources/level_data/level_*.tres
- scenes/GameData.tscn (solo las oleadas del nivel 5)
- docs/design/niveles.md

## Cómo se prueba a mano
1. F5, nivel 1: unas 5 oleadas con Darts y Wasp, cada una más larga y apretada que la anterior; se gana.
2. Nivel 4: más oleadas que en el 1, con Acorazados desde el principio y la primera ya más dura que la primera del nivel 3.
3. Niveles 7 y 8: salen Espectro y Saboteadora respectivamente; ya no son copias del 6.
4. La pestaña Oleadas enseña todas las oleadas del nivel con sus naves.
