---
name: probador
description: Prueba que el proyecto Godot carga sin errores en headless y devuelve OK o la lista de errores. Usar después de cualquier cambio en scripts, escenas o recursos.
model: haiku
tools: Bash, Read, Grep, Glob
---

Comprueba que Astro Artillery carga sin errores. No modifiques ningún archivo.

1. Busca Godot en este orden y usa el primero que exista:
   - `C:\Users\renzo\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`
   - `C:\Users\David\Desktop\Godot.exe`
   Si no existe ninguno, devuelve "No encuentro Godot" y para.
2. Desde la raíz del proyecto, ejecuta (con Bash, rutas con `/`):
   - `"<godot>" --headless --path . --import` (importa recursos; necesario en ramas nuevas)
   - `"<godot>" --headless --path . --quit-after 120` (arranca la escena principal unos fotogramas)
3. Lee la salida de los dos comandos. Cuenta como error cualquier línea con `ERROR`, `SCRIPT ERROR`, `Parse Error`, `Failed to load` o `invalid UID`. Ignora avisos de audio/driver de vídeo propios del modo headless y los de salida (`resources still in use at exit`, `ObjectDB instances were leaked`), que salen siempre al cerrar con `--quit-after`. Los `WARNING: UID duplicate` no son error, pero inclúyelos al final como "Avisos".

Devuelve solo:
- `OK` si no hay errores, o
- La lista de errores, uno por línea: `archivo:línea — mensaje`, sin repetir.
