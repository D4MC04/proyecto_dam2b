# Lanzar tickets sin preguntar y tickets en la carpeta de su creador

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Dos preguntas que se repiten y ralentizan el flujo:
- El chat central a veces no lanza un ticket y saca una tarjeta de "Nueva sesión / Hacerlo aquí". Pasa sobre todo cuando un ticket que esperaba a otro se desbloquea al llegar el aviso de subida: en ese turno la app no deja al central abrir chats. Y "Hacerlo aquí" nunca vale, porque el central no implementa.
- `/add`, `/ideas`, `/accept` y `/work` preguntan cada vez quién es el creador y quién el responsable. Basta con un solo campo, `Creador`, y que salga de una configuración local de cada uno.

## Qué hay que hacer
**Lanzar siempre en su chat, sin tarjetas**
- En el prompt del chat central (`.claude/skills/hub/SKILL.md`) y en `CLAUDE.md` › "Chat central", dejar claro que las órdenes de tickets (`/add`, `/accept`, "acepto X", "lanza X") son siempre continuación del chat central. Los tickets se lanzan con `start_session` `initiation` "user_asked", nunca con "offer" ni "own_initiative" (las tarjetas).
- Tickets en espera: que `/accept` apunte en el ticket que espera a cuál espera (por ejemplo, una línea `Espera a: nombre`). Al acabar `/merge`, el propio chat del ticket (que corre en un turno que pidió el usuario, así que la app sí le deja) lanza los tickets aceptados que esperaban al suyo, en chats propios con worktree. Después los saca de debajo de él con `detach_session`, para que no se archiven con él. Luego avisa al central como ahora. El central solo limpia.
- Si aun así la app no deja lanzar un chat, el central lo dice en una línea ("X ya se puede lanzar: escribe 'lanza X'") y no saca tarjeta.

**El creador es la carpeta, sacada de la configuración local**
- Una variable de entorno nueva en `.claude/settings.local.json` de cada uno, junto a `GODOT` (por ejemplo `AUTHOR`), con su nombre. Si no está, preguntar una vez y explicar cómo ponerla, igual que con `GODOT`.
- Los tickets pasan a `docs/tickets/<nombre del creador>/nombre-del-ticket.md` (por ejemplo `docs/tickets/David/pausa-rendirse.md`). `/add` e `/ideas` los escriben en la carpeta de quien los crea, sacada de la variable, sin preguntar, y la crean si no existe. La plantilla se queda en `docs/tickets/_plantilla.md`.
- Quitar los campos `Creador` y `Responsable` de todo: la plantilla, las skills que los piden o los enseñan (`add`, `ideas`, `accept`, `work`) y las preguntas de "quién lo creó y quién es el responsable, ¿continuar?" de `/accept` y `/work`.
- Mover los tickets que ya hay a la carpeta de su `Creador:` actual, quitándoles las dos líneas, con `git mv`. Los que no tengan creador se quedan donde mejor encaje; si no está claro, preguntar.
- Actualizar todas las rutas `docs/tickets/nombre.md` de las skills (`work`, `fix`, `board`, `accept`, `add`, `ideas`, `merge`, `check`, `commit`, `hub`), de `CLAUDE.md` y de `docs/CLAUDE-CODE.md`, para que busquen el ticket en cualquier carpeta de creador (`docs/tickets/*/nombre.md`). `/work nombre` sigue funcionando solo con el nombre.
- Explicar la variable y las carpetas en `docs/CLAUDE-CODE.md`, en la parte de configuración donde está `GODOT`.

## Qué leer
- .claude/skills/hub/SKILL.md (el prompt del chat central)
- .claude/skills/accept/SKILL.md › pasos 0 a 3
- .claude/skills/merge/SKILL.md › paso 8
- .claude/skills/add/SKILL.md › pasos 5 y 6
- .claude/skills/ideas/SKILL.md y .claude/skills/work/SKILL.md › los pasos que hablan de `Creador`/`Responsable` (sacarlos con Grep)
- Las rutas `docs/tickets/` de todas las skills: `grep -rn "docs/tickets" .claude/skills CLAUDE.md docs/CLAUDE-CODE.md`
- CLAUDE.md › "Flujo de tickets"
- docs/CLAUDE-CODE.md › la configuración de `GODOT` (líneas 1 a 15)

## Archivos que toca
- .claude/skills/hub/SKILL.md
- .claude/skills/accept/SKILL.md
- .claude/skills/merge/SKILL.md
- .claude/skills/add/SKILL.md
- .claude/skills/ideas/SKILL.md
- .claude/skills/work/SKILL.md
- .claude/skills/fix, board, check y commit (rutas)
- docs/tickets/_plantilla.md y todos los tickets (se mueven a su carpeta)
- CLAUDE.md
- docs/CLAUDE-CODE.md

## Cómo se prueba a mano
No hay nada que probar en el juego: se prueba usando el flujo.
1. Poner tu nombre en `.claude/settings.local.json` como explique `docs/CLAUDE-CODE.md`.
2. `/add` de una idea cualquiera: no debería preguntar quién eres, y el ticket debería salir en `docs/tickets/<tu nombre>/`, sin `Creador` ni `Responsable`. Los tickets de antes deberían estar ya en la carpeta de su creador.
3. Aceptar dos tickets que toquen los mismos archivos: el segundo debería quedar apuntado como en espera del primero. Al hacer `/merge` del primero, el segundo debería lanzarse solo en su chat, sin ninguna tarjeta.
