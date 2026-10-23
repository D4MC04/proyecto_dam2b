extends Button
class_name PowerButton
## Botón de un poder en la barra izquierda. Lee el estado de Powers cada frame y lo pinta:
## la tecla a la izquierda y el icono a la derecha, ámbar mientras se apunta y, en recarga, un oscurecido que se va
## vaciando con los segundos que faltan. Al pulsarlo solo emite pressed; LevelUI decide.

const BG_COLOR := Color("#0e1626")
const BORDER_COLOR := Color("#1c7496")
const HOVER_BG_COLOR := Color("#16243c")
const HOVER_BORDER_COLOR := Color("#40e0f0")
const DISABLED_BG_COLOR := Color("#0a0f1a")
const DISABLED_BORDER_COLOR := Color("#1c4a60")
const ACTIVE_BG_COLOR := Color("#453d2b")
const ACTIVE_BORDER_COLOR := Color("#ecb23c")
const ICON_DIM_COLOR := Color(1, 1, 1, 0.5)
const COOLDOWN_COLOR := Color(0, 0, 0, 0.45)
const SECONDS_COLOR := Color("#cce6ff")
const KEY_COLOR := Color("#5a7a96")
# Hueco de la tecla al borde izquierdo (el icono va a la derecha, con el mismo hueco) y alto de la fuente (Monogram a 16, línea de 13 px).
const KEY_MARGIN := 4
const FONT_SIZE := 16

@export var power: Powers.Power
## Letra de la tecla que se pinta a la izquierda.
@export var key_label := ""

var powers: Powers

var _active_style := ClippedBoxStyle.create(ACTIVE_BG_COLOR, ACTIVE_BORDER_COLOR)
var _normal_style := ClippedBoxStyle.create(BG_COLOR, BORDER_COLOR)
# Lo último pintado, para redibujar solo si cambia.
var _shown_seconds := -1
var _shown_fraction := -1.0
var _shown_aiming := false

func _ready() -> void:
	add_theme_stylebox_override("normal", _normal_style)
	add_theme_stylebox_override("hover", ClippedBoxStyle.create(HOVER_BG_COLOR, HOVER_BORDER_COLOR))
	add_theme_stylebox_override("pressed", _active_style)
	add_theme_stylebox_override("disabled", ClippedBoxStyle.create(DISABLED_BG_COLOR, DISABLED_BORDER_COLOR))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_color_override("icon_disabled_color", ICON_DIM_COLOR)

func _process(_delta: float) -> void:
	if not is_instance_valid(powers):
		return
	var left := powers.get_cooldown_left(power)
	var fraction := left / Powers.COOLDOWNS[power]
	var seconds := ceili(left)
	var aiming := powers.get_aimed_power() == power
	if fraction == _shown_fraction and aiming == _shown_aiming:
		return
	_shown_fraction = fraction
	_shown_seconds = seconds
	_shown_aiming = aiming
	disabled = left > 0.0
	add_theme_stylebox_override("normal", _active_style if aiming else _normal_style)
	queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	var line_y := (size.y + font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) / 2.0
	draw_string(font, Vector2(KEY_MARGIN, roundf(line_y)), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, KEY_COLOR)
	if _shown_fraction <= 0.0:
		return
	# Oscurecido desde arriba, con alto proporcional a lo que falta, recortado a la forma del botón.
	var clip := ClippedBoxStyle.BUTTON_CLIP
	var w := size.x
	var h := size.y
	var shape := PackedVector2Array([Vector2(clip, 0), Vector2(w, 0), Vector2(w, h - clip),
			Vector2(w - clip, h), Vector2(0, h), Vector2(0, clip)])
	var band := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, roundf(h * _shown_fraction)), Vector2(0, roundf(h * _shown_fraction))])
	for polygon in Geometry2D.intersect_polygons(shape, band):
		draw_colored_polygon(polygon, COOLDOWN_COLOR)
	draw_string(font, Vector2(0, roundf(line_y)), str(_shown_seconds), HORIZONTAL_ALIGNMENT_CENTER, w, FONT_SIZE, SECONDS_COLOR)
