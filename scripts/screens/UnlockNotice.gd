extends Control
class_name UnlockNotice
## Mini pantalla de aviso de desbloqueos, reutilizable: recibe una lista de `UnlockInfo` con `show_unlocks()`,
## los enseña uno tras otro (icono, tipo, nombre y una frase) y emite `finished` al cerrar el último. No sabe
## qué se desbloquea ni desde dónde se abre. Un clic en "Siguiente", Intro o Espacio pasan al siguiente;
## mientras está abierta se come el ratón y el teclado (Escape incluido).

## Se han enseñado todos los avisos y la pantalla se ha cerrado.
signal finished

# Fundido de la pantalla al abrir y de cada aviso al aparecer.
const FADE_TIME: float = 0.25
# El recuadro del aviso entra desde esta escala hasta 1.
const POP_SCALE: float = 0.92
# El icono se amplía en enteros hasta caber en este lado (en píxeles).
const ICON_BOX: int = 96
const NEXT_KEY: String = "BTN_NEXT"
const LAST_KEY: String = "BTN_RESUME"

@onready var panel: OverlayFrame = %Panel
@onready var icon_frame: OverlayFrame = %IconFrame
@onready var icon_rect: TextureRect = %IconRect
@onready var kind_label: Label = %KindLabel
@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %TextLabel
@onready var counter_label: Label = %CounterLabel
@onready var next_button: Button = %NextButton

var _items: Array[UnlockInfo] = []
var _index: int = 0
var _tween: Tween

func _ready() -> void:
	next_button.pressed.connect(_next)
	_set_open(false)

## Si hay algún aviso abierto.
func is_open() -> bool:
	return visible

## Enseña los avisos uno tras otro; emite `finished` al cerrar el último. Con la lista vacía no hace nada.
## Si ya hay avisos en pantalla, los nuevos se añaden al final de la cola.
func show_unlocks(items: Array[UnlockInfo]) -> void:
	if items.is_empty():
		return
	if visible:
		_items.append_array(items)
		counter_label.text = "%d / %d" % [_index + 1, _items.size()]
		counter_label.visible = true
		next_button.text = tr(NEXT_KEY)
		return
	_items = items
	_index = 0
	_set_open(true)
	_show_current()

func _set_open(open: bool) -> void:
	visible = open
	mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	set_process_input(open)

# Pone los datos del aviso actual y lo hace aparecer con un fundido y un pequeño salto de escala.
func _show_current() -> void:
	var info: UnlockInfo = _items[_index]
	panel.accent_color = info.accent
	icon_frame.accent_color = info.accent
	kind_label.text = tr(info.kind_key)
	kind_label.add_theme_color_override(&"font_color", info.accent)
	name_label.text = info.title
	text_label.text = info.text
	text_label.visible = not info.text.is_empty()
	_set_icon(info.icon)
	icon_rect.modulate = info.icon_tint
	counter_label.text = "%d / %d" % [_index + 1, _items.size()]
	counter_label.visible = _items.size() > 1
	next_button.text = tr(LAST_KEY if _index == _items.size() - 1 else NEXT_KEY)
	# El tamaño del panel cambia con el texto: se escala desde el centro del tamaño que le va a tocar.
	panel.pivot_offset = panel.get_combined_minimum_size() / 2.0
	panel.scale = Vector2.ONE * POP_SCALE
	modulate.a = 0.0 if _index == 0 else 1.0
	panel.modulate.a = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(panel, "scale", Vector2.ONE, FADE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(panel, "modulate:a", 1.0, FADE_TIME)
	if _index == 0:
		_tween.tween_property(self, "modulate:a", 1.0, FADE_TIME)

# Icono en píxeles: se amplía en enteros (sin emborronar) hasta caber en ICON_BOX.
func _set_icon(texture: Texture2D) -> void:
	icon_rect.texture = texture
	if texture == null:
		icon_rect.custom_minimum_size = Vector2.ONE * ICON_BOX
		return
	var side: int = maxi(texture.get_width(), texture.get_height())
	var factor: int = maxi(1, ICON_BOX / maxi(side, 1))
	icon_rect.custom_minimum_size = Vector2(texture.get_size()) * factor

func _next() -> void:
	if _index < _items.size() - 1:
		_index += 1
		_show_current()
		return
	_set_open(false)
	_items = []
	finished.emit()

# Intro o Espacio pasan al siguiente; el resto del teclado y Escape no llegan al menú de detrás.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo and (key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]):
			_next()
		get_viewport().set_input_as_handled()
