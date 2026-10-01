extends Node2D
class_name Grid

var logic: TileMapLayer
var slot_cells = {}
var towers = {}

func _ready():
	logic = get_node("../Map/LogicMap")
	for c in logic.get_used_cells():
		if logic.get_cell_tile_data(c).get_custom_data("kind") == "slot":
			slot_cells[c] = true

func can_build(c: Vector2i) -> bool:
	return slot_cells.has(c) and not towers.has(c)

func register_tower(c: Vector2i, t: Node) -> void:
	towers[c] = t
	t.tree_exiting.connect(func(): towers.erase(c))

func cell(p: Vector2) -> Vector2i:
	return logic.local_to_map(logic.to_local(p))

func center(c: Vector2i) -> Vector2:
	return logic.to_global(logic.map_to_local(c))
