extends Control
class_name TutorialHints
## Tutorial del simulacro (el nivel de prueba): NOVA, el astronauta guía, da un mensaje cada vez en un
## recuadro abajo del área de juego. Cuando pide algo, oscurece la pantalla menos lo que hay que tocar
## (y su recuadro), solo deja hacer eso y no se va hasta que se hace. Entre peticiones se juega libre.

## "Saltar" pulsado dos veces (la segunda confirma): Game sale del simulacro.
signal skip_requested
## La despedida tras ganar se ha cerrado: Game vuelve a la oficina.
signal finished

enum Step { STATION, PLACE_TURRETS, OPEN_WAVES, INSPECT_ENEMY, ENEMY_INFO, START_WAVE, FIRST_WAVE,
		UPGRADE_PICK, UPGRADE_PRESS, SELL_INFO, DONE, FREE, COMPLETE }
# Acciones del jugador que el tutorial puede bloquear; cada sitio donde entran pregunta con allows().
enum Action { SELECT_TURRET, BUILD, RELEASE_TURRET, SELECT_PLACED, TAB_TURRETS, TAB_WAVES, NEXT_WAVE, WAVE_ARROWS,
		TOGGLE_AUTO, TOGGLE_SPEED, UPGRADE, SELL, POWER_METEOR, POWER_FREEZE, POWER_ORBITAL }

# Pasos en los que NOVA pide algo: se oscurece todo menos lo señalado y solo valen las acciones de
# ALLOWED_ACTIONS (un paso sin entrada no deja ninguna). En los demás todo es libre.
const FOCUS_STEPS: Array[Step] = [Step.STATION, Step.PLACE_TURRETS, Step.OPEN_WAVES, Step.INSPECT_ENEMY,
		Step.ENEMY_INFO, Step.START_WAVE, Step.UPGRADE_PICK, Step.UPGRADE_PRESS, Step.SELL_INFO]
const ALLOWED_ACTIONS: Dictionary[Step, Array] = {
	Step.PLACE_TURRETS: [Action.SELECT_TURRET, Action.BUILD, Action.RELEASE_TURRET, Action.TAB_TURRETS],
	Step.OPEN_WAVES: [Action.TAB_WAVES],
	Step.START_WAVE: [Action.NEXT_WAVE],
	Step.UPGRADE_PICK: [Action.SELECT_PLACED, Action.RELEASE_TURRET],
	Step.UPGRADE_PRESS: [Action.SELECT_PLACED, Action.RELEASE_TURRET, Action.UPGRADE],
	Step.SELL_INFO: [Action.SELL],
}
# Pasos sin recuadro: el jugador juega libre hasta que pase algo.
const HIDDEN_STEPS: Array[Step] = [Step.FIRST_WAVE, Step.FREE]

const TEXTS: Dictionary[Step, String] = {
	Step.STATION: "TUTORIAL_STATION",
	Step.PLACE_TURRETS: "TUTORIAL_PLACE_TURRETS",
	Step.OPEN_WAVES: "TUTORIAL_OPEN_WAVES",
	Step.INSPECT_ENEMY: "TUTORIAL_INSPECT_ENEMY",
	Step.ENEMY_INFO: "TUTORIAL_ENEMY_INFO",
	Step.START_WAVE: "TUTORIAL_START_WAVE",
	Step.UPGRADE_PICK: "TUTORIAL_UPGRADE_PICK",
	Step.UPGRADE_PRESS: "TUTORIAL_UPGRADE_PRESS",
	Step.SELL_INFO: "TUTORIAL_SELL_INFO",
	Step.DONE: "TUTORIAL_DONE",
	Step.COMPLETE: "TUTORIAL_COMPLETE",
}
# Texto de UPGRADE_PICK cuando NOVA tiene que poner el dinero que falta para la mejora.
const UPGRADE_GIFT_TEXT: String = "TUTORIAL_UPGRADE_GIFT"
const SKIP_CONFIRM_TEXT: String = "TUTORIAL_SKIP_CONFIRM"
const SKIP_TEXT: String = "TUTORIAL_SKIP"
# Pasos que no esperan una acción del juego: se cierran con "Entendido".
const INFO_STEPS: Array[Step] = [Step.STATION, Step.ENEMY_INFO, Step.SELL_INFO, Step.DONE, Step.COMPLETE]
# Paso al que lleva "Entendido" en cada paso informativo (COMPLETE acaba el simulacro).
const NEXT_AFTER_OK: Dictionary[Step, Step] = {
	Step.STATION: Step.PLACE_TURRETS,
	Step.ENEMY_INFO: Step.START_WAVE,
	Step.SELL_INFO: Step.DONE,
	Step.DONE: Step.FREE,
}
# Mensajes que se cierran solos tras AUTO_CLOSE_TIME si no se pulsa "Entendido".
const AUTO_CLOSE_STEPS: Array[Step] = [Step.DONE, Step.COMPLETE]
const AUTO_CLOSE_TIME: float = 5.0
# Segundos por carácter del texto que va apareciendo, como si hablara.
const TYPE_TIME_PER_CHAR: float = 0.02

