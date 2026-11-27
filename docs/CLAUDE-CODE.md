# Cómo trabajar con Claude Code en este proyecto

## Preparar tu equipo (una vez)
El agente `probador` abre Godot en headless y necesita saber dónde está, y los comandos de tickets necesitan saber quién eres. Ponlo en tu `.claude/settings.local.json` (no se sube al repo, es solo tuyo):

```json
{
  "env": {
    "GODOT": "C:/Users/tu-usuario/ruta/a/Godot.exe",
    "AUTHOR": "tu-nombre"
  }
}
```

Si el archivo ya existe, añade solo el bloque `"env"`. Vale para los chats que abras después de guardarlo.

`AUTHOR` es tu nombre (Renzo, David o Ezequiel), escrito siempre igual: es el nombre de tu carpeta de tickets. `/add` e `/ideas` guardan los tickets que creas en `docs/tickets/<tu nombre>/` (la crean si no existe) sin preguntarte quién eres. Si no lo pones, te lo preguntan una vez y te recuerdan cómo ponerlo.

Si usas varias cuentas de GitHub en el equipo, añade también `"GH_USER": "tu-cuenta"` en ese `"env"`: `/merge` usará esa cuenta para los PR sin que tengas que cambiar la activa de `gh` (tienen que estar todas iniciadas con `gh auth login`). Y en el repo, para que commits y push vayan con esa cuenta:

```
git config user.name "tu-nombre"
git config user.email "tu-email"
git remote set-url origin https://tu-cuenta@github.com/D4MC04/proyecto_dam2b.git
```

## Los comandos
| Comando | Qué hace |
|---|---|
| `/add idea 1; idea 2` | Convierte **tus** ideas (arreglos o cosas nuevas) en tickets |
| `/ideas [tema]` | Claude **propone** 3-5 tickets (opcional: sobre un tema) |
| `/board [all]` | Tablero: lista tus tickets (`all`, o "todos" con tus palabras, para los de todos; "los de Renzo" para los de alguien), dice cuáles chocan (tocan los mismos archivos) y en qué tandas hacerlos |
| `/accept [nombres]` | Acepta tickets (con casillas si no dices cuáles) y abre un chat por ticket con `/work` |
| `/work nombre` | Implementa el ticket en su rama, lo prueba y te da pasos para probarlo en Godot |
| `/fix qué falla` | Arregla lo que viste mal al probar, en la misma rama, y reabre Godot con `/test` |
| `/test [qué probar]` | Abre el juego (sin editor) delante de todo, ya en el punto de prueba del cambio (un nivel, una oleada, con dinero de sobra, la oficina...). Cierra antes el de la carpeta del chat |
| `/check` | Revisa la rama sin tocar nada y te explica qué cambia |
| `/commit` | Revisa lo que no está commiteado, lo prueba y, si sale bien, hace un commit en la rama explicando el cambio. No sube nada |
| `/merge` | Lo lleva todo a main sin que revises nada: commitea lo pendiente, trae `main` y resuelve conflictos, sube la rama, abre el PR y lo fusiona (squash) |
| `/hub` | Abre el chat central (solo en la app de escritorio). Escrito en un central lleno, le hace el relevo |

