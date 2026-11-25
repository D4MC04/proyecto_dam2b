"""Genera desde cero los sprites de la estación y su SpriteFrames.

Uso (desde la raíz del proyecto):
	python scripts/tools/make_estacion.py              # escribe assets y resources
	python scripts/tools/make_estacion.py --preview D  # solo boceto y GIFs ampliados en D

Diseño: núcleo fijo en el centro y, girando alrededor, un buje con 4 radios, el anillo
y 4 placas solares con mástil pegadas por fuera del anillo. Cada píxel se calcula en coordenadas polares
del anillo (ángulo local = ángulo de pantalla - giro), así que todo lo que está en el
anillo, incluido el daño de cada fase, gira junto. La luz viene siempre de arriba a la
izquierda de la pantalla, no gira.
"""
import math
import os
import sys
from PIL import Image

SIZE = 96
FRAMES = 96  # una vuelta entera: 3,75 grados por fotograma
SPEED = 10.0  # fotogramas por segundo: una vuelta cada 9,6 s
EXPLOSION_FRAMES = 10
C = SIZE / 2.0

OUT_DIR = "assets/sprites/base/estacion"
TRES = "resources/sprite_frames/estacion.tres"


def hexc(s: str, a: int = 255) -> tuple:
	return (int(s[1:3], 16), int(s[3:5], 16), int(s[5:7], 16), a)


OUTLINE = hexc("#0c0e16")
METAL = [hexc(c) for c in ("#343a4a", "#606a7c", "#96a2b6", "#d2dceb")]
SOOT = [hexc(c) for c in ("#16141a", "#262228", "#3a3438", "#505262")]
GLASS = [hexc(c) for c in ("#223470", "#4060aa", "#96b4eb")]
GLASS_DEAD = hexc("#141c40")
DOME = [hexc(c) for c in ("#12223e", "#224a70", "#5c9ec4")]
CYAN = hexc("#40e0f0")
CYAN_LIGHT = hexc("#c8ecfa")
WINDOW = hexc("#ffd68c")
RED = hexc("#f0323c")
DARK_RED = hexc("#781222")
FIRE = [hexc(c) for c in ("#781222", "#c83c1c", "#ff8c32", "#ffe082", "#ffffe6")]
SPARK = hexc("#ffe28c")
SMOKE = hexc("#464250")
SMOKE_LIGHT = hexc("#686270")
TRANSPARENT = (0, 0, 0, 0)

# Medidas en píxeles (el sprite ocupa 80x80: radio 40)
CORE_R = 9.5  # núcleo fijo
HUB_IN, HUB_OUT = 10.5, 13.0  # buje que gira
RING_IN, RING_OUT = 25.5, 33.0
RING_MID, RING_HALF = (RING_IN + RING_OUT) / 2, (RING_OUT - RING_IN) / 2
SPOKE_HALF = 3.0
PANEL_IN, PANEL_OUT, PANEL_HALF = 35.5, 46.0, 7.5  # placa solar del diseño A
SPOKE_ANGLES = (0, 90, 180, 270)
PANEL_ANGLES = (45, 135, 225, 315)
LIGHT = (-0.55, -0.65, 0.52)  # de arriba a la izquierda y hacia el espectador


