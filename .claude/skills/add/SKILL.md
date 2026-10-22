---
name: add
description: Convierte las ideas del usuario (arreglos o cosas nuevas) en tickets de docs/tasks/ con Estado propuesta, listos para aceptar.
disable-model-invocation: true
argument-hint: "idea 1; idea 2; ..."
---

Crea tickets con las ideas del usuario: $ARGUMENTS

1. Separa las ideas (por `;`, líneas o números). Si no hay ninguna, pregunta qué quiere. Una idea que no cabe en una sesión se parte en varios tickets; dos ideas pequeñas que tocan lo mismo pueden ir juntas.
2. Mira los tickets que ya hay en `docs/tasks/` para no repetirlos (si ya existe, dilo en vez de duplicarlo).
3. Comprueba la sección "Decidido" de `docs/DESIGN.md`. Si una idea la contradice, no escribas su ticket: avisa al usuario y sigue con las demás.
4. Busca en el código dónde está lo que hay que cambiar (Grep y trozos, no archivos enteros), solo lo justo para rellenar "Qué hay que hacer" y "Archivos que toca". Si una idea es tan vaga que no sabes qué cambiar, pregunta con AskUserQuestion en vez de adivinar.
5. Escribe cada ticket en `docs/tasks/nombre-en-kebab-case.md` con el formato de `docs/tasks/_plantilla.md` y `Estado: propuesta`. Respeta lo que pidió el usuario: no añadas extras. Modelo y esfuerzo según `docs/CLAUDE-CODE.md`.
6. No toques código ni otros archivos.

Al acabar, una línea por ticket (archivo + qué arregla) y termina con las casillas para aceptar (ver "Casillas para aceptar" en CLAUDE.md).