# Oscurecido de los pasos con foco: negro a esta opacidad, que entra y sale en DIM_FADE_TIME.
const DIM_ALPHA: float = 0.6
const DIM_FADE_TIME: float = 0.2
const HIGHLIGHT_COLOR: Color = Color("#ecb23c")
# Medio ciclo del parpadeo del borde, en segundos.
const HIGHLIGHT_BLINK_TIME: float = 0.4
# Margen del hueco y de su borde respecto a lo señalado.
const HIGHLIGHT_GROW: int = 2
# Tamaño del hueco sobre cosas del mapa: el asteroide con plataforma (2x2 casillas) y la estación.
const SLOT_SIZE: Vector2 = Vector2(32.0, 32.0)
const STATION_SIZE: Vector2 = Vector2(96.0, 96.0)

@onready var box: Control = %Box
@onready var message_label: Label = %MessageLabel
@onready var ok_button: Button = %OkButton
@onready var skip_button: Button = %SkipButton

var sidebar: Sidebar
var info_panel: InfoPanel
var turret_actions: TurretActions

var _step: TutorialHints.Step = Step.FREE
var _active: bool = false
var _level: Level
var _typing: Tween
var _dim_tween: Tween
var _dim_alpha: float = 0.0
var _blink_time: float = 0.0
var _confirming_skip: bool = false

