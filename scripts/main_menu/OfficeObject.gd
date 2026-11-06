class_name OfficeObject
extends Control

# Objeto de la oficina del menú que se pulsa con el ratón. Su dibujo fijo es un PNG de la habitación
# (assets/sprites/office/); aquí solo se anima lo que se mueve (pantallas y luces) en _draw_object(),
# en píxeles enteros, y se redibuja cada frame. Al pasar el ratón se marca con corchetes en L, sin
# rótulo de texto.

signal pressed

## Corchetes en L al pasar el ratón (la puerta no los lleva: se entreabre).
@export var show_brackets := true

var hovered := false
## Segundos desde que se creó, para las animaciones.
var time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _process(delta: float) -> void:
	time += delta
	# Se mira cada frame, así se apaga también cuando un panel lo tapa sin que se mueva el ratón.
	hovered = is_visible_in_tree() and get_viewport().gui_get_hovered_control() == self
	if is_visible_in_tree():
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit()

func _draw() -> void:
	_draw_object()
	if hovered and show_brackets:
		OfficePaint.brackets(self, hover_rect(), OfficePaint.CYAN_LIGHT)

## Dibujo animado del objeto, en coordenadas locales.
func _draw_object() -> void:
	pass

## Lo que marcan los corchetes al pasar el ratón; por defecto, todo el objeto.
func hover_rect() -> Rect2i:
	return Rect2i(Vector2i.ZERO, Vector2i(size))

## Punto de la vista (de OfficeLayout) en coordenadas locales.
func to_local_point(view_point: Vector2) -> Vector2:
	return view_point - position
