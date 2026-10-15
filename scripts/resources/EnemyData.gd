extends InspectableData
class_name EnemyData

# Rojo de motor de los enemigos (ver docs/design/art.md); acento de su ficha, distinto al de las torres.
const ACCENT_COLOR := Color("#f0323c")
const INSPECT_TAG := "ENEMIGO"

@export var name: String
@export var hp: int
@export var speed: int
@export var reward: int
@export var sprite_frames: SpriteFrames
@export var collision_shape: Shape2D
@export var rotate_sprite: bool = false
# Giro extra en grados para sprites que no miran hacia arriba.
@export var rotation_offset: float = 0.0
# Opcional: frase corta que se enseña al final de la ficha.
@export_multiline var description: String

func get_inspect_icon() -> Texture2D:
	if sprite_frames != null and sprite_frames.has_animation("up"):
		return sprite_frames.get_frame_texture("up", 0)
	return null

func get_inspect_name() -> String:
	return name

func get_inspect_tag() -> String:
	return INSPECT_TAG

func get_inspect_accent() -> Color:
	return ACCENT_COLOR

func get_inspect_description() -> String:
	return description

## Filas de la ficha: vida, velocidad (px/s) y recompensa.
func get_stats() -> Array[StatEntry]:
	return [
		StatEntry.new("health", "Vida", UiFormat.number(hp)),
		StatEntry.new("speed", "Velocidad", UiFormat.number(speed)),
		StatEntry.new("reward", "Recompensa", UiFormat.abbreviate(reward) + "€"),
	]
