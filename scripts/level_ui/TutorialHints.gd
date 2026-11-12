extends Control
class_name TutorialHints
## Tutorial del simulacro (el nivel de prueba): NOVA, el astronauta guía, da un mensaje cada vez en un
## recuadro abajo del área de juego. Cuando pide algo, oscurece la pantalla menos lo que hay que tocar
## (y su recuadro), solo deja hacer eso y no se va hasta que se hace. Entre peticiones se juega libre.
## Va en tiempo real: la velocidad ×2 del juego no lo acelera.

## "Saltar simulacro" pulsado dos veces (la segunda confirma): Game sale del simulacro.
signal skip_requested

enum Step { STATION, PLACE_TURRETS, OPEN_WAVES, INSPECT_ENEMY, ENEMY_INFO, START_WAVE, FIRST_WAVE,
		UPGRADE_PICK, UPGRADE_PRESS, DONE, FREE }
# Acciones del jugador que el tutorial puede bloquear; cada sitio donde entran pregunta con allows().
enum Action { SELECT_TURRET, BUILD, RELEASE_TURRET, SELECT_PLACED, TAB_TURRETS, TAB_WAVES, NEXT_WAVE, WAVE_ARROWS,
		TOGGLE_AUTO, TOGGLE_SPEED, UPGRADE, SELL, POWER_METEOR, POWER_FREEZE, POWER_ORBITAL }

# Pasos en los que NOVA pide algo o enseña algo: se oscurece todo menos lo señalado y solo valen las
# acciones de ALLOWED_ACTIONS (un paso sin entrada no deja ninguna). En los demás todo es libre.
const FOCUS_STEPS: Array[Step] = [Step.STATION, Step.PLACE_TURRETS, Step.OPEN_WAVES, Step.INSPECT_ENEMY,
		Step.ENEMY_INFO, Step.START_WAVE, Step.UPGRADE_PICK, Step.UPGRADE_PRESS]
const ALLOWED_ACTIONS: Dictionary[Step, Array] = {
	Step.PLACE_TURRETS: [Action.SELECT_TURRET, Action.BUILD, Action.RELEASE_TURRET, Action.TAB_TURRETS],
	Step.OPEN_WAVES: [Action.TAB_WAVES],
	Step.START_WAVE: [Action.NEXT_WAVE],
	Step.UPGRADE_PICK: [Action.SELECT_PLACED, Action.RELEASE_TURRET],
	Step.UPGRADE_PRESS: [Action.SELECT_PLACED, Action.RELEASE_TURRET, Action.UPGRADE],
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
	Step.DONE: "TUTORIAL_DONE",
}
# Texto de UPGRADE_PICK cuando NOVA tiene que poner el dinero que falta para la mejora.
const UPGRADE_GIFT_TEXT: String = "TUTORIAL_UPGRADE_GIFT"
const SKIP_CONFIRM_TEXT: String = "TUTORIAL_SKIP_CONFIRM"
const SKIP_TEXT: String = "TUTORIAL_SKIP"
# Pasos que no esperan una acción del juego: se pasan con un clic en cualquier sitio (o Intro/Espacio).
const INFO_STEPS: Array[Step] = [Step.STATION, Step.ENEMY_INFO, Step.DONE]
# Paso al que lleva pasar cada mensaje informativo.
const NEXT_AFTER_OK: Dictionary[Step, Step] = {
	Step.STATION: Step.PLACE_TURRETS,
	Step.ENEMY_INFO: Step.START_WAVE,
	Step.DONE: Step.FREE,
}
# Mensajes que se cierran solos tras AUTO_CLOSE_TIME si no se pasan antes.
const AUTO_CLOSE_STEPS: Array[Step] = [Step.DONE]
const AUTO_CLOSE_TIME: float = 5.0
# Segundos por carácter del texto que va apareciendo, como si hablara.
const TYPE_TIME_PER_CHAR: float = 0.02

# Oscurecido de los pasos con foco: negro a esta opacidad, que entra y sale en DIM_FADE_TIME.
const DIM_ALPHA: float = 0.6
const DIM_FADE_TIME: float = 0.2
const HIGHLIGHT_COLOR: Color = Color("#ecb23c")
# Medio ciclo del parpadeo del borde, en segundos.
const HIGHLIGHT_BLINK_TIME: float = 0.4
# Margen del hueco y de su borde respecto a lo señalado de la interfaz.
const HIGHLIGHT_GROW: int = 2
# Flecha de "sigue" de los mensajes informativos: triángulo de 7 px de ancho que sube y baja.
const ARROW_COLOR: Color = Color("#ecb23c")
const ARROW_WIDTH: int = 7
const ARROW_ROWS: int = 4
const ARROW_BOB_PX: float = 2.0
const ARROW_BOB_TIME: float = 0.8

