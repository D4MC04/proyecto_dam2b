extends Control
class_name TutorialHints
## Tutorial del nivel 1: el astronauta guía da un mensaje cada vez en un recuadro abajo del área de
## juego y cada paso espera a que el jugador haga lo que se pide. Un borde parpadeante señala lo que
## hay que pulsar. Al acabarlo o saltarlo se guarda en GameState y no vuelve a salir.

enum Step { PICK_TURRET, PLACE_TURRET, START_WAVE, WAIT_WAVE_END, INSPECT_TURRET, FUSE_INFO, POWERS, DONE }

const TEXTS: Dictionary[Step, String] = {
	Step.PICK_TURRET: "¡Hola, recluta! Los enemigos vienen a por la estación. Elige una torreta en la barra de la derecha.",
	Step.PLACE_TURRET: "Bien. Ahora haz clic en un asteroide con plataforma libre para colocarla.",
	Step.START_WAVE: "Lista la defensa. Abre la pestaña Oleadas y pulsa Siguiente oleada (o Espacio).",
	Step.INSPECT_TURRET: "¡Oleada superada! Suelta la torreta de la tienda con clic derecho y haz clic en una de las tuyas del mapa para ver su ficha.",
	Step.FUSE_INFO: "Desde la ficha puedes venderla o, si tiene mejora, pulsar Mejorar para convertirla en una más fuerte.",
	Step.POWERS: "Tienes dos poderes en la ficha: Q lanza un meteorito y E congela a los enemigos. Prueba uno.",
	Step.DONE: "¡Eso es! El resto es cosa tuya. Suerte ahí fuera.",
}
# Pasos que no esperan una acción del juego: se cierran con "Entendido".
const INFO_STEPS: Array[Step] = [Step.FUSE_INFO, Step.DONE]
# Segundos por carácter del texto que va apareciendo, como si hablara.
const TYPE_TIME_PER_CHAR := 0.02
# El último mensaje se cierra solo tras estos segundos.
const DONE_HIDE_TIME := 4.0
const HIGHLIGHT_COLOR := Color("#ecb23c")
# Medio ciclo del parpadeo del borde, en segundos.
const HIGHLIGHT_BLINK_TIME := 0.4
# Separación del borde respecto al control señalado.
const HIGHLIGHT_GROW := 2

@onready var box: Control = %Box
@onready var message_label: Label = %MessageLabel
@onready var ok_button: Button = %OkButton
@onready var skip_button: Button = %SkipButton

var sidebar: Sidebar
var info_panel: InfoPanel

var _step := Step.DONE
var _active := false
var _typing: Tween
var _blink_time := 0.0

func _ready() -> void:
	ok_button.pressed.connect(_on_ok_pressed)
	skip_button.pressed.connect(_finish)
	_set_active(false)

## Empieza el tutorial con el nivel recién montado. Las señales del nivel anterior se van con él.
func start(state: LevelState, spawner: Spawner, powers: Powers) -> void:
	state.selected_turret_changed.connect(_on_selected_turret_changed)
	state.turret_placed.connect(_advance_from.bind(Step.PLACE_TURRET, Step.START_WAVE))
	state.sellable_turret_changed.connect(func(turret: Turret) -> void:
		if turret != null:
			_advance_from(Step.INSPECT_TURRET, Step.FUSE_INFO))
	spawner.wave_started.connect(_on_wave_started.unbind(2))
	# bind y unbind se aplican de derecha a izquierda: se quita el argumento de la señal y se añaden los pasos.
	spawner.wave_cleared.connect(_advance_from.bind(Step.WAIT_WAVE_END, Step.INSPECT_TURRET).unbind(1))
	powers.power_used.connect(_advance_from.bind(Step.POWERS, Step.DONE).unbind(1))
	_set_active(true)
	_show_step(Step.PICK_TURRET)

## Quita el tutorial sin guardar nada (otro nivel o ya hecho).
func stop() -> void:
	_set_active(false)

func _set_active(active: bool) -> void:
	_active = active
	box.visible = active
	set_process(active)
	queue_redraw()

func _show_step(step: Step) -> void:
	_step = step
	# Mientras corre la oleada 1 no hay nada que pedir: el recuadro se esconde hasta que acabe.
	box.visible = step != Step.WAIT_WAVE_END
	ok_button.visible = step in INFO_STEPS
	if TEXTS.has(step):
		message_label.text = TEXTS[step]
		message_label.visible_ratio = 0.0
		if _typing:
			_typing.kill()
		_typing = create_tween()
		_typing.tween_property(message_label, "visible_ratio", 1.0, TEXTS[step].length() * TYPE_TIME_PER_CHAR)
	if step == Step.DONE:
		_typing.tween_interval(DONE_HIDE_TIME)
		_typing.tween_callback(_finish)
	queue_redraw()

# Pasa a `next` solo si el tutorial está en `from`.
func _advance_from(from: Step, next: Step) -> void:
	if _active and _step == from:
		_show_step(next)

# Elegir torreta avanza; soltarla antes de colocarla vuelve a pedirla.
func _on_selected_turret_changed(data: TurretData) -> void:
	if data != null:
		_advance_from(Step.PICK_TURRET, Step.PLACE_TURRET)
	else:
		_advance_from(Step.PLACE_TURRET, Step.PICK_TURRET)

# Lanzar la oleada 1 antes de tiempo también vale: el tutorial espera a que acabe.
func _on_wave_started() -> void:
	if _active and _step < Step.WAIT_WAVE_END:
		_show_step(Step.WAIT_WAVE_END)

func _on_ok_pressed() -> void:
	if _step == Step.FUSE_INFO:
		_show_step(Step.POWERS)
	elif _step == Step.DONE:
		_finish()

func _finish() -> void:
	if not _active:
		return
	GameState.complete_tutorial()
	_set_active(false)

func _process(delta: float) -> void:
	_blink_time += delta
	queue_redraw()

# Lo que hay que pulsar en el paso actual; null si no hay nada que señalar.
func _highlight_target() -> Control:
	match _step:
		Step.PICK_TURRET:
			return sidebar.turret_buttons if sidebar.turrets_page.visible else sidebar.turrets_tab
		Step.START_WAVE:
			return sidebar.next_wave_button if sidebar.waves_page.visible else sidebar.waves_tab
		Step.POWERS:
			return info_panel.meteor_button.get_parent()
	return null

func _draw() -> void:
	if not _active or not box.visible or fmod(_blink_time, HIGHLIGHT_BLINK_TIME * 2.0) >= HIGHLIGHT_BLINK_TIME:
		return
	var target := _highlight_target()
	if target == null:
		return
	var rect := Rect2(target.global_position - global_position, target.size).grow(HIGHLIGHT_GROW)
	draw_rect(rect, HIGHLIGHT_COLOR, false, 1.0)
