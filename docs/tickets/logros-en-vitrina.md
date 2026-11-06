# Ver los logros en la vitrina, sin pantalla propia

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Los logros se ven ya en las medallas de la vitrina; abrir otra pantalla para leerlos sobra. Además, los corchetes blancos alrededor de toda la vitrina confunden: solo las medallas se pueden mirar.

## Qué hay que hacer
- Al pasar el ratón por una medalla de la vitrina, enseñar ahí mismo su nombre, descripción y fase (por ejemplo, una ficha pequeña junto a la medalla), sin abrir otra pantalla.
- Quitar `AchievementsScreen` (escena, script y su nodo en `MainMenu`) y que la vitrina deje de abrir nada al pulsarla.
- Quitar los corchetes blancos de la vitrina entera; solo los tienen las medallas.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Logros", "Escena y script" y la fila `MedalCase` de "Oficina"
- scripts/main_menu/MedalCase.gd
- scripts/main_menu/OfficeObject.gd › `hover_rect()`, `show_brackets`
- scripts/screens/MainMenu.gd › dónde se abre `AchievementsScreen`

## Archivos que toca
- scripts/main_menu/MedalCase.gd
- scripts/screens/MainMenu.gd
- scenes/MainMenu.tscn
- scenes/AchievementsScreen.tscn y scripts/screens/AchievementsScreen.gd (se borran)
- docs/design/menu.md

## Cómo se prueba a mano
1. Entrar a la oficina y girar a la vitrina.
2. Pasar el ratón por la vitrina fuera de las medallas: no salen corchetes.
3. Pasar el ratón por una medalla: corchetes en la medalla y su ficha con nombre, descripción y fase.
4. Pulsar la vitrina no abre ninguna pantalla.
