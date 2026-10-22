---
name: check
description: Revisa la rama actual sin tocar nada: busca fallos, prueba en headless, mira si entra limpia en main y resume los cambios en lenguaje claro.
model: opus
disable-model-invocation: true
---

Revisa la rama actual frente a `origin/main`.

1. En un solo comando: `git fetch origin && git status --short && git diff origin/main...HEAD && git diff HEAD && git merge-tree --write-tree --name-only origin/main HEAD; echo "merge-tree: $?"` (lo commiteado, lo no commiteado y conflictos con main a la vez).
2. Busca fallos reales: lógica rota, referencias en .tscn/.tres que no se actualizaron al renombrar, uid= o ids de ext_resource cambiados, tile_map_data escrito a mano, reglas de CLAUDE.md incumplidas.
3. Lanza el agente `probador`.
4. Comprueba que el docs/design afectado está actualizado y que el ticket se borró.
5. Conflictos con main, del paso 1 (merge-tree no toca archivos; solo mira lo commiteado). Código 0: entra limpio. Código 1: lista los archivos en conflicto.

Devuelve:
- Resumen de qué cambia la rama, para alguien que está aprendiendo (sin jerga).
- Lista de problemas encontrados (archivo:línea y por qué), o "sin problemas".
- Resultado del probador.
- Main: entra limpio, o los archivos en conflicto.
- Siguiente paso: `/ship`, o qué arreglar antes.

No arregles nada sin preguntar.
