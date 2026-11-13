class_name NavedexShowcase
extends Control
## Vitrina de la Navedex: un mini nivel en vivo (SubViewport) con las piezas reales del juego, para que
## se vea igual que en partida.
## - Torreta: un trozo del mapa del juego (NavedexMap, generado de resources/map_data/navedex.txt) con la
##   Turret de verdad sobre su asteroide con plataforma a la izquierda (con su BuildManager y LevelState,
##   como en partida), y por el pasillo libre de la derecha, a 48 px de ella, bajan las naves de su escena
##   (SCENES), elegidas para que se vea su mecánica; la torreta les dispara con sus propias balas, ondas,
##   rayos, haces, orbes y escarcha.
## - Nave: el Enemy de verdad da vueltas al camino con su animación, su giro y su habilidad (camuflaje,
##   pulso EMP...). La Reparadora cura a una nave secundaria, tenue y dañada; la Divisora se parte cada
##   pocos segundos como en Spawner. Las no vistas van en silueta negra y sin habilidad. Dan vueltas a un
##   camino cerrado (rectángulo) sobre un fondo de pantalla oscura con cuadrícula.

# Aumento del mini nivel: las naves de cerca; las torretas a ×1, con la cámara lejos para ver más mapa.
const SHIP_ZOOM: int = 2
const TURRET_ZOOM: int = 1
const TURRET_SCENE: PackedScene = preload("res://scenes/entities/Turret.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/entities/Enemy.tscn")
# Escena de cada torreta base; las mejoras usan la de su base (ver _turret_base). Claves:
# - "map": trozo de mapa (scenes/maps/<Nombre>Map.tscn, generado de resources/map_data/<nombre>.txt con
#   map_generator.gd; "navedex_<torreta>" si falta), "slot": su casilla de torreta (MAP_SLOT si falta) y
#   "view": dónde queda esa casilla en la vitrina, en fracción del ancho y del alto (centrada si falta).
# - Las naves van por los caminos del mapa como en una oleada: entran donde cada camino entra en la
#   vitrina y salen por otro borde o mueren. "enemy" (archivo de resources/enemy_data/; sin él no sale
#   ninguna), "speed" (px/s; despacio para que el Rail, que gira a 45°/s, llegue a apuntar), "health"
#   (multiplicador de vida), "interval" (segundos entre salidas; sale una por camino), "group" (naves por
#   salida, en fila a SHIP_GAP px) y "max" (naves en la vitrina como mucho).
# - "helpers": torretas de alrededor (archivo de resources/turret_data/ y su casilla del mapa).
# Solo para la vitrina: no cambia el balance.
const SCENES: Dictionary[String, Dictionary] = {
	# Un camino recto por debajo: lo básico, un disparo tras otro a una nave.
	"turret": {"enemy": "dart_verde", "speed": 25.0, "health": 4.0, "interval": 3.0},
	# El camino sube por su izquierda y baja por su derecha (la vuelta queda fuera de la vitrina):
	# Acorazados lentos y duros que no salen de su alcance, así que acelera hasta el tope, se calienta y para.
	"minigun": {"enemy": "acorazado", "speed": 20.0, "health": 3.0, "interval": 2.5},
	# Entre dos caminos, uno a cada lado a 3 casillas, dentro de su onda: Darts rápidos que no mueren
	# entran corriendo por arriba y por abajo y frenan al pasar junto a ella.
	"cryo": {"enemy": "dart_rojo", "speed": 60.0, "health": 100.0, "interval": 1.6},
	# El camino baja por su derecha y sube por su izquierda (la vuelta queda fuera de la vitrina): grupos
	# de tres, y la explosión alcanza a las de al lado.
	"rocket_launcher": {"enemy": "nave_normal", "speed": 20.0, "health": 1.0, "interval": 4.0, "group": 3},
	# Un camino en zigzag a su alrededor: naves seguidas y cerca entre tramos, y la cadena salta de una a otra.
	"tesla": {"enemy": "nave_normal", "speed": 25.0, "health": 1.0, "interval": 1.2},
	# Un camino recto que le pasa por delante, 2 casillas por encima, y entra en la vitrina ya a su alcance:
	# apunta y carga desde lejos y el haz atraviesa la fila entera, que viene casi en su línea.
	"rail": {"enemy": "nave_normal", "speed": 25.0, "health": 1.0, "interval": 6.0, "group": 4},
	# El camino le pasa por encima en arco, siempre a su alcance: un Acorazado lento cada vez, al que el haz
	# no suelta y sube de nivel hasta romperlo.
	"disintegrator": {"enemy": "acorazado", "speed": 15.0, "health": 1.0, "interval": 1.5, "max": 1},
	# Un camino recto por debajo que cruza su anillo dos veces (y pasa por el hueco de dentro, donde no
	# llega): las naves chocan con las cargas.
	"orbiter": {"enemy": "dart_verde", "speed": 30.0, "health": 1.0, "interval": 1.5},
	# Un Cañón pesado a un lado y una Tesla al otro, separados, dentro de su aura, y un camino por debajo:
	# la onda los hace brillar, la explosión del cañón es más grande y la cadena salta a más naves.
	"amplifier": {"enemy": "nave_normal", "speed": 25.0, "health": 2.0, "interval": 3.0,
		"helpers": {"rocket_launcher": Vector2i(8, 8), "tesla": Vector2i(20, 8)}},
	# Sin naves: con la oleada en curso, genera dinero.
	"miner": {"map": "navedex", "slot": Vector2i(6, 8), "view": Vector2(0.3, 0.5)},
}
# Separación de las naves de un grupo, como en una oleada (px).
const SHIP_GAP: float = 26.0
# Nave secundaria de la Reparadora.
const COMPANION_DATA: EnemyData = preload("res://resources/enemy_data/dart_verde.tres")
# Margen del camino al borde de la vitrina (píxeles del juego; deja sitio a la barra de vida).
const PATH_MARGIN: float = 14.0
# Torreta: dónde va en la vitrina (fracción del ancho y del alto) y su casilla en los mapas navedex_*.txt.
const TURRET_VIEW: Vector2 = Vector2(0.5, 0.5)
const MAP_SLOT: Vector2i = Vector2i(14, 8)
const TILE_SIZE: int = 16
# Naves: alto del bucle, en fracción del alto (centrado).
const SHIP_PATH_Y: Vector2 = Vector2(0.3, 0.7)
# Nave secundaria de la Reparadora: distancia por delante en el camino, opacidad y vida que le falta.
const COMPANION_GAP: float = 34.0
const COMPANION_ALPHA: float = 0.45
const COMPANION_DAMAGE: float = 0.6
# Divisora: segundos entera y segundos partida, en bucle.
const SPLIT_WHOLE_TIME: float = 3.0
const SPLIT_PARTS_TIME: float = 3.0
const GRID_STEP: int = 8

