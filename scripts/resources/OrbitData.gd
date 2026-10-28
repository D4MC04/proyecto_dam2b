extends Resource
class_name OrbitData
# Ataque en órbita: la torreta genera proyectiles que giran a su alrededor, en el anillo entre
# TurretData.min_range y el radio de attack_range, y explotan en área al chocar con un enemigo.
# No apunta: genera uno en cada cooldown mientras no tenga max_orbs en órbita.

@export var damage: float
# Radio (px) de la explosión alrededor del proyectil.
@export var splash_radius: float
# Proyectiles en órbita a la vez; con todos fuera no genera más.
@export var max_orbs: int = 4
# Velocidad de giro de la órbita, en grados por segundo.
@export var orbit_speed: float = 90.0
# Segundos que tarda un proyectil en salir en espiral del emisor hasta la órbita (no choca mientras).
@export var deploy_time: float = 0.6
# Animación en bucle del proyectil.
@export var orb_frames: SpriteFrames
# Animación (sin loop) de la explosión y su escala (entera, para no emborronar el pixel art).
@export var impact_frames: SpriteFrames
@export var impact_scale: float = 1.0
# Frame de la animación "fire_0" del emisor en el que sale el proyectil.
@export var fire_frame: int = 3

## Filas de la ficha propias de la órbita.
func get_stats() -> Array[StatEntry]:
	return [
		StatEntry.new("damage", "DAÑO", UiFormat.number(damage)),
		StatEntry.new("splash", "ÁREA", UiFormat.number(splash_radius)),
		StatEntry.new("targets", "CARGAS", UiFormat.abbreviate(max_orbs)),
		StatEntry.new("speed", "GIRO", UiFormat.number(orbit_speed)),
	]
