class_name OfficeTutorial
extends Control
## Tutorial de la oficina: la última fase del tutorial de una partida nueva. Sale la primera vez que se
## llega a la oficina después del nivel de emergencia (ganado, saltado o abandonado). NOVA, con el mismo
## recuadro y el mismo foco que en el nivel de emergencia (mientras habla se oscurece todo menos su
## recuadro y lo que señala), pide girar la silla y mirar las dos vistas de los lados (allí calla y se
## puede tocar todo), enseña la mesa de Sectores y la consola de opciones y deja lo demás para explorar.
## No se salta. Hecho, no vuelve a salir en la ranura; si se sale a medias, vuelve a empezar.

enum Step { WELCOME, TURN, TURN_OTHER, RADAR, OPTIONS, DONE }

# Una clave de textos.csv por paso; un `|` en el texto corta página.
const TEXTS: Dictionary[Step, String] = {
	Step.WELCOME: "OFFICE_TUTORIAL_WELCOME",
	Step.TURN: "OFFICE_TUTORIAL_TURN",
	Step.TURN_OTHER: "OFFICE_TUTORIAL_TURN_OTHER",
	Step.RADAR: "OFFICE_TUTORIAL_RADAR",
	Step.OPTIONS: "OFFICE_TUTORIAL_OPTIONS",
	Step.DONE: "OFFICE_TUTORIAL_DONE",
}
# Bienvenida si se ganó el nivel de emergencia: NOVA empieza felicitando.
const WELCOME_WON_TEXT: String = "OFFICE_TUTORIAL_WELCOME_WON"
const PAGE_BREAK: String = "|"
# Paso al que lleva pasar la última página con un clic. Los de girar no están: esperan al giro.
const NEXT_STEP: Dictionary[Step, Step] = {
	Step.WELCOME: Step.TURN,
	Step.RADAR: Step.OPTIONS,
	Step.OPTIONS: Step.DONE,
}
# Pasos que esperan a que el jugador mire las dos vistas de los lados; solo en ellos se puede girar.
const TURN_STEPS: Array[Step] = [Step.TURN, Step.TURN_OTHER]
# Ancho del hueco de cada borde de girar: estrecho, para que se vea que hay que llevar el ratón al borde.
const TURN_FOCUS_WIDTH: float = 24.0
# Segundos que se ve la oficina antes de que NOVA empiece a hablar.
const START_DELAY: float = 0.5
# Segundos por carácter del texto que va apareciendo, como si hablara.
const TYPE_TIME_PER_CHAR: float = 0.02
# Fundido del recuadro y del oscurecido.
const FADE_TIME: float = 0.2
const DIM_ALPHA: float = 0.6
const HIGHLIGHT_COLOR: Color = Color("#ecb23c")
# Medio ciclo del parpadeo del borde, en segundos.
const HIGHLIGHT_BLINK_TIME: float = 0.4
# Margen del hueco y de su borde respecto a lo señalado.
const HIGHLIGHT_GROW: float = 2.0
# Flecha de "sigue": triángulo de 7 px de ancho que sube y baja.
const ARROW_COLOR: Color = Color("#ecb23c")
const ARROW_WIDTH: int = 7
const ARROW_ROWS: int = 4
const ARROW_BOB_PX: float = 2.0
const ARROW_BOB_TIME: float = 0.8

@onready var box: Control = $Box
@onready var message_label: Label = $Box/Margin/Row/Column/MessageLabel
@onready var continue_arrow: Control = $ContinueArrow

var _running: bool = false
# El recuadro ya está a la vista y NOVA habla (tras START_DELAY).
var _talking: bool = false
var _step: Step = Step.WELCOME
var _pages: PackedStringArray = PackedStringArray()
var _page: int = 0
var _won: bool = false
var _radar: OfficeObject
var _options: OfficeObject
# Vistas de los lados ya vistas: izquierda y derecha.
var _seen: Array[bool] = [false, false]
# El jugador mira una vista de los lados: NOVA calla (sin recuadro ni oscurecido) y la oficina responde.
var _away: bool = false
var _typing: Tween
var _box_tween: Tween
var _dim_tween: Tween
var _dim_alpha: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	continue_arrow.draw.connect(_draw_continue_arrow)
	_set_open(false)

## Empieza el tutorial. `won`: si se ganó el nivel de emergencia (NOVA felicita). `radar` y `options`
## son la mesa de Sectores y la consola de opciones de la vista central, lo que se señala.
func start(won: bool, radar: OfficeObject, options: OfficeObject) -> void:
	_won = won
	_radar = radar
	_options = options
	_running = true
	_talking = false
	_seen = [false, false]
	_away = false
	_set_open(true)
	continue_arrow.hide()
	message_label.text = ""
	box.modulate.a = 0.0
	await get_tree().create_timer(START_DELAY).timeout
	if not _running:
		return
	_fade_box(1.0)
	_talking = true
	_enter(Step.WELCOME)