@onready var box: Control = %Box
@onready var message_label: Label = %MessageLabel
@onready var continue_arrow: Control = %ContinueArrow
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
# Segundos reales desde que empezó el tutorial: mueven el parpadeo y la flecha.
var _time: float = 0.0
var _confirming_skip: bool = false
# Contornos ámbar de los sprites del mapa, por textura y región (se calculan una vez).
var _outlines: Dictionary[String, ImageTexture] = {}

# Lo que se señala del mapa: un trozo de textura dibujado encima del oscurecido, con su contorno.
class Spotlight:
	var texture: Texture2D
	var region: Rect2
	# Dónde se dibuja, en el espacio de `transform`.
	var rect: Rect2
	# De ese espacio a las coordenadas de TutorialHints.
	var transform: Transform2D

# Hueco de la interfaz: lo que hay debajo se ve sin oscurecer; con borde, parpadea alrededor.
class Hole:
	var rect: Rect2
	var border: bool

	func _init(hole_rect: Rect2, has_border: bool) -> void:
		rect = hole_rect
		border = has_border

func _ready() -> void:
	skip_button.pressed.connect(_on_skip_pressed)
	continue_arrow.draw.connect(_draw_continue_arrow)
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

## Si el paso actual deja hacer `action`. Sin tutorial en marcha o fuera de los pasos con foco todo vale.
func allows(action: Action) -> bool:
	return not _active or _step not in FOCUS_STEPS or action in ALLOWED_ACTIONS.get(_step, [])

func _set_active(active: bool) -> void:
	_active = active
	box.visible = false
	continue_arrow.visible = false
	skip_button.visible = active
	_confirming_skip = false
	skip_button.text = tr(SKIP_TEXT)
	_dim_alpha = 0.0
	set_process(active)
	set_process_input(active)
	queue_redraw()

func _show_step(step: Step) -> void:
	var was_focus: bool = _step in FOCUS_STEPS and box.visible
	_step = step
	box.visible = step not in HIDDEN_STEPS
	continue_arrow.visible = false
	if TEXTS.has(step):
		_type_message(tr(TEXTS[step]))
	if step in AUTO_CLOSE_STEPS:
		_typing.tween_interval(AUTO_CLOSE_TIME)
		_typing.tween_callback(_advance_info)
	var is_focus: bool = step in FOCUS_STEPS
	if is_focus != was_focus:
		_fade_dim(DIM_ALPHA if is_focus else 0.0)
	queue_redraw()

# El texto aparece letra a letra, como si NOVA hablara; en los informativos sale después la flecha.
func _type_message(message: String) -> void:
	message_label.text = message
	message_label.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween().set_ignore_time_scale()
	_typing.tween_property(message_label, "visible_ratio", 1.0, message.length() * TYPE_TIME_PER_CHAR)
	_typing.tween_callback(func() -> void: continue_arrow.visible = _step in INFO_STEPS)

func _fade_dim(to_alpha: float) -> void:
	if _dim_tween:
		_dim_tween.kill()
	_dim_tween = create_tween().set_ignore_time_scale()
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

# BuildManager mejora antes (se conectó antes a la señal), así que la torreta ya está mejorada.
func _on_upgrade_requested() -> void:
	if _active and _step == Step.UPGRADE_PRESS and _upgraded_turret() != null:
		_show_step(Step.DONE)

# Lanzar la oleada 1 deja jugar libre hasta que acaba.
func _on_wave_started() -> void:
	if _active and _step < Step.FIRST_WAVE:
		_show_step(Step.FIRST_WAVE)

# Al acabar la oleada 1 se pide mejorar una torreta (si ya se mejoró alguna jugando, solo queda la
# despedida). Si no llega el dinero, NOVA pone lo que falta.
func _on_wave_cleared(index: int) -> void:
	if not _active or index != 0 or _step != Step.FIRST_WAVE:
		return
	# Con AUTO la oleada 2 llegaría en plena explicación: se apaga.
	_level.spawner.auto_waves = false
	if _upgraded_turret() != null:
		_show_step(Step.DONE)
		return
	_show_step(Step.UPGRADE_PICK)
	var missing: int = _upgrade_cost() - _level.game_state.money
	if missing > 0:
		_level.game_state.add_money(missing)
		_type_message(tr(UPGRADE_GIFT_TEXT))