def noise(x: float, y: float, seed: int = 0) -> float:
	# Ruido determinista en [0, 1)
	n = int(x * 73856093) ^ int(y * 19349663) ^ (seed * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	return ((n ^ (n >> 16)) & 0xFFFF) / 65536.0


def ang_diff(a: float, b: float) -> float:
	return (a - b + 180.0) % 360.0 - 180.0


def shade(nx: float, ny: float, nz: float, tones: list) -> tuple:
	length = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
	lx, ly, lz = LIGHT
	ll = math.sqrt(lx * lx + ly * ly + lz * lz)
	i = (nx * lx + ny * ly + nz * lz) / (length * ll)
	# Umbrales para repartir los tonos de oscuro a claro
	steps = [-0.05, 0.45, 0.85][: len(tones) - 1]
	k = sum(1 for s in steps if i > s)
	return tones[k]


def darker(color: tuple, tones: list) -> tuple:
	return tones[max(tones.index(color) - 1, 0)] if color in tones else color


# Daño de cada fase, en ángulos locales del anillo (se acumula de una fase a la siguiente)
DAMAGE = {
	1: {
		"scorch": [(200, 16), (20, 8)],
		"breach": [],
		"panels_dark": [225],
		"panels_lost": [],
		"spokes_cut": [],
		"fires": [(200, RING_MID + 1.5), (226, PANEL_IN + 1.5)],
		"core": "ok",
	},
	2: {
		"scorch": [(110, 20), (320, 12)],
		"breach": [(110, 6)],
		"panels_dark": [],
		"panels_lost": [135],
		"spokes_cut": [(90, 16.0, 21.5)],
		"fires": [(102, RING_MID), (135, RING_OUT + 1.0), (322, RING_OUT - 1.5)],
		"core": "dim",
	},
	3: {
		"scorch": [(290, 22), (45, 10), (160, 10)],
		"breach": [(290, 8), (165, 3)],
		"panels_dark": [45],
		"panels_lost": [315],
		"spokes_cut": [(270, 14.5, 22.5)],
		"fires": [(281, RING_MID - 1), (300, RING_MID + 2), (48, PANEL_IN + 3.5), (160, RING_IN + 1.5)],
		"core": "alarm",
	},
}


def damage_for(phase: int) -> dict:
	total = {"scorch": [], "breach": [], "panels_dark": [], "panels_lost": [], "spokes_cut": [], "fires": [], "core": "ok"}
	for p in range(1, phase + 1):
		for key, value in DAMAGE[p].items():
			if key == "core":
				total["core"] = value
			else:
				total[key] += value
	# Un módulo perdido ya no está oscuro
	total["panels_dark"] = [a for a in total["panels_dark"] if a not in total["panels_lost"]]
	return total


def in_breach(local: float, r: float, dmg: dict) -> bool:
	for a, half in dmg["breach"]:
		# Bordes dentados: el hueco varía con el radio
		jag = (noise(round(r), a, 5) - 0.5) * 2.4
		if abs(ang_diff(local, a)) * math.pi / 180 * r < half * r / RING_MID * 1.0 + jag:
			return True
	return False


def near_breach(local: float, r: float, dmg: dict, margin: float) -> bool:
	for a, half in dmg["breach"]:
		arc = abs(ang_diff(local, a)) * math.pi / 180 * r
		if arc < half * r / RING_MID + margin + 1.2:
			return True
	return False


def scorch_at(local: float, r: float, dmg: dict, seed: float) -> bool:
	for a, half in dmg["scorch"]:
		d = abs(ang_diff(local, a))
		if d < half and noise(round(local / 3), round(r), int(a) + 1) < 1.1 - d / half:
			return True
	return False


def station_pixel(x: int, y: int, rot: float, frame: int, dmg: dict | None) -> tuple:
	"""Color del píxel (x, y) con el anillo girado `rot` grados. Devuelve (color, parte)."""
	dx, dy = x + 0.5 - C, y + 0.5 - C
	r = math.hypot(dx, dy)
	screen = math.degrees(math.atan2(dy, dx))
	local = (screen - rot) % 360.0
	ux, uy = (dx / r, dy / r) if r > 0 else (0.0, 0.0)

	# Núcleo fijo (no gira)
	if r <= CORE_R:
		if r > CORE_R - 1.0:
			return OUTLINE
		core = dmg["core"]
		center_r = math.hypot(dx + 0.5, dy + 0.5)
		if center_r < 1.6:
			if core == "alarm":
				return RED if (frame // 5) % 2 == 0 else DARK_RED
			if core == "dim":
				return CYAN if (frame // 8) % 3 else DOME[2]
			return CYAN_LIGHT if center_r < 0.8 else CYAN
		if core == "alarm" and _core_crack(dx, dy):
			return OUTLINE
		hx, hy = dx + 3.0, dy + 3.0
		hd = math.hypot(hx, hy)
		if hd < 2.2:
			return DOME[2]
		if r > 6.6:
			return METAL[1] if (dx + dy) < 0 else METAL[0]
		return DOME[1] if hd < 6.5 else DOME[0]

	# Buje que gira con el anillo
	if r <= HUB_OUT:
		bolt = any(abs(ang_diff(local, a)) * math.pi / 180 * r < 0.9 for a in (45, 135, 225, 315))
		if bolt and HUB_IN + 0.4 < r < HUB_OUT - 0.4:
			return METAL[3]
		return shade(ux * 0.6, uy * 0.6, 1.0, METAL[:3])

	# Radios
	for a in SPOKE_ANGLES:
		da = math.radians(ang_diff(local, a))
		if math.cos(da) <= 0:
			continue
		perp = r * math.sin(da)
		if abs(perp) <= SPOKE_HALF and r < RING_IN + 0.5:
			cut = next((c for c in dmg["spokes_cut"] if c[0] == a), None)
			if cut:
				jag = (noise(round(perp), a, 9) - 0.5) * 2.0
				if cut[1] + jag < r < cut[2] - jag:
					return None
				if cut[1] + jag - 1.2 < r < cut[2] - jag + 1.2:
					return FIRE[1] if noise(x, y, frame // 3) < 0.6 else FIRE[2]
			# Normal en pantalla: perpendicular al radio
			t = perp / SPOKE_HALF
			px, py = -uy, ux
			return shade(px * t, py * t, math.sqrt(max(1 - t * t, 0)) + 0.2, METAL)

	# Anillo
	if RING_IN <= r <= RING_OUT:
		if in_breach(local, r, dmg):
			return None
		t = (r - RING_MID) / RING_HALF
		color = shade(ux * t, uy * t, math.sqrt(max(1 - t * t, 0)), METAL)
		seam = any(abs(ang_diff(local, a)) * math.pi / 180 * r < 0.55 for a in range(0, 360, 30))
		if seam:
			color = darker(color, METAL)
		window = abs(r - RING_MID) < 0.75 and any(
			abs(ang_diff(local, a)) * math.pi / 180 * r < 0.75 for a in range(15, 360, 30))
		if window:
			color = WINDOW
		if scorch_at(local, r, dmg, 0):
			color = SOOT[min(METAL.index(color), 3)] if color in METAL else SOOT[1]
		if dmg["breach"] and near_breach(local, r, dmg, 0.0):
			color = FIRE[1] if noise(x, y, frame // 2) < 0.5 else FIRE[0]
		return color

	color = panel_pixel(x, y, r, local, ux, uy, frame, dmg)
	return None if color is MISS else color


MISS = object()  # el píxel no es de un panel


def _corner_frame(r: float, local: float, a: float) -> tuple:
	# Coordenadas del panel `a`: u radial, v a lo largo del anillo (en píxeles)
	da = math.radians(ang_diff(local, a))
	return r * math.cos(da), r * math.sin(da), math.cos(da) > 0


def _soot(color: tuple, x: int, y: int) -> tuple:
	if color in METAL and noise(x, y, 3) < 0.55:
		return SOOT[METAL.index(color)]
	return color


def _stub(x: int, y: int, frame: int) -> tuple:
	return FIRE[1] if noise(x, y, frame // 2) < 0.5 else SOOT[1]


def panel_pixel(x: int, y: int, r: float, local: float, ux: float, uy: float, frame: int, dmg: dict):
	tx, ty = -uy, ux
	for a in PANEL_ANGLES:
		ru, v, front = _corner_frame(r, local, a)
		if not front:
			continue
		lost = a in dmg["panels_lost"]
		dark = a in dmg["panels_dark"]
		# Mástil desde el anillo y una placa solar grande, cruzada al radio, con celdas.
		# Es lo único que sale del círculo de 80: llega a r = 46,5, dentro del frame de 96.
		if r < RING_OUT - 0.5:
			continue
		mast = ru < PANEL_IN + 0.5 and abs(v) <= 2.0
		panel = PANEL_IN <= ru <= PANEL_OUT and abs(v) <= PANEL_HALF
		if not (mast or panel):
			continue
		if lost:
			return _stub(x, y, frame) if ru < RING_OUT + 1.2 else None
		if mast:
			return shade(tx * v / 2.0, ty * v / 2.0, 1.0, METAL)
		pu = ru - (PANEL_IN + PANEL_OUT) / 2
		# Marco metálico, rejilla azul oscura y celdas con brillo hacia la luz
		if abs(pu) > (PANEL_OUT - PANEL_IN) / 2 - 1.0 or abs(v) > PANEL_HALF - 1.0:
			color = METAL[1] if (ux * pu + tx * v) * -0.7 + (uy * pu + ty * v) * -0.7 > 0 else METAL[0]
			return _soot(color, x, y) if dark else color
		grid = abs(pu) < 0.5 or any(abs(v - g) < 0.5 for g in (-2.5, 2.5))
		if dark:
			return SOOT[1] if grid else (GLASS_DEAD if noise(x, y, 4) < 0.7 else SOOT[0])
		if grid:
			return GLASS[0]
		# Brillo: más claro en la parte de la placa que mira a la luz (arriba a la izquierda)
		sx = ux * pu + tx * v
		sy = uy * pu + ty * v
		glow = -(sx + sy) / 7.0 + (noise(round(pu), round(v), int(a)) - 0.5) * 0.3
		return GLASS[2] if glow > 0.55 else GLASS[1]
	return MISS


def _core_crack(dx: float, dy: float) -> bool:
	# Grieta fija en el núcleo (fase 3)
	return (abs(dy - (dx * 0.6 - 1.5)) < 0.5 and 0 < dx < 6) or (abs(dx - 2.5) < 0.5 and 1 < dy < 5)


def outline(img: Image.Image) -> None:
	px = img.load()
	w, h = img.size
	solid = [[px[x, y][3] == 255 for y in range(h)] for x in range(w)]
	for x in range(w):
		for y in range(h):
			if not solid[x][y]:
				continue
			for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
				if nx < 0 or ny < 0 or nx >= w or ny >= h or not solid[nx][ny]:
					px[x, y] = OUTLINE
					break


def blend(dst: tuple, src: tuple) -> tuple:
	a = src[3] / 255.0
	if dst[3] == 0:
		return src
	return tuple(int(src[i] * a + dst[i] * (1 - a)) for i in range(3)) + (255,)


def draw_disc(img: Image.Image, cx: float, cy: float, rad: float, color: tuple, only_empty: bool = False) -> None:
	px = img.load()
	for y in range(int(cy - rad - 1), int(cy + rad + 2)):
		for x in range(int(cx - rad - 1), int(cx + rad + 2)):
			if 0 <= x < SIZE and 0 <= y < SIZE and (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= rad * rad:
				if only_empty and px[x, y][3] == 255:
					continue
				px[x, y] = blend(px[x, y], color)


def polar(r: float, screen_deg: float) -> tuple:
	a = math.radians(screen_deg)
	return C + r * math.cos(a), C + r * math.sin(a)


def station_frame(phase: int, frame: int) -> Image.Image:
	rot = frame * 360.0 / FRAMES
	dmg = damage_for(phase)
	img = Image.new("RGBA", (SIZE, SIZE), TRANSPARENT)
	px = img.load()
	for y in range(SIZE):
		for x in range(SIZE):
			color = station_pixel(x, y, rot, frame, dmg)
			if color is not None:
				px[x, y] = color
	outline(img)
	if phase == 0:
		return img
	# Humo: cada fuego suelta bocanadas que se quedan donde nacieron y se alejan hacia fuera
	smoke_len = 6
	for i, (a, r) in enumerate(dmg["fires"]):
		for age in range(smoke_len, 0, -1):
			born = (frame - age * 3) % FRAMES
			jitter = (noise(i, born, 16) - 0.5) * 3.0
			sx, sy = polar(r + 2.0 + age * 1.1 + jitter, a + born * 360.0 / FRAMES)
			alpha = int(110 * (1 - age / (smoke_len + 1)))
			col = SMOKE_LIGHT if age < 3 else SMOKE
			draw_disc(img, sx, sy, 0.9 + age * 0.22, col[:3] + (alpha,), only_empty=True)
	# Fuegos que parpadean, pegados a su sitio del anillo
	for i, (a, r) in enumerate(dmg["fires"]):
		fx, fy = polar(r, a + rot)
		flick = noise(i, frame // 2, 11)
		size = 1.6 + flick * 0.9
		draw_disc(img, fx, fy, size, FIRE[1])
		draw_disc(img, fx, fy, size - 0.7, FIRE[2])
		draw_disc(img, fx - 0.3, fy - 0.3, max(size - 1.4, 0.5), FIRE[3])
		# Chispa suelta de vez en cuando
		if noise(i, frame, 13) < 0.3:
			sx, sy = polar(r + 3 + noise(i, frame, 14) * 3, a + rot + (noise(i, frame, 15) - 0.5) * 12)
			if 0 <= int(sx) < SIZE and 0 <= int(sy) < SIZE:
				px[int(sx), int(sy)] = SPARK
	return img


# --- Restos y explosión ---------------------------------------------------

# Trozos del anillo que quedan tras la explosión: (ángulo inicial, final, empuje en px)
FRAGMENTS = [(-60, 25, 6.0), (40, 100, 5.0), (120, 215, 7.0), (230, 285, 5.5)]
WRECK_ROT = 30.0


def wreck_pixel(x: int, y: int, push: float) -> tuple:
	for start, end, drift in FRAGMENTS:
		mid = (start + end) / 2 + WRECK_ROT
		ox, oy = polar(drift * push, mid)
		dx, dy = x + 0.5 - ox, y + 0.5 - oy
		r = math.hypot(dx, dy)
		local = (math.degrees(math.atan2(dy, dx)) - WRECK_ROT) % 360.0
		inside = start <= ang_diff(local, 0) <= end if start < 0 else start <= local <= end
		if not inside:
			continue
		jag = (noise(round(r), start, 21) - 0.5) * 6
		if min(abs(ang_diff(local, start)), abs(ang_diff(local, end))) * math.pi / 180 * r < 1.5 + jag:
			continue
		ux, uy = dx / r, dy / r
		if RING_IN <= r <= RING_OUT:
			t = (r - RING_MID) / RING_HALF
			color = shade(ux * t, uy * t, math.sqrt(max(1 - t * t, 0)), SOOT)
			if noise(x, y, 22) < 0.08:
				return FIRE[1]
			return color
		# Mástil y media placa solar quemada que quedan en algunos trozos
		for a in (45, 135):
			if start <= ang_diff(a, 0) <= end or start <= a <= end:
				ru, v, front = _corner_frame(r, local, a)
				if not front or ru < RING_OUT - 0.5:
					continue
				if ru < PANEL_IN + 0.5 and abs(v) <= 2.0:
					return SOOT[2] if (ux + uy) < 0 else SOOT[1]
				broken = 3.0 + (noise(round(ru), a, 25) - 0.5) * 4.0
				if PANEL_IN <= ru <= PANEL_OUT - 2.0 and -PANEL_HALF <= v <= broken:
					return GLASS_DEAD if noise(x, y, 26) < 0.6 else SOOT[0]
	# Núcleo reventado en el centro (sin moverse)
	dx, dy = x + 0.5 - C, y + 0.5 - C
	r = math.hypot(dx, dy)
	if r < 7.0 - noise(x, y, 23) * 2.0:
		if r < 2.0:
			return FIRE[1] if noise(x, y, 24) < 0.5 else FIRE[0]
		return SOOT[1] if (dx + dy) < 0 else SOOT[0]
	return None


def wreck_frame(push: float = 1.0) -> Image.Image:
	img = Image.new("RGBA", (SIZE, SIZE), TRANSPARENT)
	px = img.load()
	for y in range(SIZE):
		for x in range(SIZE):
			color = wreck_pixel(x, y, push)
			if color is not None:
				px[x, y] = color
	outline(img)
	return img


def fireball(img: Image.Image, radius: float, heat: float, seed: int, alpha: int = 255) -> None:
	# Bola de fuego: más caliente en el centro; `heat` baja de 1 a 0 al enfriarse
	px = img.load()
	ramp = FIRE + [FIRE[-1]]
	for y in range(SIZE):
		for x in range(SIZE):
			dx, dy = x + 0.5 - C, y + 0.5 - C
			d = math.hypot(dx, dy) / max(radius, 0.1) + (noise(x, y, seed) - 0.5) * 0.25
			if d > 1.0:
				continue
			v = (1.0 - d) * (0.6 + heat * 0.9)
			if heat < 0.25:
				# Humo punteado: cuanto menos `alpha`, menos píxeles
				if noise(x, y, seed + 7) < alpha / 255.0 * (0.4 + v):
					col = SMOKE_LIGHT if v > 0.3 else SMOKE
					px[x, y] = blend(px[x, y], col[:3] + (160,))
				continue
			k = min(int(v * 4.0), 4)
			px[x, y] = blend(px[x, y], ramp[k][:3] + (alpha,))


def explosion_frames() -> list:
	frames = []
	# 0-1: la estación en fase 3 con el núcleo encendiéndose
	for i in range(2):
		img = station_frame(3, i)
		fireball(img, 4.0 + i * 6.0, 1.0, 30 + i)
		frames.append(img)
	# 2-6: bola de fuego que crece y se enfría mientras los trozos salen despedidos
	sizes = [(22, 1.0), (32, 0.85), (37, 0.6), (38, 0.4), (36, 0.3)]
	for i, (rad, heat) in enumerate(sizes):
		img = wreck_frame(push=min(1.0, (i + 1) / 4.0))
		fireball(img, rad, heat, 40 + i)
		for k in range(14):
			sx, sy = polar(rad + 2 + noise(k, i, 41) * 8, noise(k, 0, 42) * 360)
			if 0 <= int(sx) < SIZE and 0 <= int(sy) < SIZE:
				img.load()[int(sx), int(sy)] = SPARK
		frames.append(img)
	# 7-9: humo que se disipa sobre los restos
	for i, alpha in enumerate((170, 100, 40)):
		img = wreck_frame()
		fireball(img, 38 + i * 2, 0.0, 50 + i, alpha)
		frames.append(img)
	return frames


# --- Salida -----------------------------------------------------------------

def sheet(frames: list) -> Image.Image:
	out = Image.new("RGBA", (SIZE * len(frames), SIZE), TRANSPARENT)
	for i, f in enumerate(frames):
		out.paste(f, (i * SIZE, 0))
	return out


def write_tres() -> None:
	# Conserva los uid y los id de ext_resource existentes
	ext = [
		('ctbsxih6owibd', 'estacion_fase_0_sheet.png', '1_fase_0'),
		('3m8bfiu5xdv4', 'estacion_fase_1_sheet.png', '2_fase_1'),
		('bx7pd0i5ausqd', 'estacion_fase_2_sheet.png', '3_fase_2'),
		('cbwp8sjgggu8p', 'estacion_fase_3_sheet.png', '4_fase_3'),
		('ba3wppo7b1hsu', 'estacion_explosion_sheet.png', '5_explosion'),
		('dl4jp0b6hmi3b', 'estacion_destruida.png', '6_destruida'),
	]
	anims = [("destruida", "6_destruida", 1, False, 5.0), ("explosion", "5_explosion", EXPLOSION_FRAMES, False, 12.0)]
	anims += [("fase_%d" % n, ext[n][2], FRAMES, True, SPEED) for n in range(4)]
	lines = ['[gd_resource type="SpriteFrames" format=3 uid="uid://tg41fftx6xax"]', ""]
	for uid, name, rid in ext:
		lines.append('[ext_resource type="Texture2D" uid="uid://%s" path="res://%s/%s" id="%s"]' % (uid, OUT_DIR, name, rid))
	lines.append("")
	for name, rid, count, _loop, _speed in anims:
		for i in range(count):
			lines += ['[sub_resource type="AtlasTexture" id="AtlasTexture_%s_%d"]' % (name, i),
				'atlas = ExtResource("%s")' % rid, "region = Rect2(%d, 0, %d, %d)" % (i * SIZE, SIZE, SIZE), ""]
	lines += ["[resource]", "animations = [{"]
	blocks = []
	for name, _rid, count, loop, speed in anims:
		frames = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%s_%d")\n}' % (name, i) for i in range(count))
		blocks.append('"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f' % (frames, "true" if loop else "false", name, speed))
	lines.append("\n}, {\n".join(blocks))
	lines.append("}]")
	with open(TRES, "w", encoding="utf-8", newline="\n") as f:
		f.write("\n".join(lines) + "\n")


def preview(out_dir: str) -> None:
	os.makedirs(out_dir, exist_ok=True)
	bg = (26, 28, 44, 255)
	scale = 4
	# Boceto: fase 0 a 3 (fotograma 0), restos, y la explosión
	sketch = Image.new("RGBA", (SIZE * 5, SIZE * 2), bg)
	for n in range(4):
		f = station_frame(n, 0)
		sketch.paste(f, (n * SIZE, 0), f)
	w = wreck_frame()
	sketch.paste(w, (4 * SIZE, 0), w)
	for i, f in enumerate(explosion_frames()[::2]):
		sketch.paste(f, (i * SIZE, SIZE), f)
	sketch.resize((sketch.width * scale, sketch.height * scale), Image.NEAREST).save(os.path.join(out_dir, "boceto.png"))
	for n in range(4):
		gif = []
		for i in range(FRAMES):
			f = Image.new("RGBA", (SIZE, SIZE), bg)
			s = station_frame(n, i)
			f.paste(s, (0, 0), s)
			gif.append(f.convert("RGB").resize((SIZE * scale, SIZE * scale), Image.NEAREST))
		gif[0].save(os.path.join(out_dir, "fase_%d.gif" % n), save_all=True, append_images=gif[1:],
			duration=int(1000 / SPEED), loop=0)
	ex = []
	for f in explosion_frames() + [wreck_frame()] * 6:
		b = Image.new("RGBA", (SIZE, SIZE), bg)
		b.paste(f, (0, 0), f)
		ex.append(b.convert("RGB").resize((SIZE * scale, SIZE * scale), Image.NEAREST))
	ex[0].save(os.path.join(out_dir, "explosion.gif"), save_all=True, append_images=ex[1:], duration=int(1000 / 12), loop=0)


def main() -> None:
	if len(sys.argv) > 2 and sys.argv[1] == "--preview":
		preview(sys.argv[2])
		return
	for n in range(4):
		sheet([station_frame(n, i) for i in range(FRAMES)]).save(os.path.join(OUT_DIR, "estacion_fase_%d_sheet.png" % n))
	sheet(explosion_frames()).save(os.path.join(OUT_DIR, "estacion_explosion_sheet.png"))
	wreck_frame().save(os.path.join(OUT_DIR, "estacion_destruida.png"))
	write_tres()


if __name__ == "__main__":
	main()