var _data: InspectableData
var _known: bool = true
var _viewport: SubViewport
# Aumento del mini nivel en uso (SHIP_ZOOM o TURRET_ZOOM).
var _zoom: int = SHIP_ZOOM
var _border: Control
# Todo lo del mini nivel cuelga de aquí; se rehace al cambiar de dato o de tamaño.
var _level: Node2D
var _path: Path2D
# Torretas: naves en la vitrina, caminos del mapa con el avance donde entran en la vitrina, y rectángulo
# de la vitrina con margen (las que salen de él se quitan).
var _ships: Array = []
var _path_starts: Dictionary[Path2D, float] = {}
var _view: Rect2
var _turret_parent: BuildManager
var _ship: Enemy
var _companion: Enemy
var _parts: Array[Enemy] = []
var _split_timer: float = 0.0

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# El SubViewport dibuja a la resolución final de pantalla (tamaño en pantalla, no en píxeles del juego)
	# y el aumento se hace con la transformación del canvas, no ampliando la imagen: así lo que gira
	# (las torretas) se dibuja nítido, como en partida.
	_viewport = SubViewport.new()
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_viewport)
	var view: TextureRect = TextureRect.new()
	view.texture = _viewport.get_texture()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	resized.connect(_rebuild)
	get_viewport().size_changed.connect(_rebuild)
	_border = Control.new()
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	_border.draw.connect(_draw_border)
	add_child(_border)

