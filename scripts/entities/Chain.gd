extends Line2D
class_name Chain
# Rayo de un solo uso: daña al objetivo y salta a los enemigos cercanos; la línea los sigue mientras dura.

# Cada cuánto cambia de variante el rayo.
const FLICKER_TIME := 0.05

var _data: ChainData
var _targets: Array[Enemy] = []
var _age := 0.0
var _variant := randi()

static func spawn(tower: Tower, first: Enemy) -> void:
	var data := tower.data.chain
	var chain := Chain.new()
	chain._data = data
	chain._targets = _pick_targets(first, data, tower.get_tree().get_nodes_in_group(&"enemies"))
	chain.add_point(tower.global_position)
	for enemy in chain._targets:
		chain.add_point(enemy.global_position)
	chain.texture = data.bolt_textures[chain._variant % data.bolt_textures.size()]
	chain.width = chain.texture.get_height()
	chain.texture_mode = Line2D.LINE_TEXTURE_TILE
	chain.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# Por encima de torretas y enemigos.
	chain.z_index = 1
	var world := tower.get_parent()
	world.add_child(chain)
	for enemy in chain._targets:
		enemy.take_damage(data.damage)
		if enemy.hp > 0:
			enemy.flash()
		if data.impact_frames:
			# Si el enemigo muere, el impacto se queda en el sitio en vez de desaparecer con él.
			Effect.spawn(enemy if enemy.hp > 0 else world, data.impact_frames, enemy.global_position, enemy.effect_scale())

# Cada salto va al enemigo más cercano al último alcanzado, dentro de jump_range y sin repetir.
static func _pick_targets(first: Enemy, data: ChainData, enemies: Array[Node]) -> Array[Enemy]:
	var targets: Array[Enemy] = [first]
	while targets.size() < data.max_targets:
		var last: Enemy = targets[-1]
		var next: Enemy = null
		var best := data.jump_range
		for enemy: Enemy in enemies:
			if enemy in targets or enemy.is_queued_for_deletion():
				continue
			var distance := last.global_position.distance_to(enemy.global_position)
			if distance <= best:
				best = distance
				next = enemy
		if next == null:
			break
		targets.append(next)
	return targets

func _process(delta: float) -> void:
	_age += delta
	if _age >= _data.bolt_time:
		queue_free()
		return
	texture = _data.bolt_textures[(_variant + int(_age / FLICKER_TIME)) % _data.bolt_textures.size()]
	for i in _targets.size():
		if is_instance_valid(_targets[i]):
			set_point_position(i + 1, _targets[i].global_position)
