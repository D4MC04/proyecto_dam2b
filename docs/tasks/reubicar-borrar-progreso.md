# Reubicar el botón "Borrar progreso" en Opciones

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Ahora "Borrar progreso" está en la rejilla de `// JUEGO`, al lado de los interruptores ON/OFF y con su mismo aspecto, aunque es una acción destructiva que no se puede deshacer. Además, al pedir confirmación el botón cambia a "¿Seguro? Pulsa otra vez", se estira para que quepa el texto y el panel de Opciones entero se ensancha y se recoloca durante 3 s.

## Qué hay que hacer
- Sacar `ResetProgressLabel` y `ResetProgressButton` de `GameGrid`. El botón pasa a ser un control propio, centrado, debajo de las dos columnas (`Sections`) y encima de "Volver", separado de los ajustes normales. El texto del botón ya dice lo que hace ("Borrar progreso"), así que la etiqueta aparte sobra.
- Estilo de peligro: nueva variación de tema `DangerButton` en `assets/ui/menu_theme.tres`, con las mismas esquinas recortadas (`ClippedBox`) que el resto de botones del tema pero con el rojo de peligro: borde y texto `#ff3c5a`, y al pasar el ratón relleno rojo con texto claro `#ffaabe` (ver la paleta del panel holograma en docs/design/art.md). Texto a 24 px como el resto de Opciones.
- Mantener la confirmación de dos pulsaciones (`_confirming_reset`, `CONFIRM_TIME` de 3 s), pero:
  - el botón tiene un ancho fijo (`custom_minimum_size`) en el que quepan los dos textos, para que ni el botón ni el panel cambien de tamaño;
  - el texto de confirmación es corto ("¿Seguro?") y, mientras se espera la segunda pulsación, el botón se ve relleno de rojo (como en hover) para que se note que está "armado".
- `OptionsMenu.tscn` también se abre desde el menú de pausa: ocultar el botón cuando Opciones se abre desde la pausa, porque borrar el progreso a mitad de un nivel no tiene sentido. Basta con saber desde qué panel se abrió en `open_from(opener)` o con una propiedad que ponga el menú de pausa.
- Actualizar docs/design/menu.md (tabla de Opciones y párrafo de "Borrar progreso") y, si cambia la paleta de botones del tema, docs/design/art.md.

## Archivos que toca
- scenes/OptionsMenu.tscn
- scripts/screens/OptionsMenu.gd
- assets/ui/menu_theme.tres
- docs/design/menu.md, docs/design/art.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` (F5) y entrar en Opciones.
2. Debajo de las columnas AUDIO / PANTALLA / JUEGO, encima de "Volver", sale el botón rojo "Borrar progreso", distinto de los interruptores ON/OFF.
3. Pulsarlo una vez: pasa a "¿Seguro?" relleno de rojo y el panel no cambia de tamaño. Esperar 3 s: vuelve a "Borrar progreso".
4. Pulsarlo dos veces seguidas, volver y entrar en Jugar: solo está desbloqueado el nivel 1.
5. Entrar en un nivel, pausar (Esc) y abrir Opciones: el botón no sale.
