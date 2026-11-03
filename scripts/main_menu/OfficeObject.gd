class_name OfficeObject
extends Control

# Objeto de la oficina del menú que se pulsa con el ratón. Al pasar por encima se marca con
# corchetes en L (los del panel holograma) y sale encima un rótulo con lo que abre. Cada objeto
# pinta su dibujo en _draw_object(), en píxeles enteros, y se redibuja cada frame para animarse.

signal pressed

## Rótulo que sale encima del objeto al pasar el ratón.
@export var label_text := ""

# Rótulo: márgenes del texto, recorte de las esquinas y hueco hasta los corchetes.
const TAG_PADDING := Vector2i(6, 2)
const TAG_CLIP := 2
const TAG_GAP := 4
const TAG_BG := Color("#13414f")

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
	if hovered:
		var r := Rect2i(Vector2i.ZERO, Vector2i(size))
		OfficePaint.brackets(self, r, OfficePaint.CYAN_LIGHT)
		_draw_tag()

## Dibujo del objeto, en coordenadas locales dentro de `size`.
func _draw_object() -> void:
	pass

# Rótulo centrado encima de los corchetes: caja recortada cian con el texto en claro.
func _draw_tag() -> void:
	if label_text.is_empty():
		return
	var width := OfficePaint.text_width(label_text) + TAG_PADDING.x * 2
	var height := OfficePaint.TEXT_HEIGHT + TAG_PADDING.y * 2
	@warning_ignore("integer_division")
	var box := Rect2i(int(size.x) / 2 - width / 2, -4 - TAG_GAP - height, width, height)
	var ci := get_canvas_item()
	ClippedBoxStyle.fill_inside(ci, box, TAG_CLIP, TAG_BG)
	ClippedBoxStyle.draw_outline(ci, box, TAG_CLIP, OfficePaint.CYAN)
	OfficePaint.text(self, box.position + TAG_PADDING, label_text, OfficePaint.CYAN_LIGHT)
