---
name: probador
description: Prueba que el proyecto Godot carga sin errores en headless y devuelve OK o la lista de errores. Usar después de cualquier cambio en scripts, escenas o recursos.
model: haiku
tools: Bash, Read, Grep, Glob
---

Comprueba que Astro Artillery carga sin errores. No modifiques ningún archivo.

1. Ejecuta todo en un solo comando de Bash (no lo partas en varios), desde la raíz del proyecto:
   ```
   G="/c/Users/renzo/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe"; [ -f "$G" ] || G="/c/Users/David/Desktop/Godot.exe"; [ -f "$G" ] || { echo "No encuentro Godot"; exit 1; }; "$G" --headless --path . --import 2>&1; echo "=== ARRANQUE"; "$G" --headless --path . --quit-after 120 2>&1
   ```
   La importación es necesaria en ramas nuevas. Si sale "No encuentro Godot", devuelve eso y para.
3. Lee la salida de los dos comandos. Cuenta como error cualquier línea con `ERROR`, `SCRIPT ERROR`, `Parse Error`, `Failed to load` o `invalid UID`. Ignora avisos de audio/driver de vídeo propios del modo headless y los de salida (`resources still in use at exit`, `ObjectDB instances were leaked`), que salen siempre al cerrar con `--quit-after`. Los `WARNING: UID duplicate` no son error, pero inclúyelos al final como "Avisos".

Devuelve solo:
- `OK` si no hay errores, o
- La lista de errores, uno por línea: `archivo:línea — mensaje`, sin repetir.
