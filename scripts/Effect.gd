extends AnimatedSprite2D
class_name Effect
# Efecto de un solo uso: reproduce su animación (sin loop) y se borra solo al acabar.

const GROUP := &"effects"
const MAX_EFFECTS := 60
# Con la opción de efectos reducidos el tope baja a esta cantidad.
const MAX_EFFECTS_LOW := 20

## Cuántos efectos (Effect y HealEffect) puede haber vivos a la vez; los sobrantes se omiten.
static func has_room(tree: SceneTree) -> bool:
	var limit := MAX_EFFECTS_LOW if Settings.get_value(&"low_effects") else MAX_EFFECTS
	return tree.get_node_count_in_group(GROUP) < limit

static func spawn(parent: Node, frames: SpriteFrames, pos: Vector2, size: float = 1.0) -> void:
	if not has_room(parent.get_tree()):
		return
	var effect := Effect.new()
	effect.add_to_group(GROUP)
	effect.sprite_frames = frames
	effect.scale = Vector2.ONE * (size if size > 0 else 1.0)
	parent.add_child(effect)
	effect.global_position = pos
	effect.animation_finished.connect(effect.queue_free)
	effect.play()
