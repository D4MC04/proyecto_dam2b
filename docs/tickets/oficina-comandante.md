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
  - Cada objeto debe entenderse sin texto, pero con un rótulo pequeño (al pasar el ratón o fijo) para que no haya dudas.

### Decidido por el usuario
- **"Jugar" pasa a llamarse "Sectores".** Más adelante su pantalla de selección será un radar que detecta dónde hay enemigos, pero eso lo está haciendo un compañero y se juntará después. **En este ticket la selección de sector sigue siendo el panel genérico de ahora** (`LevelSelectionScreen`); solo cambian el nombre y el objeto de la oficina que la abre, que debe encajar con la idea del radar (por ejemplo, una consola o pantalla de radar).
- **"Salir" → una puerta automática tecnológica**, de las robóticas que se abren solas (deslizante, por segmentos o similar), nada de puerta genérica de madera. Una trampilla vale como alternativa si la puerta no encaja en la composición.
- **Logros fuera de la Navedex → un mural con medallas** en la pared. Quitar la pestaña LOGROS de la Navedex y que el mural abra los logros. Es buena idea que el mural enseñe ya las medallas de los logros conseguidos. Ojo: el ticket `logros-progreso` toca la lista de logros de `Navedex.gd`; si ya está en main, mover también su contador "340/1000".
- **"Archivo" (Navedex: naves y torretas) → una tablet** sobre el escritorio. El usuario pensó en un libro, pero desentona con la estética. Solo se cambia la tablet por otra cosa si hay una idea claramente mejor, o un libro que encaje en lo tecnológico (por ejemplo, un códice holográfico); en ese caso, preguntar al usuario antes.

### Idea del usuario: girar en la silla (a valorar, le gusta)
Se puede hacer algo creativo en vez de meterlo todo en una sola pantalla:
- **Vista central (la de entrada):** sentado en el escritorio, mirando al escritorio y al ventanal gigante. Sobre el escritorio están la tablet de la Navedex y una pantalla grande con el radar de Sectores.
- **Girarse a izquierda o derecha** (flechas en los bordes, teclas o ratón al borde; elegir lo más claro) cambia a una vista lateral con un paso de cámara suave, como si girara la silla. En un lado, el mural de condecoraciones (logros) y alguna cosa más; en el otro, los stats u otro elemento.
- **La puerta:** no pega en la vista central, porque da al ventanal, y obligar a girarse para salir del juego es poco intuitivo. Propuesta: la puerta va en una de las vistas laterales (o detrás), y además Escape abre un "¿Salir del juego?" desde cualquier vista, que es lo que usará casi todo el mundo. Si se encuentra algo mejor, proponerlo.
- Si se hace con vistas, el reparto de objetos de "Sin decidir" se piensa junto con qué va en cada lado.

### Sin decidir
- **"Stats" y "Opciones"**: aún no hay objeto. No usar tablets para todo, porque queda genérico. Antes de hacerlos, proponer al usuario 2 o 3 ideas para cada uno (con AskUserQuestion) que encajen en una oficina de comandante, y hacer la que elija.

- Lo que abre cada objeto (selección de sector, Navedex, logros, stats, opciones) sigue funcionando igual. Sus paneles pueden seguir siendo los mismos paneles holograma; este ticket no los rediseña (salvo sacar los logros de la Navedex).
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
- scenes/Navedex.tscn, scripts/screens/Navedex.gd (sacar la pestaña LOGROS)
- scripts/main_menu/ (scripts nuevos de los objetos de la oficina)
- scripts/tools/ (generador de sprites, si se usa)
- assets/sprites/ o assets/ui/ (sprites de la oficina)
- docs/design/menu.md, docs/design/art.md si añade sprites

## Cómo se prueba a mano
1. F5 y llegar al menú: se ve la oficina, con el escritorio delante y el espacio por el ventanal, con la decoración moviéndose.
2. Pasar el ratón por cada objeto: se resalta y se ve qué hace.
3. Tablet → Navedex, ya sin pestaña LOGROS. Mural de medallas → logros. Objeto de Sectores → la selección de sector de siempre. Objetos de Stats y Opciones → sus paneles. "Volver" en cada uno regresa a la oficina.
4. Entrar en un nivel (salto al hiperespacio), salir con "Menú": vuelve a la selección de sector.
5. Puerta automática → se abre y se cierra el juego.