## El ciclo
| Paso | Tú | Claude |
|---|---|---|
| 1 | `/add` con lo que quieres arreglar, o `/ideas` si quieres propuestas | Escribe los tickets en `docs/tickets/<tu nombre>/` con `Estado: propuesta` |
| 2 | Marcas las casillas de los que aceptas (o `/accept nombre`). `/board` te los lista por prioridad cuando quieras. Borras los que no quieras | Cambia `Estado:` a `aceptada` y abre un chat por ticket (ver abajo) |
| 3 | `/work nombre` (si no lo lanzó ya `/accept`) | Crea la rama `ticket/nombre`, lee solo lo que pone "Qué leer" del ticket, implementa, actualiza docs, borra el ticket, hace `/commit`, abre Godot con `/test` en el punto de prueba y te da pasos para probar |
| 4 | Pruebas en el juego que ya está abierto (si lo cerraste, `/test`) | Si algo falla, `/fix qué falla` en el chat de ese ticket: lo arregla, hace `/commit` y reabre Godot con `/test` |
| 5 | `/merge` | Commitea lo pendiente, trae `main`, resuelve conflictos, sube la rama, abre el PR y lo fusiona en main con squash (un commit por ticket). Te da el enlace del PR |
| 6 | — (no haces `git pull`) | Deja tu `main` local al día y borra la rama. En chats con worktree lo hace el chat central, que además archiva el chat del ticket (se puede recuperar desde Archivados) y quita su worktree. Si Godot está abierto en esa carpeta, ciérralo |

Si cambias algo a mano (en Godot o en el código), escribe `/commit` para guardarlo. Solo los comandos commitean o suben: decir "commitea", "sube" o "listo" no hace nada, así nada se guarda ni se sube sin querer.

**Conflictos en `/merge`**: se resuelven en la rama, así que `main` no se toca hasta que todo está resuelto y probado. Si los dos cambios se pueden sumar (textos, cosas distintas en la misma zona, escenas con cambios en nodos distintos o reordenadas por el editor), los combina solo. Si los dos cambiasteis la misma lógica o la misma propiedad del mismo nodo, o es una imagen o un audio, para, te enseña las dos versiones y te pregunta.

**Varios tickets a la vez** (app de escritorio): al aceptar, Claude sube el cambio de `Estado:` a main (los worktrees salen de lo que hay en main) y abre un chat con worktree por cada ticket que no choque con otro, ya con `/work`. Los que chocan quedan apuntados con `Espera a: otro` y, cuando ese otro hace `/merge`, su chat los lanza solo en chats nuevos, sin tarjetas ni preguntas. En la extensión de VS Code no se pueden abrir chats solos: lanza tú `/work` en cada chat.

**`/hub`**: abre el chat central (Opus high, en la carpeta principal, sobre `main`) y borra el chat donde lo escribiste (la app te pide confirmar el borrado). El chat central reparte tickets, recibe los avisos de subida y mantiene `main` local actualizado; no implementa. Los chats de ticket van en worktree y no pueden tocar la carpeta principal, por eso lo hace él. Con `/merge todo`, sube él mismo todos los tickets listos.

**¿Sigo en este chat o abro otro?** Cada mensaje envía una parte fija de unos 75k tokens (herramientas, conectores, skills, instrucciones), sea el chat nuevo o viejo, más todo el historial de ese chat. Un chat nuevo no paga más que uno viejo: solo pierde lo que el viejo ya había leído. Si el próximo ticket toca los mismos archivos y el chat aún es corto (menos de ~40k de mensajes), puede seguir ahí.
- Otro ticket u otro tema → chat nuevo.
- Mismo ticket y el chat va por menos de ~60k → sigue en él (lo que ya leyó le sirve).
- El chat central pasa de ~60k (él te avisa) → `/hub` ahí mismo: abre un central nuevo con un resumen de 10 líneas de los tickets en marcha y cierra el viejo. Es el **relevo**.

Los tickets siguen el formato de `docs/tickets/_plantilla.md` y van en la carpeta de su creador (`docs/tickets/<nombre>/`). Puedes escribir tú uno a mano y lanzar `/work nombre` igual: lo encuentra en cualquier carpeta.

## Qué modelo usar
Se cambia en el selector de modelo de la app. Algunos comandos fijan el suyo y lo usan aunque el chat esté en otro: `/ideas` y `/check` van en Opus; `/board`, `/accept` y el `probador`, en Haiku; `/hub` y el chat central que abre van en Opus con esfuerzo high. `/add`, `/work`, `/fix`, `/test`, `/commit` y `/merge` usan el del chat.

