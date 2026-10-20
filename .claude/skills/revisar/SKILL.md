---
name: revisar
description: Revisa la rama actual antes de abrir el PR: busca fallos, prueba en headless y resume los cambios en lenguaje claro.
model: opus
disable-model-invocation: true
---

Revisa la rama actual frente a `main` antes del PR.

1. Mira los cambios con `git diff main...HEAD` y `git status` (incluye lo no commiteado).
2. Busca fallos reales: lógica rota, referencias en .tscn/.tres que no se actualizaron al renombrar, uid= o ids de ext_resource cambiados, tile_map_data escrito a mano, reglas de CLAUDE.md incumplidas.
3. Lanza el agente `probador`.
4. Comprueba que el docs/design afectado está actualizado y que el ticket se borró.

Devuelve:
- Resumen de qué cambia la rama, para alguien que está aprendiendo (sin jerga).
- Lista de problemas encontrados (archivo:línea y por qué), o "sin problemas".
- Resultado del probador.

No arregles nada sin preguntar.
