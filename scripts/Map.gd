class_name Map
extends Node2D

@onready var paths_node: Node2D = $Paths

func get_paths() -> Array[Path2D]:
	var result: Array[Path2D] = []
	result.assign(paths_node.get_children())
	return result