# Con la Navedex cerrada el mini nivel se para (y no suena).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _viewport != null:
		_viewport.process_mode = Node.PROCESS_MODE_INHERIT if is_visible_in_tree() else Node.PROCESS_MODE_DISABLED
		if is_visible_in_tree():
			_rebuild()

## Enseña la escena de `data`; `known` en falso la deja en silueta y sin habilidad.
func show_data(data: InspectableData, known: bool) -> void:
	_data = data
	_known = known
	_zoom = TURRET_ZOOM if data is TurretData else SHIP_ZOOM
	_rebuild()

func _rebuild() -> void:
	if _level != null:
		_level.queue_free()
	_level = null
	_ship = null
	_companion = null
	_parts.clear()
	_ships.clear()
	_path_starts.clear()
	# Píxeles de pantalla por píxel de la vitrina: el escalado de la ventana (stretch canvas_items, que
	# get_screen_transform no cuenta) por lo que amplíen los padres.
	var pixel_scale: float = maxf(roundf((get_viewport().get_final_transform() * get_global_transform_with_canvas()).get_scale().x), 1.0)
	_viewport.size = Vector2i((size * pixel_scale).round())
	_viewport.canvas_transform = Transform2D.IDENTITY.scaled(Vector2.ONE * pixel_scale * _zoom)
	var world: Vector2 = (size / float(_zoom)).floor()
	if _data == null or world.x < 2.0 * PATH_MARGIN or world.y < 2.0 * PATH_MARGIN:
		return
	_level = Node2D.new()
	_viewport.add_child(_level)
	var turret: TurretData = _data as TurretData
	if turret != null:
		_build_turret(turret, world)
		return
	_path = Path2D.new()
	_path.curve = Curve2D.new()
	var backdrop: Node2D = Node2D.new()
	backdrop.draw.connect(_draw_backdrop.bind(backdrop, world))
	_level.add_child(backdrop)
	# Bucle centrado para las naves.
	var top: float = minf(world.y * SHIP_PATH_Y.x, world.y / 2.0 - 1.0)
	top = maxf(top, minf(PATH_MARGIN, world.y / 2.0 - 1.0))
	var loop: Rect2 = Rect2(PATH_MARGIN, top, world.x - 2.0 * PATH_MARGIN, maxf(world.y * SHIP_PATH_Y.y - top, 2.0))
	loop = Rect2(loop.position.round(), loop.size.round())
	for corner: Vector2 in [loop.position, Vector2(loop.end.x, loop.position.y), loop.end, Vector2(loop.position.x, loop.end.y), loop.position]:
		_path.curve.add_point(corner)
	_level.add_child(_path)
	_build_ship(_data as EnemyData)

# --- Torreta ------------------------------------------------------------------------------

# El trozo de mapa, colocado para que la casilla de la torreta caiga donde dice la escena (el resto se
# recorta por los bordes). Las naves van por sus caminos (Paths) y entran donde cada camino entra en la
# vitrina, para no esperar a que lleguen desde el borde del mapa.
func _build_map(base: String, scene: Dictionary, world: Vector2) -> Vector2:
	var map_name: String = scene.get("map", "navedex_" + base)
	var map: Node2D = (load("res://scenes/maps/%sMap.tscn" % map_name.to_pascal_case()) as PackedScene).instantiate()
	var turret_position: Vector2 = (world * (scene.get("view", TURRET_VIEW) as Vector2)).round()
	var slot: Vector2i = scene.get("slot", MAP_SLOT)
	map.position = turret_position - (Vector2(slot) + Vector2(0.5, 0.5)) * TILE_SIZE
	_level.add_child(map)
	# El fondo cubre todo el área, así que se coloca en el origen de la vitrina y no del mapa.
	(map.get_node("Background") as Node2D).position = -map.position
	_view = Rect2(Vector2.ZERO, world).grow(PATH_MARGIN)
	for path: Path2D in map.get_node("Paths").get_children():
		_path_starts[path] = 0.0
		for point: Vector2 in path.curve.get_baked_points():
			if _view.has_point(point + map.position):
				_path_starts[path] = path.curve.get_closest_offset(point)
				break
	return turret_position

