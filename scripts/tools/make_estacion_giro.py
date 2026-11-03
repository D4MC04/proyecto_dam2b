"""Genera las tiras de fotogramas de la estación (fase_0 a fase_3) con el anillo girando.

Uso: python scripts/tools/make_estacion_giro.py ruta/al/giro.gif
El GIF (96x96 a x4, 48 fotogramas, el bucle se repite a los 24) da fase_0.
Las fases dañadas son fase_0 más el daño de las tiras antiguas: se toman los píxeles
que cada tira antigua cambia respecto a la antigua fase_0 (8 fotogramas, se repiten).
Script de un solo uso: sobrescribe las tiras, así que parte de las antiguas una vez.
"""
import sys
from PIL import Image

DIR = "assets/sprites/base/estacion/estacion_fase_%d_sheet.png"
SIZE = 96
FRAMES = 24
BG = (10, 12, 26, 255)
OLD_FRAMES = 8

gif = Image.open(sys.argv[1])
giro = []
for i in range(FRAMES):
	gif.seek(i)
	frame = gif.convert("RGBA").resize((SIZE, SIZE), Image.NEAREST)
	# El fondo del GIF (color exacto, también entre radios y dentro del anillo) pasa a transparente
	frame.putdata([(0, 0, 0, 0) if px == BG else px for px in frame.getdata()])
	giro.append(frame)

old = [Image.open(DIR % n).convert("RGBA") for n in range(4)]

def old_frame(phase: int, k: int) -> Image.Image:
	return old[phase].crop((k * SIZE, 0, (k + 1) * SIZE, SIZE))

for phase in range(4):
	sheet = Image.new("RGBA", (SIZE * FRAMES, SIZE))
	for i in range(FRAMES):
		frame = giro[i].copy()
		if phase > 0:
			k = i % OLD_FRAMES
			base = old_frame(0, k).load()
			dmg = old_frame(phase, k).load()
			px = frame.load()
			for y in range(SIZE):
				for x in range(SIZE):
					if dmg[x, y] != base[x, y]:
						px[x, y] = dmg[x, y]
		sheet.paste(frame, (i * SIZE, 0))
	sheet.save(DIR % phase)
