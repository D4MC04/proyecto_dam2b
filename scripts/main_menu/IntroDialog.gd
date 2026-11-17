extends Control
class_name IntroDialog
## Llamada de socorro de NOVA al empezar una partida nueva, sobre el espacio del menú y antes del salto
## al hiperespacio del nivel de emergencia. Mismo recuadro que el tutorial del nivel de emergencia
## (retrato, nombre, 2 líneas por página y flecha para seguir). No se salta: cada clic, Intro o Espacio
## completa el texto que se escribe o pasa a la página siguiente.

# Una clave de textos.csv por página.
const PAGES: Array[String] = ["INTRO_CALL_1", "INTRO_CALL_2", "INTRO_CALL_3", "INTRO_CALL_4"]
# Segundos por carácter del texto que va apareciendo, como si hablara.
const TYPE_TIME_PER_CHAR: float = 0.02
# Fundido de entrada y de salida del recuadro.
const FADE_TIME: float = 0.2
# Flecha de "sigue": triángulo de 7 px de ancho que sube y baja.
const ARROW_COLOR: Color = Color("#ecb23c")
const ARROW_WIDTH: int = 7
const ARROW_ROWS: int = 4
const ARROW_BOB_PX: float = 2.0
const ARROW_BOB_TIME: float = 0.8

signal finished

@onready var box: Control = %Box
@onready var message_label: Label = %MessageLabel
@onready var continue_arrow: Control = %ContinueArrow

var _page: int = 0
var _typing: Tween
var _fade: Tween
var _time: float = 0.0
var _playing: bool = false
var _closing: bool = false

func _ready() -> void:
	continue_arrow.draw.connect(_draw_continue_arrow)
	_set_open(false)

func _process(delta: float) -> void:
	_time += delta
	if continue_arrow.visible:
		continue_arrow.queue_redraw()

## Lanza la llamada y espera a que acabe la última página.
func play() -> void:
	_page = 0
	_closing = false
	_set_open(true)
	box.modulate.a = 0.0
	_fade = create_tween()
	_fade.tween_property(box, "modulate:a", 1.0, FADE_TIME)
	_type_page()
	await finished

func _set_open(open: bool) -> void:
	_playing = open
	visible = open
	mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	set_process(open)
	set_process_input(open)

# La página actual aparece letra a letra.
func _type_page() -> void:
	continue_arrow.hide()
	message_label.text = tr(PAGES[_page])
	message_label.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(message_label, "visible_ratio", 1.0, message_label.text.length() * TYPE_TIME_PER_CHAR)
	_typing.tween_callback(_on_page_typed)

func _on_page_typed() -> void:
	message_label.visible_ratio = 1.0
	continue_arrow.show()

# Un clic izquierdo, Intro o Espacio: completa el texto, pasa de página o, en la última, cierra.
func _input(event: InputEvent) -> void:
	if not _playing or _closing:
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	var is_click: bool = click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT
	var is_key: bool = event is InputEventKey and event.is_pressed() and not (event as InputEventKey).echo
	if not is_click and not is_key and not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	if message_label.visible_ratio < 1.0:
		_typing.kill()
		_on_page_typed()
	elif _page < PAGES.size() - 1:
		_page += 1
		_type_page()
	else:
		_close()

func _close() -> void:
	_closing = true
	continue_arrow.hide()
	_fade = create_tween()
	_fade.tween_property(box, "modulate:a", 0.0, FADE_TIME)
	await _fade.finished
	_set_open(false)
	finished.emit()

# Flecha de "sigue" abajo a la derecha del recuadro: un triángulo que apunta abajo y sube y baja.
func _draw_continue_arrow() -> void:
	var bob: float = roundf((sin(_time * TAU / ARROW_BOB_TIME) + 1.0) / 2.0 * ARROW_BOB_PX)
	for row: int in ARROW_ROWS:
		continue_arrow.draw_rect(Rect2(row, row + bob, ARROW_WIDTH - row * 2, 1), ARROW_COLOR)