## Mientras dura, no se gira la silla salvo cuando NOVA lo pide (ver allows_turn()).
func is_running() -> bool:
	return _running

## Se puede girar la silla en los pasos de girar: en el primero, cuando NOVA ha acabado de pedirlo; en
## los lados y al pedir el otro lado, siempre (para no frenar al que ya va hacia allí).
func allows_turn() -> bool:
	if not _talking or _step not in TURN_STEPS:
		return false
	return _away or _step == Step.TURN_OTHER or _talk_done()

## MainMenu avisa al acabar cada giro de la silla: `side` -1 (vista izquierda), 0 (centro) o 1 (derecha).
func on_turned(side: int) -> void:
	if not _talking or _step not in TURN_STEPS:
		return
	if side != 0:
		# En los lados NOVA calla: se esconde el recuadro y el oscurecido.
		_seen[0 if side < 0 else 1] = true
		if not _away:
			_set_away(true)
			if _typing:
				_typing.kill()
			continue_arrow.hide()
			_fade_box(0.0)
			_fade_dim(false)
		return
	if not _away:
		return
	_set_away(false)
	_fade_box(1.0)
	_enter(Step.RADAR if _seen[0] and _seen[1] else Step.TURN_OTHER)

func _set_open(open: bool) -> void:
	visible = open
	# Parado el ratón, los objetos de la oficina no se marcan ni se pulsan mientras habla NOVA.
	mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	set_process(open)
	set_process_input(open)

# En los lados se deja el ratón y las teclas a la oficina: se puede mirar y tocar todo (la puerta y
# Escape incluidos; si se vuelve al inicio, el tutorial vuelve a salir al entrar en la ranura).
func _set_away(away: bool) -> void:
	_away = away
	mouse_filter = Control.MOUSE_FILTER_IGNORE if away else Control.MOUSE_FILTER_STOP
	set_process_input(not away)

func _process(delta: float) -> void:
	_time += delta
	if continue_arrow.visible:
		continue_arrow.queue_redraw()
	queue_redraw()

# --- Pasos y páginas -----------------------------------------------------------------------

func _enter(step: Step) -> void:
	_step = step
	var key: String = WELCOME_WON_TEXT if step == Step.WELCOME and _won else TEXTS[step]
	_pages = tr(key).split(PAGE_BREAK, false)
	_page = 0
	_fade_dim(true)
	_type_page()

# La página actual aparece letra a letra.
func _type_page() -> void:
	continue_arrow.hide()
	message_label.text = _pages[_page].strip_edges()
	message_label.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(message_label, "visible_ratio", 1.0, message_label.text.length() * TYPE_TIME_PER_CHAR)
	_typing.tween_callback(_on_page_typed)

# Al acabar de escribirse, la flecha si un clic lleva a algo (no en la última página de girar).
func _on_page_typed() -> void:
	message_label.visible_ratio = 1.0
	continue_arrow.visible = not _is_last_page() or _step not in TURN_STEPS

func _is_last_page() -> bool:
	return _page >= _pages.size() - 1

func _talk_done() -> bool:
	return _is_last_page() and message_label.visible_ratio >= 1.0

# Un clic, Intro o Espacio: completa el texto, pasa de página o de paso. Los de girar esperan al giro.
func _advance() -> void:
	if not _talking or _away:
		return
	if message_label.visible_ratio < 1.0:
		_typing.kill()
		_on_page_typed()
	elif not _is_last_page():
		_page += 1
		_type_page()
	elif _step == Step.DONE:
		_finish()
	elif NEXT_STEP.has(_step):
		_enter(NEXT_STEP[_step])

# Acaba al pasar la despedida: queda hecho en la ranura.
func _finish() -> void:
	if not _running:
		return
	_running = false
	_talking = false
	GameState.complete_office_tutorial()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(false)
	continue_arrow.hide()
	_fade_dim(false)
	_fade_box(0.0)
	await _box_tween.finished
	_set_open(false)

func _input(event: InputEvent) -> void:
	if not _running:
		return
	# No se salta: Escape no hace nada (ni abre "¿Volver al inicio?").
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	var is_click: bool = click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT
	if not is_click and not event.is_action_pressed(&"ui_accept"):
		return
	get_viewport().set_input_as_handled()
	_advance()

# --- Recuadro y foco -----------------------------------------------------------------------