func _build_turret(data: TurretData, world: Vector2) -> void:
	var base: String = _turret_base(data)
	var scene: Dictionary = SCENES.get(base, {})
	var turret_position: Vector2 = _build_map(base, scene, world)
	# Como en partida, la torreta cuelga del BuildManager (la excavadora lee de él el estado del nivel).
	var state: LevelState = LevelState.new()
	state.wave_in_progress = true
	_level.add_child(state)
	_turret_parent = BuildManager.new()
	_turret_parent.state = state
	_level.add_child(_turret_parent)
	_turret_parent.stop_building()
	var node: Turret = TURRET_SCENE.instantiate()
	node.data = data
	node.position = turret_position
	_turret_parent.add_child(node)
	var helpers: Dictionary = scene.get("helpers", {})
	var slot: Vector2i = scene.get("slot", MAP_SLOT)
	for file: String in helpers:
		var helper: Turret = TURRET_SCENE.instantiate()
		helper.data = load(Navedex.TURRET_DIR + file + ".tres") as TurretData
		helper.position = turret_position + Vector2((helpers[file] as Vector2i) - slot) * TILE_SIZE
		_turret_parent.add_child(helper)
		# Sin Grid que calcule el aura: dentro de la del Amplificador desde el principio.
		if data.is_amplifier():
			helper.set_amplification(data.amplifier_level)
	if scene.has("enemy"):
		var timer: Timer = Timer.new()
		timer.wait_time = scene["interval"]
		timer.autostart = true
		timer.timeout.connect(_spawn_group.bind(scene))
		_level.add_child(timer)
		_spawn_group(scene)

# Archivo de la torreta base (el de una mejora es el de su base + "_fusion").
func _turret_base(data: TurretData) -> String:
	return data.resource_path.get_file().get_basename().trim_suffix("_fusion")

# Saca por cada camino un grupo de naves en fila, por donde entra en la vitrina, si caben.
func _spawn_group(scene: Dictionary) -> void:
	_ships = _ships.filter(func(ship: Variant) -> bool: return is_instance_valid(ship))
	var group: int = scene.get("group", 1)
	var enemy_data: EnemyData = load(Navedex.ENEMY_DIR + scene["enemy"] + ".tres") as EnemyData
	for path: Path2D in _path_starts:
		if _ships.size() + group > scene.get("max", 99):
			return
		for i: int in group:
			var ship: Enemy = _spawn(enemy_data, maxf(_path_starts[path] - i * SHIP_GAP, 0.0), scene["health"], path)
			ship.loop = false
			ship.speed = scene["speed"]
			_ships.append(ship)

# --- Nave ---------------------------------------------------------------------------------

func _build_ship(data: EnemyData) -> void:
	if not _known:
		# Silueta: la misma nave sin habilidades, en negro.
		data = data.duplicate() as EnemyData
		data.heal_aura = false
		data.cloak_interval = 0.0
		data.emp_interval = 0.0
		# El duplicado comparte el array con el original: se cambia por una copia vacía.
		data.split_into = data.split_into.duplicate()
		data.split_into.clear()
	_ship = _spawn(data, 0.0, 1.0)
	if not _known:
		_ship.sprite.modulate = Color.BLACK
		return
	if data.heal_aura:
		_companion = _spawn(COMPANION_DATA, COMPANION_GAP, 1.0)
		_companion.speed = _ship.speed
		_companion.modulate.a = COMPANION_ALPHA
		_hurt_companion()
	_split_timer = SPLIT_WHOLE_TIME

