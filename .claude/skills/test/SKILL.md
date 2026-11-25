---
name: test
description: Abre Godot para probar a mano, a la primera y delante de todo - el editor y el juego ya colocados en el punto donde se prueba lo cambiado en este chat. Usar tras /work y /fix, y cuando el usuario pida "abre godot" (o parecido) en un chat de ticket.
argument-hint: "[qué probar u otros argumentos de prueba]"
---

Abre Godot para probar lo de este chat. Nota del usuario (puede estar vacía): $ARGUMENTS

1. **Punto de prueba.** Elige los argumentos de prueba del juego (solo funcionan en depuración, no cargan ranura y no guardan nada; los lee `scripts/screens/DevLaunch.gd`):
   - `--level=N`: nivel N (1 = primer sector) ya empezado. `--level=emergency`: el nivel de emergencia.
   - `--wave=N` (con `--level`): las oleadas anteriores a la N se dan por jugadas; la siguiente es la N.
   - `--money=N` (con `--level`): dinero inicial. Para probar torretas, mejoras o fusiones, pon de sobra (`--money=99999`).
   - `--office`: la oficina sin tutoriales. `--office-tutorial`: la oficina con su tutorial.
   - `--progress=N`: nivel más alto desbloqueado (radar y sectores de la oficina).

   Elige el que lleve directo a lo cambiado en este chat (o a lo que diga la nota): una torreta o enemigo → un nivel donde salga, con dinero de sobra y, si es un enemigo, la oleada donde aparece (búscalo con Grep en `resources/level_data/` y `resources/wave_data/`); la oficina o sus paneles → `--office`; el nivel de emergencia o sus pistas → `--level=emergency`. Si el cambio es muy general (pantalla de inicio, ranuras) o no hay un punto claro, sin argumentos. Si hace falta un argumento que no existe para llegar a un punto de prueba habitual, añádelo a `DevLaunch.gd` (solo en depuración) y documéntalo aquí.

   Escenas de prueba propias solo si ahorran mucho tiempo frente a llegar desde el juego: van en `scenes/dev_preview/` y `scripts/dev_preview/` (ignoradas por git) y se borran antes de `/merge`. Aun así, los pasos para probar siempre incluyen uno dentro del juego real.

2. **Abrir.** Un solo comando de PowerShell, desde la carpeta de este chat (el worktree si lo hay):
   ```
   powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/test/open-godot.ps1 -Path "<carpeta de este chat>" -GameArgs "<argumentos>"
   ```
   Sin argumentos de prueba, quita `-GameArgs`. Si solo hace falta el editor (por ejemplo, algo que se ve en una escena), añade `-NoGame`. El script cierra solo el Godot de esa carpeta (no los de otras), lanza editor y juego desacoplados (no mueren al acabar la llamada), espera a que tengan ventana, reintenta una vez si no sale y los trae al frente (el juego delante del editor).

3. **Comprobar.** Lee lo que imprime: `EDITOR OK` y `JUEGO OK` es que están abiertos y delante. Si sale `NO SALE` o `NO DELANTE`, dilo tal cual al usuario (por ejemplo: "El editor no ha salido: el proceso se cerró solo" o "Está abierto pero detrás: búscalo en la barra de tareas"). Nunca digas que Godot está abierto si el script no lo confirma.

Termina con, en pocas líneas: qué se ha abierto y dónde está el juego (por ejemplo "nivel 3, oleada 5, con 99999 de dinero"), qué hacer ahí y qué debería verse. Si el usuario cierra el juego, puede volver a lanzarlo con F5 desde el editor (sin argumentos: empieza en la pantalla de inicio) o escribir `/test` otra vez.
