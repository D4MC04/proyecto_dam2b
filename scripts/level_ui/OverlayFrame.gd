extends PanelContainer
class_name OverlayFrame

# Panel con marco de las pantallas superpuestas: fondo casi opaco, borde de 1 px y esquinas marcadas en el acento.

const BG_COLOR := Color("#0a0f1a")
const BG_ALPHA := 0.96
const CORNER_LENGTH := 5
const CORNER_THICKNESS := 2

@export var accent_color: Color = Color("#40e0f0"):
	set(value):
		accent_color = value
		_refresh_style()

func _ready() -> void:
	_refresh_style()

func _refresh_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(BG_COLOR, BG_ALPHA)
	style.set_border_width_all(1)
	style.border_color = accent_color
	style.anti_aliasing = false
	add_theme_stylebox_override("panel", style)
	queue_redraw()

func _draw() -> void:
	var right := size.x
	var bottom := size.y
	var length := float(CORNER_LENGTH)
	var thick := float(CORNER_THICKNESS)
	# Cada esquina son dos rectángulos en L.
	draw_rect(Rect2(0, 0, length, thick), accent_color)
	draw_rect(Rect2(0, 0, thick, length), accent_color)
	draw_rect(Rect2(right - length, 0, length, thick), accent_color)
	draw_rect(Rect2(right - thick, 0, thick, length), accent_color)
	draw_rect(Rect2(0, bottom - thick, length, thick), accent_color)
	draw_rect(Rect2(0, bottom - length, thick, length), accent_color)
	draw_rect(Rect2(right - length, bottom - thick, length, thick), accent_color)
	draw_rect(Rect2(right - thick, bottom - length, thick, length), accent_color)
