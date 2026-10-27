extends Node
class_name Grid

var logic_map: TileMapLayer
var slot_cells: Dictionary = {}
var turrets: Dictionary = {}
# Ya hay un recálculo de auras pedido para el final del frame.
var _amp_pending := false

func setup(lm: TileMapLayer) -> void:
	logic_map = lm
	slot_cells.clear()
	for c in logic_map.get_used_cells():
		var data = logic_map.get_cell_tile_data(c)
		match data.get_custom_data("kind"):
			"slot":
				slot_cells[c] = true

func can_build(c: Vector2i) -> bool:
	return slot_cells.has(c) and not turrets.has(c)

func register_turret(c: Vector2i, t: Turret) -> void:
	turrets[c] = t
	t.tree_exiting.connect(func():
		turrets.erase(c)
		_queue_amplification())
	if t.data.is_amplifier():
		t.power_changed.connect(_queue_amplification)
	_queue_amplification()

func cell(p: Vector2) -> Vector2i:
	return logic_map.local_to_map(logic_map.to_local(p))

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
		var best := 0
		for amplifier in amplifiers:
			var aura := amplifier.data.attack_range as CircleShape2D
			if amplifier != turret and aura != null \
					and amplifier.global_position.distance_to(turret.global_position) <= aura.radius:
				best = maxi(best, amplifier.data.amplifier_level)
		turret.set_amplification(best)
