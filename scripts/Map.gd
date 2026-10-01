class_name Map
extends Node2D

# Mapa que cargará el nivel; lo fija el menú al elegir nivel.
static var selected := "res://scenes/maps/Map1.tscn"

func get_paths() -> Array[Path2D]:
	var result: Array[Path2D] = []
	# $Paths directo, no @onready: el Spawner lo pide antes del _ready de un mapa cargado por Level.
	result.assign($Paths.get_children())
	return result
