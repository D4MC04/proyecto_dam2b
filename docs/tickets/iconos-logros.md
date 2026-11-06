# Mejorar los iconos de los logros

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Algunos iconos de los logros no se entienden o se ven pobres.

## Qué hay que hacer
- **Antes de tocar nada**, enseñar al usuario todos los iconos actuales (medallas de la vitrina y los de `assets/ui/achievements/`) y preguntar cuáles le gustan y cuáles no. El usuario dirá cuáles están mal y cómo mejorarlos.
- Rehacer solo los que diga el usuario, como él diga, con el método de la oficina (los de las medallas, en `gen_right.py`; volver a generar con `make_office.py`).
- Los iconos tienen que funcionar en los tres colores de fase (bronce, plata y oro, ver `logros-tres-fases`).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/art.md › "Oficina del menú"
- docs/design/menu.md › "Logros" y la fila `MedalCase` de "Oficina"
- scripts/tools/office/gen_right.py (medallas)

## Archivos que toca
- scripts/tools/office/gen_right.py
- assets/sprites/office/medal_*.png (generados)
- scripts/main_menu/OfficeLayout.gd (generado)
- assets/ui/achievements/*.png
- docs/design/art.md

## Cómo se prueba a mano
1. Entrar a la oficina y girar a la vitrina.
2. Los iconos que pidió el usuario se ven cambiados, en sus tres colores de fase.
