extends Button
class_name OverlayOptionButton

# Botón de una OverlayScreen. Dice qué opción representa (la pantalla base lo conecta),
# se dibuja con caja en el color de acento y muestra un selector ">" al pasar el ratón.

const BG_COLOR := Color("#0e1626")
const IDLE_COLOR := Color("#cce6ff")
const SELECTOR := ">"
# Hueco entre el selector y el texto.
const SELECTOR_GAP := 4

@export var option: OverlayScreen.Option = OverlayScreen.Option.RESUME
@export var accent_color: Color = Color("#40e0f0"):
	set(value):
		accent_color = value
		_refresh_look()

func _ready() -> void:
	# Es un juego de ratón: los botones no toman el foco.
	focus_mode = Control.FOCUS_NONE
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	_refresh_look()

func _refresh_look() -> void:
	var normal := _make_style(BG_COLOR, BG_COLOR.lerp(accent_color, 0.5))
	var hover := _make_style(BG_COLOR.lerp(accent_color, 0.2), accent_color)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)
	add_theme_stylebox_override("hover_pressed", hover)
	add_theme_stylebox_override("disabled", normal)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_color_override("font_color", IDLE_COLOR)
	for color_name: String in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		add_theme_color_override(color_name, accent_color)
	queue_redraw()

func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(1)
	style.border_color = border
	style.anti_aliasing = false
	return style

func _draw() -> void:
	if not is_hovered():
		return
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var selector_width := font.get_string_size(SELECTOR, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x := floorf((size.x - text_width) / 2.0 - selector_width - SELECTOR_GAP)
	var y := floorf((size.y - font.get_height(font_size)) / 2.0 + font.get_ascent(font_size))
	draw_string(font, Vector2(x, y), SELECTOR, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, accent_color)
