extends Node
class_name Grid

var logic_map: TileMapLayer
var slot_cells: Dictionary = {}
var turrets: Dictionary = {}
# Celdas de TurretSlots quitadas en tiempo de juego: casilla -> [source_id, atlas_coords, alternativa].
var _hidden_art: Dictionary = {}
# Casilla bajo la vista previa de construcción (sin torreta aún).
var _preview_cell: Vector2i = Vector2i(-9999, -9999)
# Ya hay un recálculo de auras pedido para el final del frame.
var _amp_pending: bool = false

func setup(lm: TileMapLayer) -> void:
	logic_map = lm
	slot_cells.clear()
	_hidden_art.clear()
	_preview_cell = Vector2i(-9999, -9999)
	for c: Vector2i in logic_map.get_used_cells():
		var data: TileData = logic_map.get_cell_tile_data(c)
		match data.get_custom_data("kind"):
			"slot":
				slot_cells[c] = true

func can_build(c: Vector2i) -> bool:
	return slot_cells.has(c) and not turrets.has(c)

func register_turret(c: Vector2i, t: Turret) -> void:
	turrets[c] = t
	_refresh_slot_art(c)
	t.tree_exiting.connect(func() -> void:
		turrets.erase(c)
		_refresh_slot_art(c)
		_queue_amplification())
	if t.data.is_amplifier():
		t.power_changed.connect(_queue_amplification)
	_queue_amplification()

## Marca la casilla bajo la vista previa (o Vector2i(-9999, -9999) si no hay): su asteroide se oculta.
func set_preview_cell(c: Vector2i) -> void:
	if c == _preview_cell:
		return
	var old: Vector2i = _preview_cell
	_preview_cell = c
	_refresh_slot_art(old)
	_refresh_slot_art(c)

# El asteroide de la casilla se ve solo si no hay torreta ni vista previa encima. Se quita y repone
# la celda de TurretSlots desde código, sin tocar el mapa guardado.
func _refresh_slot_art(c: Vector2i) -> void:
	if logic_map == null or not is_instance_valid(logic_map):
		return
	var layer: TileMapLayer = logic_map.get_parent().get_node_or_null(^"TurretSlots") as TileMapLayer
	if layer == null:
		return
	var covered: bool = turrets.has(c) or c == _preview_cell
	if covered and not _hidden_art.has(c) and layer.get_cell_source_id(c) >= 0:
		_hidden_art[c] = [layer.get_cell_source_id(c), layer.get_cell_atlas_coords(c),
				layer.get_cell_alternative_tile(c)]
		layer.erase_cell(c)
	elif not covered and _hidden_art.has(c):
		var art: Array = _hidden_art[c]
		layer.set_cell(c, art[0], art[1], art[2])
		_hidden_art.erase(c)

func cell(p: Vector2) -> Vector2i:
	return logic_map.local_to_map(logic_map.to_local(p))

## Radio de clic del asteroide de un hueco: el dibujo (32x32, centrado en la casilla) mide ~15 px de radio.
const SLOT_CLICK_RADIUS: float = 15.0

## Hueco cuyo asteroide está bajo el punto global p; si dos se tocan, el de centro más cercano.
## Si no hay ninguno devuelve la casilla de p (que no será un hueco).
func slot_at(p: Vector2) -> Vector2i:
	var origin: Vector2i = cell(p)
	var best: Vector2i = origin
	var best_dist: float = SLOT_CLICK_RADIUS
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			var c: Vector2i = origin + Vector2i(dx, dy)
			if not slot_cells.has(c):
				continue
			var dist: float = center(c).distance_to(p)
			if dist <= best_dist:
				best = c
				best_dist = dist
	return best

func center(c: Vector2i) -> Vector2:
	return logic_map.to_global(logic_map.map_to_local(c))

# Colocar, vender, mejorar o apagar varias torretas en el mismo frame recalcula una sola vez.
func _queue_amplification() -> void:
	if _amp_pending or not is_inside_tree():
		return
	_amp_pending = true
	_update_amplification.call_deferred()

## Cada torreta queda amplificada por el mejor Amplificador encendido cuya aura (su attack_range)
## llegue al centro de su casilla; varios no se suman.
func _update_amplification() -> void:
	_amp_pending = false
	var amplifiers: Array[Turret] = []
	for c: Vector2i in turrets:
		var turret: Turret = turrets[c]
		if turret.data.is_amplifier() and not turret.disabled and not turret.is_queued_for_deletion():
			amplifiers.append(turret)
	for c: Vector2i in turrets:
		var turret: Turret = turrets[c]
		var best: int = 0
		for amplifier: Turret in amplifiers:
			var aura: CircleShape2D = amplifier.data.attack_range as CircleShape2D
			if amplifier != turret and aura != null \
					and amplifier.global_position.distance_to(turret.global_position) <= aura.radius:
				best = maxi(best, amplifier.data.amplifier_level)
		turret.set_amplification(best)