func _ready() -> void:
	ok_button.pressed.connect(_on_ok_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	_set_active(false)

## Empieza el tutorial con el simulacro recién montado. Las señales del nivel anterior se van con él.
func start(level: Level) -> void:
	_level = level
	var state: LevelState = level.game_state
	state.turret_placed.connect(_on_turret_placed)
	state.inspected_changed.connect(_on_inspected_changed)
	state.sellable_turret_changed.connect(_on_sellable_turret_changed)
	state.upgrade_requested.connect(_on_upgrade_requested)
	level.spawner.wave_started.connect(_on_wave_started.unbind(2))
	level.spawner.wave_cleared.connect(_on_wave_cleared)
	_set_active(true)
	_show_step(Step.STATION)

## Quita el tutorial (cualquier nivel que no sea el simulacro).
func stop() -> void:
	_set_active(false)

## El simulacro se ha ganado: NOVA se despide y, al cerrar el mensaje, emite `finished`.
func show_complete() -> void:
	if _active:
		_show_step(Step.COMPLETE)

## Si el paso actual deja hacer `action`. Sin tutorial en marcha o fuera de los pasos con foco todo vale.
func allows(action: Action) -> bool:
	return not _active or _step not in FOCUS_STEPS or action in ALLOWED_ACTIONS.get(_step, [])

func _set_active(active: bool) -> void:
	_active = active
	box.visible = false
	_dim_alpha = 0.0
	set_process(active)
	queue_redraw()

func _show_step(step: Step) -> void:
	var was_focus: bool = _step in FOCUS_STEPS and box.visible
	_step = step
	_confirming_skip = false
	skip_button.text = tr(SKIP_TEXT)
	# Tras ganar ya no se puede saltar: solo queda la despedida.
	skip_button.visible = step != Step.COMPLETE
	box.visible = step not in HIDDEN_STEPS
	ok_button.visible = step in INFO_STEPS
	if TEXTS.has(step):
		_type_message(tr(TEXTS[step]))
	if step in AUTO_CLOSE_STEPS:
		_typing.tween_interval(AUTO_CLOSE_TIME)
		_typing.tween_callback(_on_ok_pressed)
	var is_focus: bool = step in FOCUS_STEPS
	if is_focus != was_focus:
		_fade_dim(DIM_ALPHA if is_focus else 0.0)
	queue_redraw()

# El texto aparece letra a letra, como si NOVA hablara.
func _type_message(message: String) -> void:
	message_label.text = message
	message_label.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(message_label, "visible_ratio", 1.0, message.length() * TYPE_TIME_PER_CHAR)

func _fade_dim(to_alpha: float) -> void:
	if _dim_tween:
		_dim_tween.kill()
	_dim_tween = create_tween()
	_dim_tween.tween_property(self, "_dim_alpha", to_alpha, DIM_FADE_TIME)

# Pasa a `next` solo si el tutorial está en `from`.
func _advance_from(from: Step, next: Step) -> void:
	if _active and _step == from:
		_show_step(next)

# El paso de colocar acaba cuando no queda ninguna casilla libre (el dinero da justo para las 3).
func _on_turret_placed() -> void:
	if _active and _step == Step.PLACE_TURRETS and _free_slots().is_empty():
		_level.game_state.selected_turret = null
		_show_step(Step.OPEN_WAVES)

func _on_inspected_changed(data: Resource) -> void:
	if data is EnemyData:
		_advance_from(Step.INSPECT_ENEMY, Step.ENEMY_INFO)

# Elegir una torreta del mapa lleva a pulsar Mejorar; soltarla (clic en el vacío o en la interfaz)
# vuelve a pedir que se elija.
func _on_sellable_turret_changed(turret: Turret) -> void:
	if turret != null:
		_advance_from(Step.UPGRADE_PICK, Step.UPGRADE_PRESS)
	else:
		_advance_from(Step.UPGRADE_PRESS, Step.UPGRADE_PICK)

# BuildManager mejora antes (se conectó antes a la señal). Después LevelUI suelta la torreta: se vuelve
# a seleccionar en diferido para que se vea el botón de vender.
func _on_upgrade_requested() -> void:
	if _active and _step == Step.UPGRADE_PRESS:
		var upgraded: Turret = _upgraded_turret()
		if upgraded != null:
			_show_sell_info(upgraded)

func _show_sell_info(turret: Turret) -> void:
	_show_step(Step.SELL_INFO)
	_level.game_state.set_deferred("sellable_turret", turret)

# Lanzar la oleada 1 deja jugar libre hasta que acaba.
func _on_wave_started() -> void:
	if _active and _step < Step.FIRST_WAVE:
		_show_step(Step.FIRST_WAVE)

# Al acabar la oleada 1 se pide mejorar una torreta. Si ya se mejoró alguna jugando, se pasa a
# enseñar el botón de vender; si no llega el dinero, NOVA pone lo que falta.
func _on_wave_cleared(index: int) -> void:
	if not _active or index != 0 or _step != Step.FIRST_WAVE:
		return
	# Con AUTO la oleada 2 llegaría en plena explicación: se apaga.
	_level.spawner.auto_waves = false
	var upgraded: Turret = _upgraded_turret()
	if upgraded != null:
		_show_sell_info(upgraded)
		return
	_show_step(Step.UPGRADE_PICK)
	var missing: int = _upgrade_cost() - _level.game_state.money
	if missing > 0:
		_level.game_state.add_money(missing)
		_type_message(tr(UPGRADE_GIFT_TEXT))

func _on_ok_pressed() -> void:
	if NEXT_AFTER_OK.has(_step):
		_show_step(NEXT_AFTER_OK[_step])
	elif _step == Step.COMPLETE:
		_set_active(false)
		finished.emit()

# Saltar pide confirmar con un segundo clic, como vender.
func _on_skip_pressed() -> void:
	if _confirming_skip:
		skip_requested.emit()
		return
	_confirming_skip = true
	skip_button.text = tr(SKIP_CONFIRM_TEXT)

func _process(delta: float) -> void:
	_blink_time += delta
	# Abrir la pestaña Oleadas no emite nada: se mira aquí.
	if _step == Step.OPEN_WAVES and sidebar.waves_page.visible:
		_show_step(Step.INSPECT_ENEMY)
	queue_redraw()

# Casillas de torreta libres del mapa.
func _free_slots() -> Array[Vector2i]:
	var free: Array[Vector2i] = []
	for cell: Vector2i in _level.grid.slot_cells:
		if _level.grid.can_build(cell):
			free.append(cell)
	return free

# Torretas colocadas en el mapa.
func _placed_turrets() -> Array[Turret]:
	var placed: Array[Turret] = []
	for turret: Turret in _level.grid.turrets.values():
		if is_instance_valid(turret):
			placed.append(turret)
	return placed

# Una torreta ya mejorada (sin mejora siguiente), o null.
func _upgraded_turret() -> Turret:
	for turret: Turret in _placed_turrets():
		if turret.data.fusion == null:
			return turret
	return null

# Lo que cuesta mejorar la torreta del simulacro.
func _upgrade_cost() -> int:
	var data: TurretData = _level.turrets[0]
	return data.fusion.cost if data.fusion != null else 0

# Huecos del paso actual, en coordenadas de este control: lo que el jugador tiene que mirar o tocar.
func _focus_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	match _step:
		Step.STATION:
			rects.append(_world_rect(_level.base.global_position, STATION_SIZE))
			rects.append(_control_rect(sidebar.station_header))
		Step.PLACE_TURRETS:
			rects.append(_control_rect(sidebar.turret_buttons.get_child(0)
					if sidebar.turrets_page.visible else sidebar.turrets_tab))
			for cell: Vector2i in _free_slots():
				rects.append(_world_rect(_level.grid.center(cell), SLOT_SIZE))
		Step.OPEN_WAVES:
			rects.append(_control_rect(sidebar.waves_tab))
		Step.INSPECT_ENEMY:
			rects.append(_control_rect(sidebar.get_viewed_wave_block()))
		Step.ENEMY_INFO:
			rects.append(_control_rect(info_panel))
		Step.START_WAVE:
			rects.append(_control_rect(sidebar.next_wave_button))
		Step.UPGRADE_PICK:
			for turret: Turret in _placed_turrets():
				rects.append(_world_rect(turret.global_position, SLOT_SIZE))
		Step.UPGRADE_PRESS:
			if is_instance_valid(_level.game_state.sellable_turret):
				rects.append(_world_rect(_level.game_state.sellable_turret.global_position, SLOT_SIZE))
			if turret_actions.visible:
				rects.append(_control_rect(turret_actions.upgrade_button))
		Step.SELL_INFO:
			if turret_actions.visible:
				rects.append(_control_rect(turret_actions.sell_button))
	return rects

func _control_rect(target: Control) -> Rect2:
	return Rect2(target.global_position - global_position, target.size).grow(HIGHLIGHT_GROW)

# Rectángulo de `size` centrado en un punto del mapa (coordenadas globales del nivel).
func _world_rect(center: Vector2, size: Vector2) -> Rect2:
	var screen: Vector2 = get_viewport().get_canvas_transform() * center - global_position
	return Rect2(screen - size / 2.0, size).grow(HIGHLIGHT_GROW)

func _draw() -> void:
	if not _active or not box.visible or _dim_alpha <= 0.0:
		return
	# Al salir de un paso con foco el oscurecido se desvanece entero, ya sin huecos.
	var holes: Array[Rect2] = []
	if _step in FOCUS_STEPS:
		holes = _focus_rects()
	_draw_dim(holes)
	if fmod(_blink_time, HIGHLIGHT_BLINK_TIME * 2.0) >= HIGHLIGHT_BLINK_TIME:
		return
	for hole: Rect2 in holes:
		draw_rect(hole, HIGHLIGHT_COLOR, false, 1.0)

# Oscurece todo el control menos los huecos: se parte en franjas horizontales por los bordes de los
# huecos y en cada franja se pintan los tramos que no tapa ninguno. El recuadro de NOVA es hijo, así
# que se pinta encima sin oscurecer.
func _draw_dim(holes: Array[Rect2]) -> void:
	var color: Color = Color(0.0, 0.0, 0.0, _dim_alpha)
	var bounds: Rect2 = Rect2(Vector2.ZERO, size)
	var edges: Array[float] = [0.0, size.y]
	for hole: Rect2 in holes:
		edges.append(clampf(hole.position.y, 0.0, size.y))
		edges.append(clampf(hole.end.y, 0.0, size.y))
	edges.sort()
	for i: int in edges.size() - 1:
		var top: float = edges[i]
		var bottom: float = edges[i + 1]
		if bottom <= top:
			continue
		var spans: Array[Vector2] = []
		for hole: Rect2 in holes:
			if hole.position.y <= top and hole.end.y >= bottom:
				spans.append(Vector2(hole.position.x, hole.end.x))
		spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var x: float = bounds.position.x
		for span: Vector2 in spans:
			if span.x > x:
				draw_rect(Rect2(x, top, span.x - x, bottom - top), color)
			x = maxf(x, span.y)
		if x < bounds.end.x:
			draw_rect(Rect2(x, top, bounds.end.x - x, bottom - top), color)
