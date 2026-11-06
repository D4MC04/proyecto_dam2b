"""Genera los dibujos de la oficina del menú principal y sus posiciones.

Uso (desde la raíz del proyecto): python scripts/tools/office/make_office.py
Necesita Python 3 con numpy y Pillow.

- PNG en assets/sprites/office/ (habitación de cada vista, puerta, tablet, medallas...),
  dibujados píxel a píxel por gen_center.py, gen_left.py y gen_right.py.
- scripts/main_menu/OfficeLayout.gd: posiciones, trapecios de las pantallas y pilotos que usan
  los scripts del menú para animar encima de los PNG. No se edita a mano.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import pixkit  # noqa: E402
import gen_center  # noqa: E402
import gen_left  # noqa: E402
import gen_right  # noqa: E402

LAYOUT = os.path.join(pixkit.ROOT, "scripts", "main_menu", "OfficeLayout.gd")

HEADER = """class_name OfficeLayout
extends RefCounted

# Posiciones de la oficina del menú (en píxeles de cada vista de 960x540): trapecios de las pantallas,
# pilotos, puerta, medallas... Lo genera scripts/tools/office/make_office.py con los mismos datos que
# los PNG de assets/sprites/office/. No editar a mano: cambiar los generadores y volver a lanzarlo.
"""


def main():
	parts = {}
	for name, module in (("CENTER", gen_center), ("LEFT", gen_left), ("RIGHT", gen_right)):
		# Cada vista registra sus pilotos en la misma lista: se vacía antes y se copia después.
		pixkit.LEDS.clear()
		parts[name] = json.dumps(module.main(), separators=(", ", ": "))
	with open(LAYOUT, "w", encoding="utf-8", newline="\n") as f:
		f.write(HEADER)
		for name, text in parts.items():
			f.write("\nconst %s: Dictionary = %s\n" % (name, text))
	print("ok", LAYOUT)


if __name__ == "__main__":
	main()
