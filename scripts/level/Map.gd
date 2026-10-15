extends Node2D
class_name Map

@onready var visual_map: TileMapLayer = $VisualMap
@onready var logic_map: TileMapLayer = $LogicMap
@onready var space_station: Base = $SpaceStation

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
	return result.merge(space_station.transform * _station_rect())

# Rectángulo local del fotograma actual de la estación: AnimatedSprite2D no tiene get_rect()
func _station_rect() -> Rect2:
	var texture := space_station.sprite_frames.get_frame_texture(space_station.animation, space_station.frame)
	var size := texture.get_size()
	var origin := space_station.offset - (size / 2.0 if space_station.centered else Vector2.ZERO)
	return Rect2(origin, size)


## Coloca el fondo (si lo hay) en el origen del área de juego, en coordenadas globales.
## Así no se mueve con el centrado del mapa y siempre cubre el área.
func place_background(area_rect: Rect2) -> void:
	var background := get_node_or_null("Background") as Node2D
	if background == null:
		return
	background.global_position = area_rect.position
