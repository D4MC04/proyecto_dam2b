class_name TurnArrow
extends Control

# Flecha en el borde de la pantalla para girar la silla a la vista de al lado: placa de metal
# oscuro con un doble chevrón cian que se ilumina y se adelanta al pasar el ratón.

signal pressed

## -1 apunta a la izquierda, 1 a la derecha.
@export var direction: int = -1

const PLATE: Rect2i = Rect2i(0, 0, 22, 44)
const CHEVRON_HEIGHT: int = 6

var _hovered: bool = false
var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void: _hovered = true)
	mouse_exited.connect(func() -> void: _hovered = false)
	visibility_changed.connect(func() -> void: _hovered = false)

func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit()

func _draw() -> void:
	OfficePaint.wall_box(self, PLATE)
	OfficePaint.screen(self, PLATE.grow(-3))
	var shift: int = direction * (2 if _hovered else int(fmod(_time, 1.2) < 0.6))
	# Punta del chevrón delantero (el más cercano al borde) y el de detrás, 5 px más adentro.
	var lead_x: int = (5 if direction < 0 else 16) + shift
	_draw_chevron(Vector2i(lead_x - direction * 5, 22), OfficePaint.CYAN if _hovered else OfficePaint.CYAN_DARK)
	_draw_chevron(Vector2i(lead_x, 22), OfficePaint.CYAN_LIGHT if _hovered else OfficePaint.CYAN)

# Chevrón de 2 px de grueso con la punta en `tip`, abierto hacia el lado contrario a `direction`.
func _draw_chevron(tip: Vector2i, color: Color) -> void:
	for i: int in CHEVRON_HEIGHT:
		var x: int = tip.x - direction * i
		OfficePaint.rect(self, Rect2i(mini(x, x - direction), tip.y - i, 2, 1), color)
		OfficePaint.rect(self, Rect2i(mini(x, x - direction), tip.y + i, 2, 1), color)
