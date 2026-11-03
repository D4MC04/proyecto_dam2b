# Menú principal como oficina del comandante

Creador: D4MC04
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El jugador es el comandante de la estación que defiende. El menú principal deja de ser una lista de botones genéricos y pasa a ser su oficina dentro de la nave, para que el juego sea inmersivo. Es un cambio visual grande (Opus high como mínimo).

## Qué hay que hacer
- Rehacer el `TitleScreen` de `scenes/MainMenu.tscn` como una oficina tecnológica vista de frente: un escritorio y, detrás, un ventanal que ocupa todo el fondo por el que se ve el espacio. Para lo que se ve por el ventanal se puede reutilizar el fondo actual (`MenuBackground`, `RingedPlanet`, decoración, `Outpost`, `Skirmish`).
- Los botones pasan a ser objetos de la oficina, que se pueden pulsar y reaccionan al ratón (resalte o brillo al pasar por encima):
  - "Archivo" (Navedex: naves, torretas y logros) → una tablet sobre el escritorio.
  - "Stats" → un mural con condecoraciones en la pared.
  - "Salir" → una puerta o trampilla.
  - "Jugar" (selección de nivel) y "Opciones" → otros dos objetos que encajen en la oficina (por ejemplo, un mapa estelar holográfico o una consola de mando para Jugar y un panel de control para Opciones). Decidir y justificar en el doc.
  - Cada objeto debe entenderse sin texto, pero con un rótulo pequeño (al pasar el ratón o fijo) para que no haya dudas.
- Lo que abre cada objeto (selección de nivel, Navedex, stats, opciones) sigue funcionando igual. Sus paneles pueden seguir siendo los mismos paneles holograma; este ticket no los rediseña.
- El salto al hiperespacio al entrar en un nivel y la vuelta desde un nivel (`start_on_level_selection`) siguen funcionando.
- Estilo: tiene que ser coherente con el de los niveles, que es el más definitivo (paleta, contorno, luz, tablets de las barras, paneles holograma, ver docs/design/art.md y ui.md). Coherencia, no copia: se pueden hacer sprites y piezas nuevas. Pixel art 16x16 de base, sin antialiasing. Si los sprites se generan con un script (como `make_menu_background.gd`), dejarlo en `scripts/tools/`.
- No toca la pantalla de inicio ni las ranuras (eso es `pantalla-inicio-ranuras`, en `StartScreen`).

## Qué leer
- docs/design/menu.md › "Escena y script", "Comportamiento", "Fondo", "Decoración" y "Salto al hiperespacio"
- docs/design/art.md
- docs/design/ui.md › "Barras: tablet física", "Botones" y "OverlayScreen" (`OverlayFrame`)
- scenes/MainMenu.tscn y scripts/screens/MainMenu.gd

## Archivos que toca
- scenes/MainMenu.tscn
- scripts/screens/MainMenu.gd
- scripts/main_menu/ (scripts nuevos de los objetos de la oficina)
- scripts/tools/ (generador de sprites, si se usa)
- assets/sprites/ o assets/ui/ (sprites de la oficina)
- docs/design/menu.md, docs/design/art.md si añade sprites

## Cómo se prueba a mano
1. F5 y llegar al menú: se ve la oficina, con el escritorio delante y el espacio por el ventanal, con la decoración moviéndose.
2. Pasar el ratón por cada objeto: se resalta y se ve qué hace.
3. Tablet → Navedex; mural → estadísticas; objeto de Jugar → selección de nivel; objeto de Opciones → opciones; "Volver" en cada uno regresa a la oficina.
4. Entrar en un nivel (salto al hiperespacio), salir con "Menú": vuelve a la selección de nivel.
5. Puerta → se cierra el juego.
