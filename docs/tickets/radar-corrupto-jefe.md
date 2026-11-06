# Radar corrupto para el nivel de la Reina Colmena

Creador: Renzo
Responsable: Renzo
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El nivel del jefe final tiene que sentirse distinto antes de entrar: al desbloquearlo, el radar se rompe y deja claro que algo grande se acerca.

Depende del ticket `radar-sectores` y de que exista el nivel del jefe (Reina Colmena, futuro nivel 10).

## Qué hay que hacer
Seguir el modo corrupto del boceto `docs/bocetos/radar-sectores.html` (para verlo, mover la barra a 9 y a 10/10).

- Contacto del jefe siempre arriba en el centro, con la nave Reina del boceto (`PATTERNS.boss`) unas tres veces más grande que las demás y en rojo, también al seleccionarla. Su sprite lo genera el mismo script de `scripts/tools/` del ticket `radar-sectores`.
- Mientras esté desbloqueado y sin ganar:
  - El contacto aparece y desaparece con glitch.
  - Todo el radar se corrompe: barrido rojo a tirones, franjas desplazadas, ruido, viñeta roja que late y ondas rojas que salen de la Colmena.
  - Los demás contactos y los textos de km desaparecen.
  - El título y el subtítulo se corrompen.
  - La ficha muestra datos rotos, "⚠ NUEVO CONTACTO / SIN IDENTIFICAR" y un mensaje interceptado que se escribe letra a letra (el `BOSS_LOG` del boceto).
- Al ganar ese nivel, todo vuelve a la normalidad.
- Textos nuevos con claves en `translations/textos.csv` (es y en).
- No tocar nada de `scenes/maps/`.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › la sección del radar que añade el ticket `radar-sectores`, "Idiomas"
- docs/design/art.md › "Paleta"
- Los scripts del radar y de la ficha que crea el ticket `radar-sectores` (en scripts/level_ui/)
- scripts/autoloads/GameState.gd › `current_level` y la función de estrellas

## Archivos que toca
- scripts/level_ui/ (radar y ficha)
- scripts/screens/MainMenu.gd y scenes/MainMenu.tscn (título y subtítulo)
- scripts/tools/ (sprite de la Reina)
- assets/sprites/ (sprite generado)
- resources/level_data/ (datos de radar del nivel del jefe)
- translations/textos.csv
- docs/design/menu.md

## Cómo se prueba a mano
1. Con una ranura que tenga el nivel del jefe desbloqueado y sin ganar, pulsar "Jugar".
2. Debería verse el radar corrupto: barrido rojo a tirones, franjas, ruido, viñeta roja latiendo y ondas desde la Colmena arriba en el centro; sin otros contactos ni textos de km; título y subtítulo rotos.
3. Seleccionar la Colmena: grande y en rojo; la ficha con datos rotos, "⚠ NUEVO CONTACTO / SIN IDENTIFICAR" y el mensaje escribiéndose letra a letra.
4. Ganar el nivel del jefe y volver al menú: el radar vuelve a la normalidad.
