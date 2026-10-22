extends SceneTree
## Genera las imágenes del fondo del menú principal en assets/sprites/backgrounds/menu/:
##   menu_nebula.png   (960x540) nebulosa verde azulada con una banda de estrellas ondulada; casa
##                     consigo misma en horizontal, para desplazarse como la de los niveles
##   menu_planet.png   (320x240) gigante gaseoso ámbar con anillos, iluminado desde arriba a la izquierda
##   menu_vignette.png (960x540) oscurecimiento de los bordes, en tramado
##
## Uso: godot --headless --path . -s scripts/tools/make_menu_background.gd
##
## Mismo estilo que el fondo de los niveles (tonos planos muy oscuros y transiciones en tramado
## de píxeles, sin degradados ni antialiasing), pero con otra paleta y otra composición.

const OUTPUT_DIR: String = "res://assets/sprites/backgrounds/menu/"
const SEED: int = 2718

const NEBULA_SIZE: Vector2i = Vector2i(960, 540)
# Del fondo al tono más claro de la nebulosa
const NEBULA_PALETTE: Array[Color] = [
	Color("#050d14"), Color("#08161d"), Color("#0b2026"), Color("#0f2c2f"), Color("#143a39"), Color("#1b4b45"),
]
# Banda de estrellas: centro, amplitud de la onda y anchura (px)
const BAND_CENTER: float = 0.52
const BAND_AMPLITUDE: float = 0.2
const BAND_WIDTH: float = 78.0
const STAR_COUNT: int = 900
const STAR_COLORS: Array[Color] = [Color("#2c4a50"), Color("#5a8a8c"), Color("#befffa"), Color("#ffecc8"), Color("#ffffff")]

const PLANET_SIZE: Vector2i = Vector2i(320, 240)
const PLANET_RADIUS: float = 92.0
const PLANET_PALETTE: Array[Color] = [
	Color("#120b0a"), Color("#22150e"), Color("#352315"), Color("#4d331c"), Color("#684524"), Color("#865a2c"), Color("#a87438"),
]
# Anillos: semiejes, giro y tramo (fracción del radio) de cada anillo
const RING_RADII: Vector2 = Vector2(150.0, 30.0)
const RING_TILT: float = -0.22
const RING_BANDS: Array[Vector2] = [Vector2(0.66, 0.79), Vector2(0.82, 0.97)]
const RING_PALETTE: Array[Color] = [Color("#29221e"), Color("#43392e"), Color("#635442"), Color("#87725a")]
const LIGHT: Vector3 = Vector3(-0.55, -0.6, 0.58)

const VIGNETTE_COLOR: Color = Color("#02060a")
const VIGNETTE_STEPS: Array[float] = [0.0, 0.22, 0.42, 0.6]

const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = SEED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_save(_make_nebula(), "menu_nebula.png")
	_save(_make_planet(), "menu_planet.png")
	_save(_make_vignette(), "menu_vignette.png")
	quit()


func _save(image: Image, file_name: String) -> void:
	var error: Error = image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + file_name))
	print("%s%s %s (%s)" % [OUTPUT_DIR, file_name, image.get_size(), error_string(error)])