| Modelo | Cuándo |
|---|---|
| **Haiku** | Preguntas rápidas ("¿dónde se define X?"), renombres o cambios mecánicos. Barato y rápido. |
| **Sonnet** | Por defecto para `/work` y `/add`: tickets normales de 1-3 archivos (una torreta nueva, un ajuste de UI, un enemigo). |
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

## Panel de balanceo
- Abre `tools/balance/index.html` con doble clic en Chrome o Edge (sin servidor ni instalar nada), pulsa **Abrir proyecto** y elige la carpeta del juego.
- Enseña los stats de torretas y naves en tablas: se ordenan pulsando la cabecera, las celdas blancas se editan y las cian se calculan solas. Pasa el ratón por cabeceras y celdas para ver de dónde sale cada dato y las fórmulas.
- **Guardar** escribe directamente en los `.tres` de la carpeta elegida (solo la línea cambiada). Úsalo en la carpeta del worktree de un ticket, nunca en la de `main`, y luego `/commit` como siempre.
- Pestaña **Niveles**: una fila por nivel (dinero inicial editable, torretas, oleadas y totales). Pulsa un nivel para ver sus oleadas (`health_multiplier` editable, naves, recompensa, vida total, duración de la salida y el ratio dificultad/dinero, en rojo por encima de 1) y pulsa una oleada para editar sus grupos: nave (desplegable), cuántas, separación, pausa después y camino; con los botones se añaden, quitan y reordenan. Todo se recalcula al momento. Las oleadas se cambian siempre aquí: `make_waves.gd` solo genera oleadas automáticas de prueba y sobrescribe las del nivel que se le pida.
- Botón **▶ Jugar** (pestaña Niveles, en cada nivel y en emergencia): abre el juego (sin editor) ya en ese nivel, en la carpeta que elegiste en el panel (la principal o el worktree de un ticket), cerrando antes el Godot de esa carpeta. El juego lee los archivos guardados: si hay cambios sin guardar, el panel pregunta si guardar y jugar.
  - **Una vez**, registra el lanzador (protocolo `astro-artillery://`, solo para tu usuario, sin administrador): en la carpeta del juego, `powershell -NoProfile -ExecutionPolicy Bypass -File tools/balance/launcher/registrar.ps1`. Apunta a `tools/balance/launcher/lanzar.ps1` de la carpeta principal y guarda la ruta de Godot de tu `.claude/settings.local.json`. Si cambias Godot de sitio, vuelve a ejecutarlo.
  - La primera vez el navegador pregunta si abrir «astro-artillery»: marca que lo recuerde y acepta. Si el botón no abre nada, el panel enseña cómo registrarlo.
- Pestaña **Diálogos**: los textos de `translations/textos.csv` agrupados por diálogo (llamada de NOVA, tutorial del nivel de emergencia con sus variantes, tutorial de la oficina), con español e inglés lado a lado en cajas editables, contador de caracteres y aviso ⚠ si una línea es bastante más larga que las demás de su diálogo (el recuadro es fijo; `|` separa páginas). El buscador filtra por clave o texto, y «Todos los textos» enseña también el resto de claves. Guardar cambia solo las filas editadas del CSV (`git diff` solo las enseña). **Después hay que reimportar el CSV**: el juego lee los `.translation` que Godot genera al importarlo, y `/test` (sin editor) no los regenera. Reimporta abriendo el editor una vez o con `Godot --headless --import --path .` en la carpeta del juego, y commitea los `.translation` junto al CSV.
- Si cambias stats que salen en las tablas de `docs/design/` (torretas.md › "Datos", enemigos.md › "Datos"), actualiza esas tablas (o pídeselo a Claude).

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
- **Squash**: al fusionar, todos los commits de la rama entran en `main` como uno solo. En el PR se siguen viendo todos.
- Nunca se trabaja directamente en `main`: siempre en una rama. `/commit` guarda en la rama y `/merge` la lleva a main con un PR fusionado, borra la rama y deja tu carpeta con solo `main`, sin que hagas `git pull`.
