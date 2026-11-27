class_name StatsCloseUp
extends Control

# Monitor de stats de cerca: las estadísticas del menú principal. MainMenu se acerca al monitor de la
# pared izquierda (CombatScoreboard) y, al final del zoom, aparece este encima, en el mismo sitio. El
# marco es el del monitor (el trozo de left_static.png, a escala BODY_SCALE, así que encaja con la
# oficina acercada) y la pantalla enseña lo mismo que la de lejos (StatsPainter), pero a resolución
# completa y con ratón: con él encima de una barra se lee el nombre de la torreta. "Volver", Escape (lo
# lleva MainMenu) o un clic fuera del monitor emiten back_pressed.

signal back_pressed

const ROOM: Texture2D = preload("res://assets/sprites/office/left_static.png")
const VIEW_SIZE: Vector2i = Vector2i(960, 540)
## Aumento del monitor de la oficina: el zoom de MainMenu acaba con él a este tamaño, y la pantalla de
## cerca (StatsPainter.SIZE) es la de lejos por este aumento.
const BODY_SCALE: float = 1.5

var _monitor: Rect2i
# Marco (el monitor entero) y pantalla, en coordenadas del nodo.
var _body: Rect2i
var _screen: Rect2i
var _frame: AtlasTexture = AtlasTexture.new()
## El de CombatScoreboard (lo pone MainMenu): de cerca sigue igual que de lejos, sin saltos.
var painter: StatsPainter

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var m: Array = OfficeLayout.LEFT.stats.rect
	var s: Array = OfficeLayout.LEFT.stats.screen
	_monitor = Rect2i(m[0], m[1], m[2], m[3])
	_frame.atlas = ROOM
	_frame.region = Rect2(_monitor)
	var body_size: Vector2i = Vector2i((Vector2(_monitor.size) * BODY_SCALE).round())
	@warning_ignore("integer_division")
	_body = Rect2i((VIEW_SIZE - body_size) / 2, body_size)
	_screen = Rect2i(_body.position + Vector2i((Vector2(s[0] - m[0], s[1] - m[1]) * BODY_SCALE).round()), StatsPainter.SIZE)

## Rectángulo del monitor en la vista: el zoom de MainMenu acaba con el de la oficina justo aquí.
func get_body_rect() -> Rect2:
	return Rect2(_body)

# Al irse, la barra y "Volver" dejan de estar marcados (también de lejos).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and painter:
		painter.hovered_bar = -1
		painter.back_hovered = false

func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion:
		var point: Vector2i = Vector2i(motion.position) - _screen.position
		painter.back_hovered = StatsPainter.BACK_RECT.has_point(point)
		painter.hovered_bar = painter.bar_at(point)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if painter.back_hovered else Control.CURSOR_ARROW
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if painter.back_hovered or not _body.has_point(Vector2i(click.position)):
			back_pressed.emit()

func _draw() -> void:
	draw_texture_rect(_frame, Rect2(_body), false)
	# Pilotos del labio, encendidos (en la oficina los pinta OfficeLights encima del PNG).
	for led: Dictionary in OfficeLayout.LEFT.leds:
		var r: Rect2 = Rect2(led.x, led.y, led.w, led.h)
		if Rect2(_monitor).encloses(r):
			draw_rect(Rect2(Vector2(_body.position) + (r.position - Vector2(_monitor.position)) * BODY_SCALE, r.size * BODY_SCALE),
					OfficeLights._palette(led.c))
	# Las líneas de la pantalla de lejos (una oscura cada dos filas), aumentadas como en el zoom.
	var rows: int = roundi(_screen.size.y / BODY_SCALE)
	for row: int in rows:
		var top: int = floori(row * BODY_SCALE)
		OfficePaint.rect(self, Rect2i(_screen.position.x, _screen.position.y + top, _screen.size.x, floori((row + 1) * BODY_SCALE) - top),
				OfficePaint.SCREEN_DARK if row % 2 == 1 else OfficePaint.SCREEN)
	draw_set_transform(Vector2(_screen.position))
	painter.draw(self)
	draw_set_transform(Vector2.ZERO)