func _process(delta: float) -> void:
	if _level == null or not is_visible_in_tree():
		return
	# Torretas: la nave que sale de la vitrina se quita (el resto del camino no se ve).
	for ship: Variant in _ships:
		if is_instance_valid(ship) and (ship as Enemy).progress > _path_starts.get((ship as Enemy).get_parent(), 0.0) + 2.0 * PATH_MARGIN and not _view.has_point((ship as Enemy).global_position):
			(ship as Enemy).queue_free()
	# La secundaria de la Reparadora vuelve a dañarse cuando la ha curado del todo.
	if is_instance_valid(_companion) and _companion.hp >= _companion.max_hp:
		_hurt_companion()
	if _ship == null or not _known or (_data as EnemyData).split_into.is_empty():
		return
	_split_timer -= delta
	if _split_timer > 0.0:
		return
	if is_instance_valid(_ship) and _parts.is_empty():
		_split(_ship)
		_split_timer = SPLIT_PARTS_TIME
	else:
		for part: Enemy in _parts:
			part.queue_free()
		_parts.clear()
		_ship = _spawn(_data as EnemyData, 0.0, 1.0)
		_ship.spawn_in()
		_split_timer = SPLIT_WHOLE_TIME

# Le quita vida sin golpe (sin destello ni número de daño), para que la Reparadora tenga a quién curar.
func _hurt_companion() -> void:
	_companion.hp = _companion.max_hp * (1.0 - COMPANION_DAMAGE)

# Se parte como en Spawner._crack y Spawner._split: frame agrietado con destello y los trozos
# despedidos de lado que vuelven al camino.
func _split(whole: Enemy) -> void:
	var data: EnemyData = whole.data
	var progress: float = whole.progress
	var crack: AnimatedSprite2D = AnimatedSprite2D.new()
	crack.sprite_frames = whole.sprite.sprite_frames
	crack.animation = &"crack" if crack.sprite_frames.has_animation(&"crack") else whole.sprite.animation
	crack.position = whole.position
	crack.rotation = whole.sprite.rotation
	_path.add_child(crack)
	var sprite_rotation: float = whole.sprite.rotation
	whole.queue_free()
	var tween: Tween = crack.create_tween()
	tween.tween_property(crack, "modulate", Color.WHITE, Spawner.CRACK_TIME).from(Enemy.SLOW_FLASH)
	tween.tween_callback(func() -> void:
		var side: Vector2 = Vector2.RIGHT.rotated(sprite_rotation)
		var count: int = data.split_into.size()
		for i: int in count:
			var piece: Enemy = _spawn(data.split_into[i], progress, 1.0)
			var offset: Vector2 = side * (i - (count - 1) / 2.0)
			piece.sprite.rotation = sprite_rotation
			piece.flash()
			var push: Tween = piece.create_tween()
			push.tween_property(piece.sprite, "position", offset * (Spawner.SPLIT_GAP + Spawner.SPLIT_PUSH), Spawner.SPLIT_PUSH_TIME).from(offset * Spawner.SPLIT_GAP)
			push.tween_property(piece.sprite, "position", Vector2.ZERO, Spawner.SPLIT_RETURN_TIME).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			_parts.append(piece))
	tween.tween_callback(crack.queue_free)

# Un Enemy en `path` (por defecto el camino cerrado de las naves), que da vueltas sin llegar nunca al final.
func _spawn(data: EnemyData, progress: float, health: float, path: Path2D = null) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	(path if path != null else _path).add_child(enemy)
	enemy.loop = true
	# El avance antes de setup(), para que su primer giro salga del camino y no de un salto (como en Spawner).
	enemy.progress = progress
	enemy.setup(data, health)
	return enemy

# --- Dibujo -------------------------------------------------------------------------------

# Fondo del mini nivel: pantalla oscura con cuadrícula tenue.
func _draw_backdrop(canvas: Node2D, world: Vector2) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, world), OfficePaint.SCREEN_DARK)
	for x: int in range(GRID_STEP, int(world.x), GRID_STEP):
		canvas.draw_rect(Rect2(x, 0, 1, world.y), OfficePaint.SCREEN)
	for y: int in range(GRID_STEP, int(world.y), GRID_STEP):
		canvas.draw_rect(Rect2(0, y, world.x, 1), OfficePaint.SCREEN)

# Borde cian y escuadras por encima del mini nivel.
func _draw_border() -> void:
	OfficePaint.brackets(_border, Rect2i(Vector2i(4, 4), Vector2i(size) - Vector2i(8, 8)), OfficePaint.CYAN_DARK)
	_border.draw_rect(Rect2(Vector2.ZERO, size), OfficePaint.CYAN_DARK, false, 1.0)
