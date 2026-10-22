# Cómo trabajar con Claude Code en este proyecto

## Preparar tu equipo (una vez)
El agente `probador` abre Godot en headless y necesita saber dónde está. Pon la ruta en tu `.claude/settings.local.json` (no se sube al repo, es solo tuyo):

```json
{
  "env": {
    "GODOT": "C:/Users/tu-usuario/ruta/a/Godot.exe"
  }
}
```

Si el archivo ya existe, añade solo el bloque `"env"`. Vale para los chats que abras después de guardarlo.

## Los comandos
| Comando | Qué hace |
|---|---|
| `/add idea 1; idea 2` | Convierte **tus** ideas (arreglos o cosas nuevas) en tickets |
| `/ideas [tema]` | Claude **propone** 3-5 tickets (opcional: sobre un tema) |
| `/board` | Tablero: lista los tickets, dice cuáles chocan (tocan los mismos archivos) y en qué tandas hacerlos |
| `/work nombre` | Implementa el ticket en su rama, lo prueba y te da pasos para probarlo en Godot |
| `/check` | Revisa la rama sin tocar nada y te explica qué cambia |
| `/ship` | Revisa la rama y, si está bien, la commitea, la sube a main y la borra |
| `/hub` | Abre el chat central (solo en la app de escritorio) |

Los nombres antiguos (`/proponer`, `/tickets`, `/hacer`, `/revisar`, `/new`) siguen funcionando un tiempo como alias.

## El ciclo
| Paso | Tú | Claude |
|---|---|---|
| 1 | `/add` con lo que quieres arreglar, o `/ideas` si quieres propuestas | Escribe los tickets en `docs/tasks/` con `Estado: propuesta` |
| 2 | Marcas las casillas de los que aceptas (o dices "acepto X"). `/board` te los lista cuando quieras. Borras los que no quieras | Cambia `Estado:` a `aceptada` y empieza (ver abajo) |
| 3 | `/work nombre` (si no lo lanzó ya el chat central) | Crea la rama `ticket/nombre`, implementa, lo prueba con el `probador`, actualiza docs, borra el ticket y te da pasos para probar |
| 4 | Pruebas en Godot con esos pasos | Si algo falla, se lo dices en el mismo chat y lo arregla |
| 5 | `/ship` | Revisa la rama. Si encuentra problemas, para y te los enseña. Si no, commitea, sube directo a main y borra la rama. Solo hace PR si lo pides |
| 6 | — (no haces `git pull`) | El chat central deja tu `main` local al día y borra todo lo del ticket: archiva su chat (se puede recuperar desde Archivados), quita su worktree y su rama. Si Godot está abierto en esa carpeta, ciérralo |

Decir "commitea" o "sube" ya no sube nada: para eso está `/ship`, así no se sube a main sin querer.

**Varios tickets a la vez** (app de escritorio): al aceptar, Claude sube el cambio de `Estado:` a main (los worktrees salen de lo que hay en main) y abre un chat con worktree por cada ticket que no choque con otro, ya con `/work`. Los que chocan esperan a que el anterior esté en main. En la extensión de VS Code no se pueden abrir chats solos: lanza tú `/work` en cada chat.

**`/hub`**: abre el chat central (Opus, en la carpeta principal, sobre `main`) y borra el chat donde lo escribiste (la app te pide confirmar el borrado). El chat central reparte tickets, recibe los avisos de subida y mantiene `main` local actualizado. Los chats de ticket van en worktree y no pueden tocar la carpeta principal, por eso lo hace él. Con `/ship todo`, sube él mismo todos los tickets listos.

Los tickets siguen el formato de `docs/tasks/_plantilla.md`. Puedes escribir tú uno a mano y lanzar `/work` igual.

## Qué modelo usar
Se cambia en el selector de modelo de la app. Algunos comandos fijan el suyo y lo usan aunque el chat esté en otro: `/ideas`, `/check` y `/ship` van en Opus; `/board`, `/hub` y el `probador`, en Haiku. `/add` y `/work` usan el del chat.

| Modelo | Cuándo |
|---|---|
| **Haiku** | Preguntas rápidas ("¿dónde se define X?"), renombres o cambios mecánicos. Barato y rápido. |
| **Sonnet** | Por defecto para `/work` y `/add`: tickets normales de 1-3 archivos (una torre nueva, un ajuste de UI, un enemigo). |
| **Opus** | Diseñar un sistema nuevo, bugs que Sonnet no saca a la primera, tickets que tocan varios sistemas. |

Regla simple: empieza en Sonnet. Si da vueltas o falla dos veces, sube a Opus. Si es algo mecánico, baja a Haiku. Cada ticket lleva un "Modelo recomendado" y un "Esfuerzo recomendado".

## Qué esfuerzo usar
Es cuánto piensa el modelo antes de responder (se elige junto al modelo; ningún comando lo fija).

| Esfuerzo | Cuándo |
|---|---|
| `low` | Cambios mecánicos o de una línea: renombres, borrar código muerto, mover un botón. |
| `medium` | Por defecto: tickets normales de 1-3 archivos. |
| `high` | Varios sistemas a la vez o lógica delicada (fusionar, guardado, oleadas). |
| `xhigh` / `max` | Solo si algo falló con `high`. Más lento y más caro. |

## Crear comandos
Cada comando es un archivo `.claude/skills/nombre/SKILL.md` con instrucciones. Pídeselo a Claude ("crea un comando `/x` que haga...") o copia uno de los que hay.

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
- Nunca se trabaja directamente en `main`: siempre en una rama. `/ship` sube directo a main (PR solo si lo pides), borra la rama y deja tu carpeta con solo `main`, sin que hagas `git pull`.
