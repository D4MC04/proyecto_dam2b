---
name: proponer
description: Propone 3-5 tickets nuevos para Astro Artillery y los escribe en docs/tasks/ con Estado propuesta. Usar cuando el usuario pida ideas, propuestas o "qué hacemos ahora".
model: opus
disable-model-invocation: true
argument-hint: "[tema opcional, p. ej. enemigos o UI]"
---

Propón tickets nuevos para el proyecto. Tema pedido (puede estar vacío): $ARGUMENTS

1. `docs/DESIGN.md` ya está cargado (por CLAUDE.md): mira su sección "Decidido". De `docs/design/` no leas archivos enteros (algunos son muy largos): saca sus títulos con Grep (`^#`) y lee solo el apartado que toque, con offset y limit. Si hay tema, solo el `docs/design/` de ese tema.
2. Mira los tickets que ya hay en `docs/tasks/` para no repetirlos.
3. Mira el código y las escenas relacionadas para saber qué está hecho y qué falta o está roto: busca con Grep y lee solo los trozos que hagan falta, no archivos enteros.
4. Escribe de 3 a 5 tickets en `docs/tasks/nombre-en-kebab-case.md` copiando el formato de `docs/tasks/_plantilla.md`, con `Estado: propuesta`.

Reglas:
- Cada ticket cabe en una sesión: pocos archivos, un objetivo claro, algo que se pueda probar a mano en el juego.
- Ninguno contradice "Decidido". Si una idea buena lo contradice, no la escribas: menciónala al usuario aparte.
- Pon el modelo recomendado y el esfuerzo recomendado (`low`, `medium`, `high`, `xhigh` o `max`) según `docs/CLAUDE-CODE.md` (haiku mecánico, sonnet normal, opus varios sistemas o diseño).
- No toques código ni otros archivos. Solo crear tickets.

Al acabar, da al usuario una lista de una línea por ticket (nombre del archivo + qué aporta).

## Aceptar con casillas
Si hay tickets en `Estado: propuesta`, termina con la herramienta AskUserQuestion en modo multiSelect para que el usuario los marque con un clic:
- Una opción por ticket propuesto. Etiqueta: el nombre del ticket. Descripción: qué aporta en una frase, el modelo, el esfuerzo y su tanda.
- Máximo 4 opciones por pregunta: si hay más tickets, usa varias preguntas (hasta 4) agrupadas por tanda.
- Los que marque pasan a `Estado: aceptada` (solo cambias esa línea). Los no marcados se quedan como están.
- Si marca alguno, no preguntes más: sigue "Aceptar es la orden de empezar" de CLAUDE.md (subir el `Estado:` a main y abrir ya los chats con worktree).
