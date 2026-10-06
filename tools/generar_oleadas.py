#!/usr/bin/env python3
"""Genera la oleada de cada nivel en resources/waves/nivel_N.tres.

Uso (desde la raíz del proyecto):  python tools/generar_oleadas.py

Para retocar la dificultad, cambia LEVELS y vuelve a ejecutarlo. El resultado es siempre
el mismo para los mismos datos (semilla fija por nivel). La vida, velocidad y recompensa
de cada enemigo se leen de resources/enemy_data/*.tres.
"""
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Tipos de enemigo, de menos a más peligroso, por categoría.
WEAK = ["dart_rojo", "dart_verde", "dart_hielo", "dart_morado", "wasp"]
MEDIUM = ["nave_normal", "ufo", "nave_agresiva", "spiked_ship"]
HARD = ["ariete", "acorazado", "nodriza"]
ORDER = WEAK + MEDIUM + HARD
# Cuánto se retrasa cada tipo dentro del nivel: los de valor alto tienden a salir más tarde.
LATENESS = dict(dart_rojo=0.0, dart_verde=0.0, dart_hielo=0.0, dart_morado=0.0, wasp=0.7,
                nave_normal=0.9, ufo=1.0, nave_agresiva=1.2, spiked_ship=1.5,
                ariete=1.8, acorazado=2.2, nodriza=3.0)

# Por nivel:
#   paths      caminos del mapa (MapN.tscn). Se empieza por uno solo y se van abriendo los demás,
#              porque al principio solo hay dinero para una torre; después los grupos se turnan
#   enemies    cuántos de cada tipo
#   group_max  tamaño máximo de grupo: empieza de uno en uno y crece hasta este valor
#   spacing    segundos entre enemigos de un mismo grupo
#   gap        segundos entre grupos, al principio y al final del nivel
#   last       (opcional) tipo que sale el último, solo
#   open       (opcional) ritmo al que se abren los caminos: más alto, antes (por defecto 1.0)
#   open_exp   (opcional) curva de apertura: 1.0 a ritmo constante; más alto, los caminos
#              extra se abren hacia el final, cuando ya hay dinero para defenderlos
#   hard_paths (opcional) los enemigos duros solo usan los primeros N caminos (los largos)
LEVELS = {
    1: dict(paths=1, group_max=4, spacing=0.8, gap=(4.5, 2.5),
            enemies=dict(dart_rojo=5, dart_verde=4, dart_hielo=4, dart_morado=4, wasp=8)),
    2: dict(paths=1, group_max=3, spacing=1.0, gap=(4.5, 3.4),
            enemies=dict(dart_rojo=4, dart_verde=4, dart_hielo=4, dart_morado=4, wasp=8,
                         nave_normal=5, ufo=3)),
    3: dict(paths=1, group_max=4, spacing=0.9, gap=(4.8, 3.0),
            enemies=dict(dart_rojo=4, dart_verde=4, dart_hielo=4, dart_morado=4, wasp=8,
                         nave_normal=6, ufo=5, nave_agresiva=3, spiked_ship=2)),
    4: dict(paths=2, group_max=4, spacing=0.8, gap=(4.6, 2.8), open=1.5,
            enemies=dict(dart_rojo=5, dart_verde=5, dart_hielo=4, dart_morado=4, wasp=10,
                         nave_normal=6, ufo=5, nave_agresiva=5, spiked_ship=3, acorazado=3)),
    5: dict(paths=1, group_max=5, spacing=0.7, gap=(4.6, 2.6),
            enemies=dict(dart_rojo=4, dart_verde=4, dart_hielo=4, dart_morado=4, wasp=10,
                         nave_normal=6, ufo=6, nave_agresiva=5, spiked_ship=3,
                         ariete=8, acorazado=6)),
    6: dict(paths=4, group_max=5, spacing=0.8, gap=(5.5, 4.0), last="nodriza", hard_paths=2, open_exp=2.0,
            enemies=dict(dart_rojo=8, dart_verde=8, dart_hielo=8, dart_morado=8, wasp=13,
                         nave_normal=7, ufo=6, nave_agresiva=6, spiked_ship=3,
                         ariete=4, acorazado=3, nodriza=1)),
}
FIRST_SPAWN = 3.0  # segundos antes del primer enemigo


