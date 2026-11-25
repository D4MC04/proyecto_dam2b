---
name: ideas
description: Propone 3-5 tickets nuevos para Astro Artillery y los escribe en docs/tickets/ con Estado propuesta. Usar cuando el usuario pida ideas, propuestas o "qué hacemos ahora".
model: opus
disable-model-invocation: true
argument-hint: "[tema opcional, p. ej. enemigos o UI]"
---

Propón tickets nuevos para el proyecto. Tema pedido (puede estar vacío): $ARGUMENTS

1. `docs/DESIGN.md` ya está cargado (por CLAUDE.md): mira su sección "Decidido". De `docs/design/` no leas archivos enteros (algunos son muy largos): saca sus títulos con Grep (`^#`) y lee solo el apartado que toque, con offset y limit. Si hay tema, solo el `docs/design/` de ese tema.
2. Mira los tickets que ya hay en `docs/tickets/*/` (una carpeta por creador) para no repetirlos.
3. Mira el código y las escenas relacionadas para saber qué está hecho y qué falta o está roto: busca con Grep y lee solo los trozos que hagan falta, no archivos enteros.
4. Escribe de 3 a 5 tickets en `docs/tickets/<creador>/nombre-en-kebab-case.md` (crea la carpeta si no existe) copiando el formato de `docs/tickets/_plantilla.md`, con `Estado: propuesta`.

Reglas:
- Cada ticket cabe en una sesión: pocos archivos, un objetivo claro, algo que se pueda probar a mano en el juego.
- Ninguno contradice "Decidido". Si una idea buena lo contradice, no la escribas: menciónala al usuario aparte.
- Pon el modelo recomendado y el esfuerzo recomendado (`low`, `medium`, `high`, `xhigh` o `max`) según `docs/CLAUDE-CODE.md` (haiku mecánico, sonnet normal, opus varios sistemas o diseño).
- Rellena "Qué leer" con lo que ya has mirado: las secciones de `docs/design/` (archivo › título) y las funciones o nodos concretos. Así `/work` no tiene que volver a buscarlo.
- Pon `Prioridad` (alta, media o baja).
- El creador es la variable de entorno `AUTHOR` (`echo "$AUTHOR"`, junto con otro comando): no preguntes quién eres. Si está vacía, pregunta una vez con AskUserQuestion (Renzo, David, Ezequiel) y explica en una línea cómo ponerla (`"AUTHOR": "tu-nombre"` en el `"env"` de `.claude/settings.local.json`, junto a `GODOT`; ver `docs/CLAUDE-CODE.md`). No lo deduzcas del usuario de git ni del correo.
- No toques código ni otros archivos. Solo crear tickets.

Al acabar, da al usuario una lista de una línea por ticket (nombre del archivo + qué aporta) y termina con las casillas de `.claude/skills/accept/SKILL.md`.
