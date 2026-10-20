---
name: hacer
description: Implementa un ticket aceptado de docs/tasks/, lo prueba en headless y deja pasos para probarlo a mano.
disable-model-invocation: true
argument-hint: "nombre-del-ticket"
---

Implementa el ticket `docs/tasks/$ARGUMENTS.md`.

1. Lee el ticket. Si no existe o no pone `Estado: aceptada`, para y díselo al usuario (si en este chat ha dicho "acepto $ARGUMENTS", cambia tú el estado a `aceptada` y sigue).
2. Comprueba con `git status` que no hay cambios sin guardar de otra cosa. Si los hay, para y pregunta. Crea la rama `ticket/$ARGUMENTS` desde `main` (si ya existe, cámbiate a ella).
3. Comprueba que el ticket no contradice la sección "Decidido" de `docs/DESIGN.md`. Si contradice, para y avisa.
4. Lee solo el `docs/design/` que toque y los archivos que lista el ticket. Implementa siguiendo CLAUDE.md.
5. Lanza el agente `probador`. Si devuelve errores, arréglalos y vuelve a lanzarlo hasta que dé OK.
6. Actualiza el `docs/design/` afectado (y `docs/DESIGN.md` si cambia algo general) y borra el archivo del ticket.
7. No hagas commit. Termina con:
   - Qué has cambiado, en 2-3 líneas claras.
   - Los pasos para probarlo a mano en Godot (escena, qué hacer, qué debería verse).
   - "Si te vale, dime 'commitea' (o 'sube') y lo commiteo y lo subo directo a main. Si no, dime qué falla."
