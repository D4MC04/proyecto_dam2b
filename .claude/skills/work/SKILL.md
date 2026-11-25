---
name: work
description: Implementa un ticket aceptado de docs/tickets/, lo prueba en headless y deja pasos para probarlo a mano.
disable-model-invocation: true
argument-hint: "nombre-del-ticket"
---

Implementa el ticket `docs/tickets/$ARGUMENTS.md`.

1. Lee el ticket. Si no existe o no pone `Estado: aceptada`, para y díselo al usuario (si en este chat ha dicho "acepto $ARGUMENTS", cambia tú el estado a `aceptada` y sigue). Di en una línea quién lo creó y quién es el responsable (`Creador:` y `Responsable:`). Si lo lanzó el usuario a mano en este chat (no `/accept` ni el chat central, que ya lo preguntan), pregunta con AskUserQuestion si quiere continuar sabiéndolo.
2. Comprueba con `git status` que no hay cambios sin guardar de otra cosa. Si los hay, para y pregunta. Crea la rama `ticket/$ARGUMENTS` desde `main` (si ya existe, cámbiate a ella).
3. Comprueba que el ticket no contradice la sección "Decidido" de `docs/DESIGN.md`. Si contradice, para y avisa.
4. Lee solo lo que pone "Qué leer" del ticket. Nunca un `docs/design/` entero (algunos son enormes): saca sus títulos con Grep (`^#`) y lee la sección con offset y limit. De los scripts, la función o el trozo indicado, no el archivo entero si es largo. Si el ticket no tiene "Qué leer", busca con Grep y lee solo trozos. Implementa siguiendo CLAUDE.md.
5. Actualiza la sección afectada de `docs/design/` (y `docs/DESIGN.md` si cambia algo general), borra el archivo del ticket y guarda con `/commit` (sigue `.claude/skills/commit/SKILL.md`: ya lanza el `probador`, no lo lances aparte). Si se para por errores, arréglalos y repite `/commit`. Para lo que pida el usuario después, `/fix`.
6. Abre Godot con `/test` (sigue `.claude/skills/test/SKILL.md`), sin pedir nada al usuario: cierra el de esta carpeta y abre el editor y el juego ya en el punto donde se prueba este ticket. Haz lo mismo cada vez que cambies algo que el usuario tenga que volver a probar.
7. No subas nada. Termina con:
   - Qué has cambiado, en 2-3 líneas claras.
   - Qué ha abierto ya `/test` (por ejemplo "el juego en el nivel 3, oleada 5, con dinero de sobra") y los pasos para probarlo ahí: qué hacer y qué debería verse. Si `/test` dijo que algo no salió, dilo. Nada de rutas ni ramas: el usuario solo juega.
   - "Si te vale, escribe `/merge`: lo subo, abro el PR y lo fusiono en main. Si no, escribe `/fix` y qué falla."