# Un clic en cualquier sitio (o Intro/Espacio) pasa los mensajes informativos: el primero acaba de
# escribir el texto y el siguiente pasa de paso. Se lo come, para que no construya ni pulse nada.
# El botón de saltar sigue respondiendo.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not box.visible or _step not in INFO_STEPS:
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	var is_click: bool = click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT
	if is_click and skip_button.get_global_rect().has_point(click.global_position):
		return
	if not is_click and not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	if message_label.visible_ratio < 1.0:
		_typing.kill()
		message_label.visible_ratio = 1.0
		continue_arrow.visible = true
		if _step in AUTO_CLOSE_STEPS:
			_typing = create_tween().set_ignore_time_scale()
			_typing.tween_interval(AUTO_CLOSE_TIME)
			_typing.tween_callback(_advance_info)
		return
	_advance_info()

func _advance_info() -> void:
	if NEXT_AFTER_OK.has(_step):
		_show_step(NEXT_AFTER_OK[_step])

# Saltar pide confirmar con un segundo clic, como vender.
func _on_skip_pressed() -> void:
	if _confirming_skip:
		skip_requested.emit()
		return
	_confirming_skip = true
	skip_button.text = tr(SKIP_CONFIRM_TEXT)

func _process(delta: float) -> void:
	# delta sigue Engine.time_scale: se deshace para que el ×2 no acelere el parpadeo ni la flecha.
	_time += delta / maxf(Engine.time_scale, 0.01)
	# Abrir la pestaña Oleadas no emite nada: se mira aquí.
	if _step == Step.OPEN_WAVES and sidebar.waves_page.visible:
		_show_step(Step.INSPECT_ENEMY)
	queue_redraw()
	if continue_arrow.visible:
		continue_arrow.queue_redraw()

func _blink_on() -> bool:
	return fmod(_time, HIGHLIGHT_BLINK_TIME * 2.0) < HIGHLIGHT_BLINK_TIME

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

# Huecos de la interfaz del paso actual, en coordenadas de este control.
func _focus_holes() -> Array[Hole]:
	var holes: Array[Hole] = []
	match _step:
		Step.STATION:
			holes.append(_control_hole(sidebar.station_header, true))
		Step.PLACE_TURRETS:
			holes.append(_control_hole(sidebar.turret_buttons.get_child(0)
					if sidebar.turrets_page.visible else sidebar.turrets_tab, true))
		Step.OPEN_WAVES:
			holes.append(_control_hole(sidebar.waves_tab, true))
		Step.INSPECT_ENEMY:
			holes.append(_control_hole(sidebar.get_viewed_wave_block(), true))
		Step.ENEMY_INFO:
			# Un panel entero no se enmarca: basta con que no se oscurezca.
			holes.append(_control_hole(info_panel, false))
		Step.START_WAVE:
			holes.append(_control_hole(sidebar.next_wave_button, true))
		Step.UPGRADE_PRESS:
			if turret_actions.visible:
				holes.append(_control_hole(turret_actions.upgrade_button, true))
	return holes

# Lo que se señala del mapa en el paso actual: se dibuja encima del oscurecido con su contorno.
func _focus_spotlights() -> Array[Spotlight]:
	var spots: Array[Spotlight] = []
	match _step:
		Step.STATION:
			_add_sprite_spotlight(spots, _level.base)
		Step.PLACE_TURRETS:
			for cell: Vector2i in _free_slots():
				_add_slot_spotlight(spots, cell)
		Step.UPGRADE_PICK:
			for turret: Turret in _placed_turrets():
				_add_turret_spotlight(spots, turret)
		Step.UPGRADE_PRESS:
			if is_instance_valid(_level.game_state.sellable_turret):
				_add_turret_spotlight(spots, _level.game_state.sellable_turret)
	return spots

func _control_hole(target: Control, border: bool) -> Hole:
	var rect: Rect2 = Rect2(target.global_position - global_position, target.size)
	return Hole.new(rect.grow(HIGHLIGHT_GROW) if border else rect, border)

# La torreta con su asteroide de debajo.
func _add_turret_spotlight(spots: Array[Spotlight], turret: Turret) -> void:
	_add_slot_spotlight(spots, _level.grid.cell(turret.global_position))
	_add_sprite_spotlight(spots, turret.sprite)
	_add_sprite_spotlight(spots, turret.cannon)

# El frame actual de un AnimatedSprite2D, tal como está en el mapa.
func _add_sprite_spotlight(spots: Array[Spotlight], sprite: AnimatedSprite2D) -> void:
	if not sprite.visible or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(sprite.animation):
		return
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return
	var spot: Spotlight = Spotlight.new()
	spot.texture = texture
	spot.region = Rect2(Vector2.ZERO, texture.get_size())
	var top_left: Vector2 = sprite.offset - (texture.get_size() / 2.0 if sprite.centered else Vector2.ZERO)
	spot.rect = Rect2(top_left, texture.get_size())
	spot.transform = get_global_transform_with_canvas().affine_inverse() * sprite.get_global_transform_with_canvas()
	spots.append(spot)

