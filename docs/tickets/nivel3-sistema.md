# Tercer nivel de mejora en todas las torretas (sistema)

Creador: Ezequiel
Responsable: Ezequiel
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Cada torreta pasa a tener Nivel 1, 2 y 3. Hoy la fusionada (nivel 2) no tiene `fusion` y no se puede volver a mejorar. Este ticket monta la cadena 1 → 2 → 3 para las 10 torretas; el aspecto y la mecánica de cada nivel 3 se diseñan después, torreta a torreta (ver ticket `mejora-nivel3-skill`).

## Qué hay que hacer
- Crear el nivel 3 de las 10 torretas como `resources/turret_data/<x>_level3.tres` (`turret`, `minigun`, `rocket_launcher`, `cryo`, `disintegrator`, `rail`, `tesla`, `amplifier`, `orbiter`, `miner`). De momento es **provisional**: copia del nivel 2 (mismo ataque, números, sprites, `amp_effect`, `amplifier_level`, `money_amount`), sin `fusion` y sin `upgrade_frames`. Cada diseño de nivel 3 lo sustituirá luego.
- Enlazar cada `<x>_fusion.tres` con su nivel 3 en el campo `fusion` (nuevo `ext_resource`, sin cambiar los `uid=` ni los `id` existentes).
- Coste del nivel 3: **2 × el coste del nivel 2** (4 × la base). Se desbloquea igual que el nivel 2: si la torreta está disponible, se puede subir a 2 y a 3 sin más condiciones.

  | Torreta (nivel 1) | Nivel 2 | Nivel 3 |
  |---|---|---|
  | Cañón doble | 200 | 400 |
  | Minigun | 400 | 800 |
  | Cryo | 500 | 1000 |
  | Cañón pesado | 600 | 1200 |
  | Tesla | 700 | 1400 |
  | Orbitador | 700 | 1400 |
  | Rail | 1000 | 2000 |
  | Disintegrator | 900 | 1800 |
  | Amplificador | 800 | 1600 |
  | Minero | 600 | 1200 |

- Nombres y descripciones: claves nuevas `TURRET_<X>_LEVEL3_NAME` / `_DESC` en `translations/textos.csv`. Provisionales: el nombre del nivel 2 seguido de " III" (y la misma descripción) hasta que llegue su diseño.
- Comprobar que lo que ya recorre la cadena funciona con tres eslabones: `BuildManager.upgrade_selected()` (mejora de 2 a 3, `invested` acumula), `TurretActions` (el botón Mejorar sale en el nivel 2 con el coste del 3 y no sale en el 3), venta (mitad de lo invertido) y la Navedex (flechas de versión 1/2/3 y `FusionLabel`, `_collect_stat_max`).
- Logro de fusiones (`GameState.register_fusion`, `fused_turrets`, meta `GOAL_ALL` = 10): sigue contando solo las torretas de nivel 2; mejorar a nivel 3 no suma (si no, el "todas" se cumpliría antes de tiempo).
- Documentación: en docs/design/torretas.md › "Mejorar (fusión)" explicar los tres niveles, la regla de coste y añadir la columna/tabla del nivel 3 marcándolo como provisional; en "Datos", que `fusion` es null solo en el nivel 3. Tocar docs/DESIGN.md solo si menciona los dos niveles.

## Qué leer
- docs/design/torretas.md › "Mejorar (fusión)", "Vender", "Datos"
- scripts/level/BuildManager.gd › `upgrade_selected()`
- scripts/level_ui/TurretActions.gd › botón de mejora (`upgrade_button`)
- scripts/screens/Navedex.gd › `_collect_stat_max()`, `_select()`, `_show_entry()`
- scripts/autoloads/GameState.gd › `register_fusion()` y el logro `fusions`
- resources/turret_data/turret_fusion.tres (como modelo de `.tres`)

## Archivos que toca
- resources/turret_data/*_fusion.tres (campo `fusion`)
- resources/turret_data/*_level3.tres (nuevos, 10)
- translations/textos.csv
- scripts/autoloads/GameState.gd
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar el nivel 1 (o cualquiera con dinero de sobra).
2. Colocar un Cañón doble, seleccionarlo y pulsar Mejorar (-200€): pasa a Cañón cuádruple. Seleccionarlo otra vez: el botón dice -400€.
3. Pulsarlo: se convierte en "Cañón cuádruple III" (mismo aspecto por ahora) y ya no sale el botón Mejorar. Al venderlo devuelve 350€ (mitad de 700).
4. En la Navedex › Torretas, el Cañón doble tiene tres versiones con las flechas.
