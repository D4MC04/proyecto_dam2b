# Escena propia de cada torreta en la Navedex

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

Depende del ticket `navedex-vitrina-mapa` (la vitrina sobre un trozo de mapa).

## Por qué
Ahora todas las torretas de la vitrina disparan a la misma nave de prueba (un Dart lento que no muere), así que no se ve lo que tiene de especial cada una. Cada torreta tiene que tener su propia escena, con las naves que mejor enseñan su mecánica.

## Qué hay que hacer
- Darle a cada torreta base de `Navedex.TURRET_FILES` su escena: qué naves salen, cuántas, a qué velocidad y con cuánta separación, y si mueren y vuelven a salir. Que las escenas sean datos (un diccionario o un Resource por torreta), no un `if` largo en código. Las mejoras usan la escena de su base, salvo que su mecánica pida otra.
- Escenas (la mecánica sale de docs/design/torretas.md):
  - **Minigun:** naves lentas y con mucha vida, seguidas, para que dé tiempo a ver cómo acelera la cadencia hasta el tope, cómo se sobrecalienta y cómo para 3 s.
  - **Cryo:** naves rápidas que entran en su onda y frenan a la vista (al 55 %), y vuelven a correr al pasar los 3,5 s.
  - Para las demás, lo mismo con su mecánica: Cañón doble (lo básico: un disparo tras otro a una nave), Cañón pesado (grupo junto para que se vea el área de la explosión), Tesla (varias naves juntas para ver los saltos de la cadena), Rail (naves en fila para ver cómo el haz las atraviesa), Disintegrator (una nave dura a la que no suelta, para ver cómo sube de nivel el haz), Orbitador (naves que entran en su anillo y chocan con las cargas), Amplificador (con torretas alrededor y su aura) y Minero (generando dinero). Si una no se luce, se ajusta su escena sin cambiar el balance de las torretas.
- Las naves tienen que ser del juego (`resources/enemy_data/`) y verse bien; se puede cambiar su vida o su velocidad solo en la vitrina, como hace ya el Dart de prueba (`TARGET_HEALTH`, `TARGET_SPEED`).
- No tocar los datos de las torretas ni de las naves (`.tres`): todo se ajusta solo para la vitrina.
- Actualizar docs/design/menu.md › "Navedex" (el punto **Vitrina**) con la escena de cada torreta.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Navedex" (el punto **Vitrina**)
- docs/design/torretas.md › "Datos" (tabla de recursos), "Sobrecalentamiento", "Amplificador" y "Minero"
- scripts/screens/NavedexShowcase.gd › `_build_turret()`, `_spawn_target()`, `_spawn()`
- scripts/screens/Navedex.gd › `TURRET_FILES`

## Archivos que toca
- scripts/screens/NavedexShowcase.gd
- resources/ o scripts/resources/ (si las escenas van en un Resource)
- docs/design/menu.md

## Cómo se prueba a mano
1. F5, en la oficina pulsar la tablet y luego TORRETAS.
2. Pasar por todas las torretas y por sus mejoras.
3. Minigun: llegan naves lentas y se ve cómo dispara cada vez más rápido hasta que se calienta y para. Cryo: llegan naves rápidas y frenan al pasar por su onda. Cada una de las demás enseña su mecánica (área, cadena, perforación, haz que sube de nivel, cargas, aura y dinero).