## Umbral del tramado ordenado 4x4 en el píxel, de -0,5 a 0,5.
func _bayer(x: int, y: int) -> float:
	return (BAYER[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0 - 0.5


## Índice de la paleta para un valor de 0 a 1 con tramado entre tonos vecinos.
func _step(value: float, steps: int, x: int, y: int) -> int:
	return clampi(floori(value * steps + 0.5 + _bayer(x, y)), 0, steps - 1)


func _make_noise(noise_seed: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	return noise


## Ruido de 0 a 1 que casa en horizontal: la x recorre un círculo en 3D.
func _tiling_noise(noise: FastNoiseLite, x: float, y: float) -> float:
	var angle: float = x / NEBULA_SIZE.x * TAU
	var radius: float = NEBULA_SIZE.x / TAU
	return noise.get_noise_3d(cos(angle) * radius, sin(angle) * radius, y) * 0.5 + 0.5


## Distancia vertical (px) de y al centro de la banda de estrellas en la columna x.
func _band_offset(noise: FastNoiseLite, x: float, y: float) -> float:
	var center: float = NEBULA_SIZE.y * (BAND_CENTER - BAND_AMPLITUDE * cos(x / NEBULA_SIZE.x * TAU))
	return y - center + (_tiling_noise(noise, x, y) - 0.5) * 90.0


func _band(noise: FastNoiseLite, x: float, y: float) -> float:
	var d: float = _band_offset(noise, x, y) / BAND_WIDTH
	return exp(-d * d)


func _make_nebula() -> Image:
	var clouds: FastNoiseLite = _make_noise(SEED, 0.006, 4)
	var detail: FastNoiseLite = _make_noise(SEED + 1, 0.02, 3)
	var warp: FastNoiseLite = _make_noise(SEED + 2, 0.004, 2)
	var image: Image = Image.create(NEBULA_SIZE.x, NEBULA_SIZE.y, false, Image.FORMAT_RGBA8)
	for y: int in NEBULA_SIZE.y:
		for x: int in NEBULA_SIZE.x:
			var band: float = _band(warp, x, y)
			var cloud: float = smoothstep(0.42, 0.78, _tiling_noise(clouds, x, y))
			var fine: float = _tiling_noise(detail, x, y)
			# Franja de polvo oscuro que recorre la banda por dentro, algo desplazada del centro
			var lane: float = (_band_offset(warp, x, y) - 14.0 + (fine - 0.5) * 30.0) / 15.0
			var dust: float = exp(-lane * lane) * band * smoothstep(0.3, 0.6, _tiling_noise(clouds, x * 3.0, y * 3.0))
			var value: float = (cloud * 0.4 + band * (0.4 + fine * 0.35) - dust * 0.45) * 0.92
			image.set_pixel(x, y, NEBULA_PALETTE[_step(value, NEBULA_PALETTE.size(), x, y)])
	_add_stars(image, warp)
	return image


## Estrellas de 1 px, más juntas en la banda, y alguna cruz brillante. Ninguna toca el borde,
## para que la imagen siga casando en horizontal.
func _add_stars(image: Image, warp: FastNoiseLite) -> void:
	var placed: int = 0
	while placed < STAR_COUNT:
		var x: int = _rng.randi_range(2, NEBULA_SIZE.x - 3)
		var y: int = _rng.randi_range(2, NEBULA_SIZE.y - 3)
		var band: float = _band(warp, x, y)
		if _rng.randf() > 0.12 + band * 0.88:
			continue
		placed += 1
		var roll: float = _rng.randf()
		if roll < 0.55:
			image.set_pixel(x, y, STAR_COLORS[0])
		elif roll < 0.85:
			image.set_pixel(x, y, STAR_COLORS[1])
		elif roll < 0.985:
			image.set_pixel(x, y, STAR_COLORS[_rng.randi_range(2, 4)])
		else:
			var color: Color = STAR_COLORS[_rng.randi_range(2, 4)]
			image.set_pixel(x, y, Color.WHITE)
			for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				image.set_pixelv(Vector2i(x, y) + side, color)


func _make_planet() -> Image:
	var bands: FastNoiseLite = _make_noise(SEED + 3, 0.03, 2)
	var image: Image = Image.create(PLANET_SIZE.x, PLANET_SIZE.y, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(PLANET_SIZE) / 2.0
	var light: Vector3 = LIGHT.normalized()
	for y: int in PLANET_SIZE.y:
		for x: int in PLANET_SIZE.x:
			var offset: Vector2 = Vector2(x, y) + Vector2(0.5, 0.5) - center
			var ring: float = _ring_radius(offset)
			var in_ring: bool = _is_ring(ring)
			# Delante del planeta va la mitad de abajo del anillo (en sus ejes girados)
			var ring_in_front: bool = in_ring and offset.rotated(-RING_TILT).y > 0.0
			if offset.length() < PLANET_RADIUS and not ring_in_front:
				image.set_pixel(x, y, _planet_color(offset, light, bands, x, y))
			elif in_ring:
				image.set_pixel(x, y, _ring_color(offset, ring, x, y))
	return image


## Distancia normalizada al centro en los ejes del anillo (1 en su borde exterior).
func _ring_radius(offset: Vector2) -> float:
	var local: Vector2 = offset.rotated(-RING_TILT)
	return Vector2(local.x / RING_RADII.x, local.y / RING_RADII.y).length()


func _is_ring(ring: float) -> bool:
	for band: Vector2 in RING_BANDS:
		if ring >= band.x and ring <= band.y:
			return true
	return false


func _planet_color(offset: Vector2, light: Vector3, bands: FastNoiseLite, x: int, y: int) -> Color:
	var flat: Vector2 = offset / PLANET_RADIUS
	var normal: Vector3 = Vector3(flat.x, flat.y, sqrt(maxf(0.0, 1.0 - flat.length_squared())))
	var lit: float = clampf(normal.dot(light), 0.0, 1.0)
	# Bandas onduladas en horizontal, como las del planeta gigante de los niveles
	var latitude: float = offset.y + sin(offset.x / 21.0) * 4.0 + bands.get_noise_2d(offset.x, offset.y) * 6.0
	var stripe: float = 0.5 + 0.5 * sin(latitude / 9.0) * cos(latitude / 23.0)
	# La sombra del anillo cruza el planeta un poco por debajo del anillo
	var shadow: float = 1.0
	if _is_ring(_ring_radius(offset + Vector2(-6.0, -10.0))) and offset.rotated(-RING_TILT).y < 0.0:
		shadow = 0.45
	var value: float = (lit * 0.62 + stripe * 0.3 - 0.05) * shadow
	# Borde iluminado de atmósfera en el lado de la luz
	if flat.length() > 0.93 and lit > 0.35:
		value += 0.15
	return PLANET_PALETTE[_step(value, PLANET_PALETTE.size(), x, y)]


func _ring_color(offset: Vector2, ring: float, x: int, y: int) -> Color:
	# Más claro hacia dentro de cada anillo y en el lado de la luz (izquierda)
	var band: Vector2 = RING_BANDS[0] if ring <= RING_BANDS[0].y else RING_BANDS[1]
	var inner: float = 1.0 - (ring - band.x) / (band.y - band.x)
	var side: float = 0.5 - offset.rotated(-RING_TILT).x / RING_RADII.x * 0.5
	var value: float = 0.25 + inner * 0.35 + side * 0.35
	return RING_PALETTE[_step(value, RING_PALETTE.size(), x, y)]


func _make_vignette() -> Image:
	var image: Image = Image.create(NEBULA_SIZE.x, NEBULA_SIZE.y, false, Image.FORMAT_RGBA8)
	var half: Vector2 = Vector2(NEBULA_SIZE) / 2.0
	for y: int in NEBULA_SIZE.y:
		for x: int in NEBULA_SIZE.x:
			var offset: Vector2 = (Vector2(x, y) + Vector2(0.5, 0.5) - half) / half
			var edge: float = smoothstep(0.62, 1.25, Vector2(offset.x, offset.y * 0.9).length())
			var color: Color = VIGNETTE_COLOR
			color.a = VIGNETTE_STEPS[_step(edge, VIGNETTE_STEPS.size(), x, y)]
			image.set_pixel(x, y, color)
	return image
