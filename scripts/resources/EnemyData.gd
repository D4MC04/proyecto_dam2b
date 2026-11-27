extends InspectableData
class_name EnemyData

# Rojo de motor de los enemigos (ver docs/design/art.md); acento de su ficha, distinto al de las torretas.
const ACCENT_COLOR: Color = Color("#f0323c")
const INSPECT_TAG: String = "TAG_ENEMY"

@export var name: String
@export var hp: float
@export var speed: int
@export var reward: int
# Vida que quita a la estación al llegar al final del camino.
@export var base_damage: int = 10
@export var sprite_frames: SpriteFrames
@export var collision_shape: Shape2D
@export var rotate_sprite: bool = false
# Jefe: su oleada empieza con el aviso de jefe, y al morir sacude el mapa.
@export var is_boss: bool = false
# Giro extra en grados para sprites que no miran hacia arriba.
@export var rotation_offset: float = 0.0
# Sonido al matarlo (no suena si llega a la estación).
@export var death_sound: AudioStream
# Camuflaje: sale camuflado y cada daño lo destapa `reveal_time` segundos (0 = nunca se camufla).
@export var reveal_time: float = 0.0
# Mender: con un rayo pasa `heal_rate` de su vida por segundo a la nave más dañada de cerca
# (ver Enemy). Con 0 no cura.
@export var heal_rate: float = 0.0
# Opcional: SpriteFrames según la vida que le queda, de más llena a casi vacía; `sprite_frames` es la
# de la vida llena. La Mender lo usa para que el saco se encoja.
@export var drain_frames: Array[SpriteFrames] = []
# Opcional: frase corta que se enseña al final de la ficha.
@export_multiline var description: String
# Trozos que suelta al morir, de izquierda a derecha según su dibujo (ninguno si está vacío).
# Si sus SpriteFrames tienen la animación "crack", se ve un instante antes de partirse.
@export var split_into: Array[EnemyData] = []
# Explosión EMP al morir (Payload): apaga `emp_disable_time` s las torretas a `emp_radius` px o menos
# y quita `death_damage` de vida a las naves que pille. Con `emp_radius` a 0 no explota.
@export var emp_radius: float = 0.0
@export var emp_disable_time: float = 3.0
@export var death_damage: float = 0.0

func get_inspect_icon() -> Texture2D:
	if sprite_frames != null and sprite_frames.has_animation("up"):
		return sprite_frames.get_frame_texture("up", 0)
	return null

func get_inspect_name() -> String:
	return tr(name)

func get_inspect_tag() -> String:
	return tr(INSPECT_TAG)

func get_inspect_accent() -> Color:
	return ACCENT_COLOR

func get_inspect_description() -> String:
	return tr(description)

## Filas de la ficha: vida, velocidad (px/s), recompensa y daño a la estación.
func get_stats() -> Array[StatEntry]:
	return [
		StatEntry.new("health", "STAT_HEALTH", UiFormat.number(hp)),
		StatEntry.new("speed", "STAT_SPEED", UiFormat.number(speed)),
		StatEntry.new("reward", "STAT_LOOT", UiFormat.money(reward)),
		StatEntry.new("damage", "STAT_DAMAGE", UiFormat.number(base_damage)),
	]
