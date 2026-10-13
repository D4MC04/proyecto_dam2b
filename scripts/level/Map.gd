extends Node2D
class_name Map

@onready var visual_map: TileMapLayer = $VisualMap
@onready var logic_map: TileMapLayer = $LogicMap
@onready var space_station: Sprite2D = $SpaceStation

func get_paths() -> Array[Path2D]:
	var result: Array[Path2D] = []
	result.assign($Paths.get_children())
	return result

## Rectángulo útil en coordenadas locales de Map: casillas usadas de LogicMap más el sprite de la estación.
func get_used_rect() -> Rect2:
	var cells := logic_map.get_used_rect()
	var tile_size := Vector2(logic_map.tile_set.tile_size)
	var cells_rect := Rect2(Vector2(cells.position) * tile_size, Vector2(cells.size) * tile_size)
	var result := logic_map.transform * cells_rect
	return result.merge(space_station.transform * space_station.get_rect())
