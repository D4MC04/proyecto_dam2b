---
name: fix
description: Arregla lo que falla al probar un ticket en Godot, en la misma rama, lo guarda con /commit y reabre Godot para volver a probar.
disable-model-invocation: true
argument-hint: "qué falla"
---

Arregla lo que el usuario vio al probar: $ARGUMENTS

1. `git rev-parse --abbrev-ref HEAD`. Si es `main`, para: los arreglos van en la rama del ticket. Si no dice qué falla, pregúntalo.
2. Busca el sitio con Grep y lee solo los trozos que hagan falta (lo que ya leíste en este chat no lo releas). Arregla lo mínimo para lo que pide: no metas extras.
3. Si cambia algo del diseño, actualiza su sección en `docs/design/`.
4. Guarda con `/commit` (sigue `.claude/skills/commit/SKILL.md`; ya lanza el `probador`). Si se para por errores, arréglalos y repite.
5. Reabre Godot en la carpeta de este chat como el paso 6 de `.claude/skills/work/SKILL.md`.

Termina con qué has cambiado en 1-2 líneas, los pasos para volver a probarlo y: "Si ya va, `/ship`. Si no, otro `/fix`."
