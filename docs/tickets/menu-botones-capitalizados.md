# Botones Archivo y Estadísticas capitalizados

Estado: aceptada
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
En el título, "ARCHIVO" y "ESTADÍSTICAS" van en mayúsculas mientras "Jugar", "Opciones" y "Salir" van capitalizados; desentonan.

## Qué hay que hacer
- En `scenes/MainMenu.tscn`, cambiar el `text` de los botones "ARCHIVO" y "ESTADÍSTICAS" a "Archivo" y "Estadísticas".
- No tocar los títulos de los paneles (`title = "ARCHIVO"`, `title = "ESTADÍSTICAS"`): todos los paneles van en mayúsculas.
- Si ya está hecho `idioma-ingles`, cambiar el texto en `translations/textos.csv` (en los dos idiomas) en vez de en la escena.

## Archivos que toca
- scenes/MainMenu.tscn (o translations/textos.csv)
- docs/design/menu.md

## Cómo se prueba a mano
1. Lanzar el juego (F5).
2. En el título, los cinco botones deberían ir igual: "Jugar", "Archivo", "Estadísticas", "Opciones", "Salir".
