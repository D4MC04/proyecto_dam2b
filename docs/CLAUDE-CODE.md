# Cómo trabajar con Claude Code en este proyecto

## El ciclo
| Paso | Tú | Claude |
|---|---|---|
| 1 | Escribes `/proponer` (o `/proponer enemigos`) | Escribe 3-5 tickets en `docs/tasks/` con `Estado: propuesta` |
| 2 | Lees los tickets (`/tickets` te los lista y dice cuáles chocan). Aceptas marcando las casillas que te salen al final (o dices "acepto X"). Borras los que no quieras | — |
| 3 | Escribes `/hacer nombre-del-ticket` | Crea la rama `ticket/nombre`, implementa, lo prueba con el agente `probador`, actualiza docs, borra el ticket y te da pasos para probar |
| 4 | Pruebas en Godot con esos pasos | Si algo falla, se lo dices en el mismo chat y lo arregla |
| 5 | Escribes `/revisar` | Repasa la rama y te explica qué cambia |
| 6 | Dices "commitea" | Hace el commit, sube la rama y te pregunta: ¿PR (tus compañeros lo revisan) o merge directo a main? Hace lo que elijas |
| 7 | Lo pruebas en tu carpeta normal y dices que va bien | Te pregunta si archiva el chat del ticket, para no acumular chats abiertos. Archivar no borra nada del proyecto y el chat se puede recuperar desde Archivados |

Ir más rápido: con varios tickets aceptados que no chocan (`/tickets` lo dice), súbelos a main y pide "abre sesiones en worktree para X e Y": un chat por ticket, cada uno en su copia del proyecto. En cada uno, `/hacer`. Los worktrees salen de lo commiteado en main: tickets sin commitear no los ven.

Los tickets siguen el formato de `docs/tasks/_plantilla.md`. Puedes escribir tú uno a mano y lanzar `/hacer` igual.

## Qué modelo usar
Se cambia en el selector de modelo de la app.

| Modelo | Cuándo |
|---|---|
| **Haiku** | Preguntas rápidas ("¿dónde se define X?"), probar el proyecto, renombres o cambios mecánicos. Barato y rápido. |
| **Sonnet** | Por defecto para `/hacer`: tickets normales de 1-3 archivos (una torre nueva, un ajuste de UI, un enemigo). |
| **Opus** | `/proponer` y `/revisar` (ya lo usan solos), diseñar un sistema nuevo, bugs que Sonnet no saca a la primera, tickets que tocan varios sistemas. |

Regla simple: empieza en Sonnet. Si da vueltas o falla dos veces, sube a Opus. Si es algo mecánico, baja a Haiku. Cada ticket lleva un "Modelo recomendado".

## Trucos
- **Plan mode** para tickets grandes: Claude piensa y te enseña el plan antes de tocar nada.
- **Una sesión por ticket**: no mezcles temas en el mismo chat. Si sigues en el mismo, `/clear` entre tickets.
- **Cierra Godot** antes de que Claude renombre o mueva archivos: si no, el editor reasigna UIDs.
- **Al cambiar de rama**, borra la carpeta `.godot` antes de abrir el editor.
- El contexto que comparten todos los agentes y sesiones es `CLAUDE.md` + `docs/`. Si algo cambia en el diseño, que quede escrito ahí.

## Git en 5 líneas
- **Rama**: una copia del proyecto donde trabajar sin tocar `main`. Cada ticket va en la suya.
- **Commit**: guardar un punto de los cambios en la rama, con un mensaje.
- **Push**: subir la rama a GitHub.
- **Pull request (PR)**: pedir que la rama entre en `main`; los compañeros la revisan antes.
- **Merge directo**: juntar la rama con `main` sin PR, sin revisión.
- Nunca se trabaja directamente en `main`: siempre en una rama. Al terminar, Claude pregunta si PR o merge directo.