# El asteroide con plataforma de una casilla de torreta, de la capa TurretSlots del mapa.
func _add_slot_spotlight(spots: Array[Spotlight], cell: Vector2i) -> void:
	var layer: TileMapLayer = _level.map.get_node_or_null(^"TurretSlots") as TileMapLayer
	if layer == null or layer.get_cell_source_id(cell) < 0:
		return
	var source: TileSetAtlasSource = layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
	if source == null:
		return
	var coords: Vector2i = layer.get_cell_atlas_coords(cell)
	var spot: Spotlight = Spotlight.new()
	spot.texture = source.texture
	spot.region = source.get_tile_texture_region(coords)
	var origin: Vector2 = Vector2(source.get_tile_data(coords, layer.get_cell_alternative_tile(cell)).texture_origin)
	spot.rect = Rect2(-spot.region.size / 2.0 - origin, spot.region.size)
	spot.transform = (get_global_transform_with_canvas().affine_inverse() * layer.get_global_transform_with_canvas()
			* Transform2D(0.0, layer.map_to_local(cell)))
	spots.append(spot)

func _draw() -> void:
	if not _active or not box.visible or _dim_alpha <= 0.0:
		return
	# Al salir de un paso con foco el oscurecido se desvanece entero, ya sin huecos.
	var holes: Array[Hole] = []
	var spots: Array[Spotlight] = []
	if _step in FOCUS_STEPS:
		holes = _focus_holes()
		spots = _focus_spotlights()
	var rects: Array[Rect2] = []
	for hole: Hole in holes:
		rects.append(hole.rect)
	_draw_dim(rects)
	var blink: bool = _blink_on()
	# Primero todos los contornos y después los sprites, para que el contorno quede solo por fuera.
	if blink:
		for spot: Spotlight in spots:
			draw_set_transform_matrix(spot.transform)
			draw_texture(_outline_texture(spot.texture, spot.region), spot.rect.position - Vector2.ONE)
	for spot: Spotlight in spots:
		draw_set_transform_matrix(spot.transform)
		draw_texture_rect_region(spot.texture, spot.rect, spot.region)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if blink:
		for hole: Hole in holes:
			if hole.border:
				draw_rect(hole.rect, HIGHLIGHT_COLOR, false, 1.0)

# Contorno ámbar de 1 px alrededor de los píxeles opacos de una región de textura: una imagen 2 px
# más grande con ámbar en cada píxel transparente que toca uno opaco. Se guarda para no repetirlo.
func _outline_texture(texture: Texture2D, region: Rect2) -> ImageTexture:
	var key: String = "%d|%s" % [texture.get_rid().get_id(), region]
	if _outlines.has(key):
		return _outlines[key]
	var image: Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var area: Rect2i = Rect2i(region)
	if area.size != image.get_size():
		image = image.get_region(area)
	var width: int = image.get_width()
	var height: int = image.get_height()
	var outline: Image = Image.create_empty(width + 2, height + 2, false, Image.FORMAT_RGBA8)
	for y: int in height + 2:
		for x: int in width + 2:
			if _is_opaque(image, x - 1, y - 1):
				continue
			if (_is_opaque(image, x - 2, y - 1) or _is_opaque(image, x, y - 1)
					or _is_opaque(image, x - 1, y - 2) or _is_opaque(image, x - 1, y)):
				outline.set_pixel(x, y, HIGHLIGHT_COLOR)
	var result: ImageTexture = ImageTexture.create_from_image(outline)
	_outlines[key] = result
	return result

func _is_opaque(image: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height() and image.get_pixel(x, y).a > 0.5

# Oscurece todo el control menos los huecos: se parte en franjas horizontales por los bordes de los
# huecos y en cada franja se pintan los tramos que no tapa ninguno. El recuadro de NOVA es hijo, así
# que se pinta encima sin oscurecer.
func _draw_dim(holes: Array[Rect2]) -> void:
	var color: Color = Color(0.0, 0.0, 0.0, _dim_alpha)
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
		var x: float = 0.0
		for span: Vector2 in spans:
			if span.x > x:
				draw_rect(Rect2(x, top, span.x - x, bottom - top), color)
			x = maxf(x, span.y)
		if x < size.x:
			draw_rect(Rect2(x, top, size.x - x, bottom - top), color)

# Flecha de "sigue" abajo a la derecha del recuadro: un triángulo que apunta abajo y sube y baja.
func _draw_continue_arrow() -> void:
	var bob: float = roundf((sin(_time * TAU / ARROW_BOB_TIME) + 1.0) / 2.0 * ARROW_BOB_PX)
	for row: int in ARROW_ROWS:
		continue_arrow.draw_rect(Rect2(row, row + bob, ARROW_WIDTH - row * 2, 1), ARROW_COLOR)
