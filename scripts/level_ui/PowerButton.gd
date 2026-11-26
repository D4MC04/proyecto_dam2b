extends Button
class_name PowerButton
## Botón de un poder en la barra izquierda. Lee el estado de Powers cada frame y lo pinta:
## la tecla a la izquierda y el icono a la derecha, ámbar mientras se apunta y, en recarga, un oscurecido que se va
## vaciando con los segundos que faltan. Al pulsarlo solo emite pressed; LevelUI decide.

const BG_COLOR: Color = Color("#0e1626")
const BORDER_COLOR: Color = Color("#1c7496")
const HOVER_BG_COLOR: Color = Color("#16243c")
const HOVER_BORDER_COLOR: Color = Color("#40e0f0")
const DISABLED_BG_COLOR: Color = Color("#0a0f1a")
const DISABLED_BORDER_COLOR: Color = Color("#1c4a60")
const ACTIVE_BG_COLOR: Color = Color("#453d2b")
const ACTIVE_BORDER_COLOR: Color = Color("#ecb23c")
const ICON_DIM_COLOR: Color = Color(1, 1, 1, 0.5)
const COOLDOWN_COLOR: Color = Color(0, 0, 0, 0.45)
const SECONDS_COLOR: Color = Color("#cce6ff")
const KEY_COLOR: Color = Color("#5a7a96")
# Hueco de la tecla al borde izquierdo (el icono va a la derecha, con el mismo hueco).
const KEY_MARGIN: int = 5
# Tamaño de la letra de la tecla (un poco menor que el de los segundos) y de los segundos de recarga.
const KEY_FONT_SIZE: int = 14
const SECONDS_FONT_SIZE: int = 16
# Alto de las mayúsculas y los números de Monogram, en fracción del tamaño (7 px a 16): para centrarlos en vertical.
const CAP_HEIGHT_EM: float = 7.0 / 16.0

@export var power: Powers.Power
## Letra de la tecla que se pinta a la izquierda.
@export var key_label: String = ""

var powers: Powers

var _active_style: ClippedBoxStyle = ClippedBoxStyle.create(ACTIVE_BG_COLOR, ACTIVE_BORDER_COLOR)
var _normal_style: ClippedBoxStyle = ClippedBoxStyle.create(BG_COLOR, BORDER_COLOR)
# Lo último pintado, para redibujar solo si cambia.
var _shown_seconds: int = -1
var _shown_fraction: float = -1.0
var _shown_aiming: bool = false

func _ready() -> void:
	var hover_style: ClippedBoxStyle = ClippedBoxStyle.create(HOVER_BG_COLOR, HOVER_BORDER_COLOR)
	var disabled_style: ClippedBoxStyle = ClippedBoxStyle.create(DISABLED_BG_COLOR, DISABLED_BORDER_COLOR)
	# El icono (alineado a la derecha) deja al borde el mismo hueco que la tecla.
	for style: ClippedBoxStyle in [_normal_style, _active_style, hover_style, disabled_style]:
		style.content_margin_right = KEY_MARGIN
	add_theme_stylebox_override("normal", _normal_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", _active_style)
	add_theme_stylebox_override("disabled", disabled_style)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_color_override("icon_disabled_color", ICON_DIM_COLOR)

func _process(_delta: float) -> void:
	if not is_instance_valid(powers):
		return
	var left: float = powers.get_cooldown_left(power)
	var fraction: float = left / Powers.COOLDOWNS[power]
	var seconds: int = ceili(left)
	var aiming: bool = powers.get_aimed_power() == power
	if fraction == _shown_fraction and aiming == _shown_aiming:
		return
	_shown_fraction = fraction
	_shown_seconds = seconds
	_shown_aiming = aiming
	disabled = left > 0.0
	add_theme_stylebox_override("normal", _active_style if aiming else _normal_style)
	queue_redraw()

func _draw() -> void:
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(KEY_MARGIN, _baseline(KEY_FONT_SIZE)), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_FONT_SIZE, KEY_COLOR)
	if _shown_fraction <= 0.0:
		return
	# Oscurecido desde arriba, con alto proporcional a lo que falta, recortado a la forma del botón.
	var clip: int = ClippedBoxStyle.BUTTON_CLIP
	var w: float = size.x
	var h: float = size.y
	var shape: PackedVector2Array = PackedVector2Array([Vector2(clip, 0), Vector2(w, 0), Vector2(w, h - clip),
			Vector2(w - clip, h), Vector2(0, h), Vector2(0, clip)])
	var band: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, roundf(h * _shown_fraction)), Vector2(0, roundf(h * _shown_fraction))])
	for polygon: PackedVector2Array in Geometry2D.intersect_polygons(shape, band):
		draw_colored_polygon(polygon, COOLDOWN_COLOR)
	draw_string(font, Vector2(0, _baseline(SECONDS_FONT_SIZE)), str(_shown_seconds), HORIZONTAL_ALIGNMENT_CENTER, w, SECONDS_FONT_SIZE, SECONDS_COLOR)

# Línea base que deja las mayúsculas (y los números) centradas en vertical en el botón.
func _baseline(font_size: int) -> float:
	return roundf((size.y + font_size * CAP_HEIGHT_EM) / 2.0)
