extends Line2D
class_name Beam
# Haz de un solo uso: sale de la boca del cañón en la dirección a la que apunta,
# daña a todos los enemigos de la línea y se desvanece.

var _data: BeamData
var _age := 0.0

static func spawn(tower: Tower) -> void:
	var data := tower.data.beam
	# El sprite del cañón mira hacia arriba.
	var direction := Vector2.UP.rotated(tower.cannon.rotation)
	var from := tower.global_position + tower.data.muzzle_offset.rotated(tower.cannon.rotation)
	var beam := Beam.new()
	beam._data = data
	beam.points = [from, from + direction * data.length]
	_set_texture(beam, data.beam_textures[0])
	# Por encima de torretas y enemigos.
	beam.z_index = 1
	var world := tower.get_parent()
	world.add_child(beam)
	if tower.data.muzzle_flash:
		# El fogonazo nace en la boca: su centro queda medio sprite por delante.
		var flash_height := tower.data.muzzle_flash.get_frame_texture(&"default", 0).get_height()
		Effect.spawn(tower.cannon, tower.data.muzzle_flash, from + direction * flash_height / 2.0)
	for enemy: Enemy in tower.get_tree().get_nodes_in_group(&"enemies"):
		if enemy.is_queued_for_deletion():
			continue
		var offset := enemy.global_position - from
		var along := offset.dot(direction)
		if along < 0 or along > data.length or absf(offset.cross(direction)) > data.half_width:
			continue
		enemy.take_damage(data.damage)
		if enemy.hp > 0:
			enemy.flash()
		if data.impact_frames:
			Effect.spawn(world, data.impact_frames, enemy.global_position, enemy.effect_scale())

# Mira pegada al cañón (gira con él); la torreta la enseña durante la carga.
static func make_sight(tower: Tower) -> Line2D:
	var sight := Line2D.new()
	var from := tower.data.muzzle_offset
	sight.points = [from, from + Vector2.UP * tower.data.beam.length]
	_set_texture(sight, tower.data.beam.sight_texture)
	sight.visible = false
	tower.cannon.add_child(sight)
	return sight

static func _set_texture(line: Line2D, tile: Texture2D) -> void:
	line.texture = tile
	line.width = tile.get_height()
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _process(delta: float) -> void:
	_age += delta
	var index := int(_age / _data.frame_time)
	if index >= _data.beam_textures.size():
		queue_free()
		return
	texture = _data.beam_textures[index]
