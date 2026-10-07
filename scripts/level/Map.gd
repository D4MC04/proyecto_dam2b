extends Node2D
class_name Map

@onready var visual_map = $VisualMap
@onready var logic_map = $LogicMap

func get_paths() -> Array[Path2D]:
	var result: Array[Path2D] = []
	result.assign($Paths.get_children())
	return result
