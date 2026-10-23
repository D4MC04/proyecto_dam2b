extends InspectableData
class_name EnemyData

# Rojo de motor de los enemigos (ver docs/design/art.md); acento de su ficha, distinto al de las torretas.
const ACCENT_COLOR := Color("#f0323c")
const INSPECT_TAG := "ENEMIGO"

@export var name: String
@export var hp: float
@export var speed: int
@export var reward: int
# Vida que quita a la estación al llegar al final del camino.
@export var base_damage: int = 10
@export var sprite_frames: SpriteFrames
@export var collision_shape: Shape2D
@export var rotate_sprite: bool = false
# Giro extra en grados para sprites que no miran hacia arriba.
@export var rotation_offset: float = 0.0
# Sonido al matarlo (no suena si llega a la estación).
@export var death_sound: AudioStream
# Camuflaje: cada `cloak_interval` segundos visible se camufla `cloak_time` segundos (0 = nunca).
@export var cloak_interval: float = 0.0
@export var cloak_time: float = 0.0
# Reparadora: cada pocos segundos cura a los enemigos de alrededor (ver Enemy).
@export var heal_aura: bool = false
# Opcional: frase corta que se enseña al final de la ficha.
@export_multiline var description: String
# Trozos que suelta al morir, de izquierda a derecha según su dibujo (ninguno si está vacío).
# Si sus SpriteFrames tienen la animación "crack", se ve un instante antes de partirse.
@export var split_into: Array[EnemyData] = []
# Pulso EMP (Saboteadora): cada `emp_interval` s apaga `emp_disable_time` s las torretas
# a `emp_radius` px o menos. Con `emp_interval` a 0 no suelta pulsos.
@export var emp_interval: float = 0.0
@export var emp_radius: float = 48.0
@export var emp_disable_time: float = 3.0

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

## Filas de la ficha: vida, velocidad (px/s), recompensa y daño a la estación.
func get_stats() -> Array[StatEntry]:
	return [
		StatEntry.new("health", "VIDA", UiFormat.number(hp)),
		StatEntry.new("speed", "VELOCIDAD", UiFormat.number(speed)),
		StatEntry.new("reward", "BOTÍN", UiFormat.money(reward)),
		StatEntry.new("damage", "DAÑO", UiFormat.number(base_damage)),
	]
