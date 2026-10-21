# Unificar el fundido de pantalla

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
El fundido está escrito dos veces: `MainMenu._transition` y `OptionsMenu._fade` (Dudas de menu.md).

## Qué hay que hacer
- Sacar una función común (en un autoload o un script estático) y usarla en los dos sitios.
- Quitar la Duda.

## Archivos que toca
- scripts/screens/MainMenu.gd
- scripts/screens/OptionsMenu.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. Entrar y salir de Opciones y elegir nivel: el fundido se ve igual que antes.
