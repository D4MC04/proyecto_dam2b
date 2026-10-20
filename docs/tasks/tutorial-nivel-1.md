# Tutorial en el nivel 1

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Quien abre el juego por primera vez no sabe que hay que elegir una torre en la barra, colocarla en un planeta y lanzar la oleada, ni que se pueden fusionar o vender. Un tutorial corto lo enseña jugando.

## Qué hay que hacer
- Solo en el nivel 1 y solo la primera vez (se guarda que ya se hizo; "Borrar progreso" lo vuelve a activar).
- Mensajes cortos, uno cada vez, en un recuadro con el estilo de la UI (sin tapar el mapa entero), que avanzan cuando el jugador hace lo que piden:
  1. "Elige una torre en la barra de la derecha" → al seleccionar torre.
  2. "Colócala en un planeta" → al colocarla.
  3. "Pulsa Siguiente oleada" → al empezar la oleada.
  4. Al acabar la oleada 1: "Clic en una torre para ver su ficha. Con la misma torre seleccionada en la tienda, clic encima para fusionarla" → se cierra con un clic o tras unos segundos.
  5. Si ya existen los poderes (`poderes-jugador`), uno más que los presenta.
- Botón "Saltar" en el recuadro que lo termina.
- Una flecha o un borde que parpadea señalando lo que hay que pulsar, si es sencillo.
- Actualizar docs/design/ui.md (y flujo.md por lo que se guarda).

## Archivos que toca
- scripts/level_ui/TutorialHints.gd (nuevo)
- scripts/level_ui/LevelUI.gd + scenes/ de LevelUI (recuadro)
- scripts/autoloads/Settings.gd o GameState.gd (guardar que se hizo; ver con cuál no choca)
- docs/design/ui.md, docs/design/flujo.md

## Cómo se prueba a mano
1. Opciones → Borrar progreso. F5, nivel 1.
2. Sale "Elige una torre…"; al elegirla cambia a "Colócala…"; al colocarla, "Pulsa Siguiente oleada"; al lanzarla desaparece.
3. Al acabar la oleada 1 sale el mensaje de ficha y fusión.
4. Reiniciar el nivel 1: ya no sale. Borrar progreso: vuelve a salir.
5. "Saltar" lo cierra del todo.
