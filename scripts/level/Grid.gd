extends Node
class_name Grid

var logic_map: TileMapLayer
var slot_cells: Dictionary = {}
var turrets: Dictionary = {}

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

func register_turret(c: Vector2i, t: Node) -> void:
	turrets[c] = t
	t.tree_exiting.connect(func(): turrets.erase(c))

func cell(p: Vector2) -> Vector2i:
	return logic_map.local_to_map(logic_map.to_local(p))

func center(c: Vector2i) -> Vector2:
	return logic_map.to_global(logic_map.map_to_local(c))
