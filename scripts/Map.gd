extends Node2D
class_name Map

func get_paths() -> Array[Path2D]:
	var result: Array[Path2D] = []
	result.assign($Paths.get_children())
	return result
