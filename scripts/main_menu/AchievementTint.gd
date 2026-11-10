class_name AchievementTint
extends RefCounted

# Pinta una medalla o un icono de logro en el metal de su fase (bronce, plata u oro). Cambia los
# colores de las familias ámbar, roja y cian de la paleta de la oficina (pixkit.py) por el tono del
# mismo brillo de la fase; el resto (contorno, esmalte, placa gris) se queda. Un mismo PNG sirve
# para las tres fases. Las texturas se guardan para no repintarlas.

# Tonos de cada fase (GameState.PHASE_BRONZE, PHASE_SILVER y PHASE_GOLD), de oscuro a claro. El oro
# es la familia ámbar tal cual.
const RAMPS: Dictionary[int, Array] = {
	1: [Color("4a2412"), Color("8a4a24"), Color("c87a3e"), Color("eeaa70"), Color("ffe2c4")],
	2: [Color("3c4352"), Color("7a8496"), Color("bcc6d4"), Color("e4eaf2"), Color("ffffff")],
	3: [Color("523710"), Color("96641e"), Color("ecb23c"), Color("ffe082"), Color("fff8e6")],
}
# Color de la paleta (RGB en hexadecimal) -> tono de la rampa que le toca.
const SOURCE_TONES: Dictionary[String, int] = {
	"523710": 0, "96641e": 1, "ecb23c": 2, "ffe082": 3, "fff8e6": 4,
	"3a0a16": 0, "961432": 1, "ff3c5a": 2, "ffaabe": 3,
	"14304a": 0, "1c7496": 1, "40e0f0": 2, "befaff": 3,
}

static var _cache: Dictionary[String, Texture2D] = {}

## `source` pintada en el metal de `phase`. Las filas de `keep_rows` (de x incluida a y sin incluir) no
## se tocan: en las medallas, la cinta, que guarda su color.
static func tint(source: Texture2D, phase: int, keep_rows: Vector2i = Vector2i.ZERO) -> Texture2D:
	if not RAMPS.has(phase):
		return source
	var key: String = "%s:%d:%s" % [source.resource_path, phase, keep_rows]
	if _cache.has(key):
		return _cache[key]
	var image: Image = source.get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var ramp: Array = RAMPS[phase]
	for y: int in image.get_height():
		if y >= keep_rows.x and y < keep_rows.y:
			continue
		for x: int in image.get_width():
			var color: Color = image.get_pixel(x, y)
			if color.a8 == 0:
				continue
			var tone: int = SOURCE_TONES.get(color.to_html(false), -1)
			if tone >= 0:
				var new_color: Color = ramp[tone]
				new_color.a = color.a
				image.set_pixel(x, y, new_color)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture
