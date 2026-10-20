# Mostrar la vida de la estación en la interfaz

Estado: propuesta
Modelo recomendado: sonnet

## Por qué
Ahora la vida de la estación no se ve en ningún sitio: solo se nota por la fase de daño del sprite (docs/design/ui.md y base.md, "Dudas"). El jugador no sabe cuánto le queda antes de perder.

## Qué hay que hacer
- Añadir a la barra derecha (`Sidebar`) una fila "ESTACIÓN" con una barra y el número `actual/máximo`, con el estilo de holograma que ya usa la UI.
- Conectarla a la señal `Base.health_changed(current, maximum)`, que ya existe pero nadie escucha. Poner el valor inicial al montar el nivel y al reiniciar o pasar al siguiente nivel.
- Si la vida baja del 30 %, la barra cambia al color de peligro de la paleta de la UI.
- Actualizar docs/design/ui.md y docs/design/base.md (quitar esas dudas).

## Archivos que toca
- scripts/level_ui/Sidebar.gd
- scenes/level_ui/Sidebar.tscn
- scripts/level_ui/LevelUI.gd
- docs/design/ui.md, docs/design/base.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn`, darle a jugar y entrar al nivel 1.
2. En la barra derecha se ve "ESTACIÓN" con la vida llena.
3. Lanzar oleadas sin poner torres: la barra baja cada vez que un enemigo llega al final, y se pone del color de peligro al bajar del 30 %.
4. Pausa → Reiniciar: la barra vuelve a estar llena.