def enemy_stats(name):
    text = (ROOT / "resources/enemy_data" / f"{name}.tres").read_text(encoding="utf-8")
    return {k: float(re.search(rf"^{k} = ([\d.]+)", text, re.M).group(1)) for k in ("hp", "speed", "reward")}


def build(level, cfg):
    """Devuelve la lista de (tiempo, tipo, camino) del nivel."""
    rng = random.Random(level)
    pool = [name for name, n in cfg["enemies"].items() for _ in range(n)]
    last = cfg.get("last")
    if last:
        pool.remove(last)
    # Mezclados, pero con los tipos más duros tendiendo a salir más tarde.
    pool.sort(key=lambda name: LATENESS[name] + rng.random())

    entries = []
    t = FIRST_SPAWN
    group = 0
    opened = 1
    i = 0
    while i < len(pool):
        progress = i / len(pool)
        size = min(1 + int(cfg["group_max"] * progress), cfg["group_max"], len(pool) - i)
        opening = progress ** cfg.get("open_exp", 1.0) * cfg.get("open", 1.0)
        open_paths = min(cfg["paths"], 1 + int(opening * cfg["paths"]))
        hard_paths = min(open_paths, cfg.get("hard_paths", open_paths))
        # El grupo que estrena un camino va entero por él; después se turnan.
        turn = open_paths - 1 if open_paths > opened else group
        opened = open_paths
        for j in range(size):
            name = pool[i + j]
            entries.append((round(t + j * cfg["spacing"], 2), name, turn % (hard_paths if name in HARD else open_paths)))
        t += (size - 1) * cfg["spacing"] + cfg["gap"][0] + (cfg["gap"][1] - cfg["gap"][0]) * progress
        i += size
        group += 1
    if last:
        entries.append((round(t + 2.0, 2), last, 0))
    return entries


def write(level, entries):
    used = [name for name in ORDER if any(e[1] == name for e in entries)]
    exts = "".join(f'[ext_resource type="Resource" path="res://resources/enemy_data/{name}.tres" id="{name}"]\n' for name in used)
    subs = "".join(
        f'[sub_resource type="Resource" id="e{i}"]\nscript = ExtResource("entry")\n'
        f'enemy_data = ExtResource("{name}")\ntime = {t}\npath_index = {path}\n\n'
        for i, (t, name, path) in enumerate(entries))
    refs = ", ".join(f'SubResource("e{i}")' for i in range(len(entries)))
    out = ROOT / "resources/waves" / f"nivel_{level}.tres"
    out.parent.mkdir(exist_ok=True)
    out.write_text(f'''[gd_resource type="Resource" script_class="WaveData" format=3]

[ext_resource type="Script" uid="uid://bov3v8pbstdra" path="res://scripts/models/WaveData.gd" id="wave"]
[ext_resource type="Script" uid="uid://cwc32qenwkwf3" path="res://scripts/models/SpawnEntry.gd" id="entry"]
{exts}
{subs}[resource]
script = ExtResource("wave")
entries = Array[ExtResource("entry")]([{refs}])
''', encoding="utf-8", newline="\n")


def main():
    stats = {name: enemy_stats(name) for name in ORDER}
    print("nivel | enemigos | débiles/medios/duros | último spawn | vida total | recompensas")
    for level, cfg in LEVELS.items():
        entries = build(level, cfg)
        write(level, entries)
        names = [e[1] for e in entries]
        tiers = "/".join(str(sum(n in tier for n in names)) for tier in (WEAK, MEDIUM, HARD))
        print(f"{level:5} | {len(entries):8} | {tiers:20} | {entries[-1][0]:10.1f} s | "
              f"{sum(stats[n]['hp'] for n in names):10.0f} | {sum(stats[n]['reward'] for n in names):8.0f} €")


if __name__ == "__main__":
    main()