func _fade_box(target: float) -> void:
	if _box_tween:
		_box_tween.kill()
	_box_tween = create_tween()
	_box_tween.tween_property(box, "modulate:a", target, FADE_TIME)

func _fade_dim(on: bool) -> void:
	if _dim_tween:
		_dim_tween.kill()
	_dim_tween = create_tween()
	_dim_tween.tween_property(self, "_dim_alpha", DIM_ALPHA if on else 0.0, FADE_TIME)

func _blink_on() -> bool:
	return fmod(_time, HIGHLIGHT_BLINK_TIME * 2.0) < HIGHLIGHT_BLINK_TIME

# Mientras habla NOVA, todo oscuro menos su recuadro (hijo, encima) y lo señalado, con su borde ámbar
# parpadeando. Al acabar, el oscurecido se desvanece entero, ya sin huecos.
func _draw() -> void:
	if _dim_alpha <= 0.0:
		return
	var dim: Color = Color(0.0, 0.0, 0.0, _dim_alpha)
	match _step if _talking else Step.DONE:
		Step.TURN, Step.TURN_OTHER:
			_draw_turn_focus(dim)
		Step.RADAR:
			_draw_object_focus(_radar, dim)
		Step.OPTIONS:
			_draw_object_focus(_options, dim)
		_:
			draw_rect(Rect2(Vector2.ZERO, size), dim)

# Girar la silla: una franja estrecha en cada borde que lleva a una vista aún sin ver.
func _draw_turn_focus(dim: Color) -> void:
	var edge: float = TURN_FOCUS_WIDTH
	var left: bool = not _seen[0]
	var right: bool = not _seen[1]
	var x0: float = edge if left else 0.0
	var x1: float = size.x - edge if right else size.x
	draw_rect(Rect2(x0, 0.0, x1 - x0, size.y), dim)
	if not _blink_on():
		return
	if left:
		draw_rect(Rect2(0.5, 0.5, edge - 1.0, size.y - 1.0), HIGHLIGHT_COLOR, false, 1.0)
	if right:
		draw_rect(Rect2(size.x - edge + 0.5, 0.5, edge - 1.0, size.y - 1.0), HIGHLIGHT_COLOR, false, 1.0)

# Un objeto de la consola: hueco con la forma de su trapecio inclinado (arriba y abajo horizontales).
func _draw_object_focus(target: OfficeObject, dim: Color) -> void:
	var quad: PackedVector2Array = _focus_quad(target)
	var top: float = quad[0].y
	var bottom: float = quad[3].y
	draw_rect(Rect2(0.0, 0.0, size.x, top), dim)
	draw_rect(Rect2(0.0, bottom, size.x, size.y - bottom), dim)
	draw_colored_polygon(PackedVector2Array([Vector2(0.0, top), quad[0], quad[3], Vector2(0.0, bottom)]), dim)
	draw_colored_polygon(PackedVector2Array([quad[1], Vector2(size.x, top), Vector2(size.x, bottom), quad[2]]), dim)
	if _blink_on():
		var line: PackedVector2Array = PackedVector2Array()
		for point: Vector2 in quad:
			line.append(point + Vector2(0.5, 0.5))
		line.append(line[0])
		draw_polyline(line, HIGHLIGHT_COLOR, 1.0)

# Contorno del objeto (su trapecio, o su rectángulo) en coordenadas de este control, crecido
# HIGHLIGHT_GROW hacia fuera. Orden: arriba izquierda, arriba derecha, abajo derecha, abajo izquierda.
func _focus_quad(target: OfficeObject) -> PackedVector2Array:
	var corners: PackedVector2Array = target.hover_quad()
	if corners.is_empty():
		var rect: Rect2 = Rect2(target.hover_rect())
		corners = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
				Vector2(rect.position.x, rect.end.y)])
	var to_local: Transform2D = get_global_transform().affine_inverse() * target.get_global_transform()
	var grow: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	var quad: PackedVector2Array = PackedVector2Array()
	for i: int in 4:
		quad.append((to_local * corners[i] + grow[i] * HIGHLIGHT_GROW).round())
	return quad

# Flecha de "sigue" abajo a la derecha del recuadro: un triángulo que apunta abajo y sube y baja.
func _draw_continue_arrow() -> void:
	var bob: float = roundf((sin(_time * TAU / ARROW_BOB_TIME) + 1.0) / 2.0 * ARROW_BOB_PX)
	for row: int in ARROW_ROWS:
		continue_arrow.draw_rect(Rect2(row, row + bob, ARROW_WIDTH - row * 2, 1), ARROW_COLOR)
