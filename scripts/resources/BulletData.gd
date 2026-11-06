extends Resource
class_name BulletData

@export var damage: float
@export var speed: float
@export var sprite_frames: SpriteFrames
@export var collision_shape: Shape2D
# Opcionales: sin configurar, la bala se comporta como siempre.
# Escala fija del sprite (entera, para no emborronar el pixel art); 0 = se ajusta a 8 px de ancho.
@export var sprite_scale: float = 0.0
# Giro extra en grados para sprites que no miran hacia la derecha.
@export var rotation_offset: float = 0.0
# Estela animada pegada a la cola de la bala.
@export var trail_frames: SpriteFrames
# Animación (sin loop) que se deja en el punto de impacto.
@export var impact_frames: SpriteFrames
# Enemigos extra que atraviesa antes de desaparecer; 0 = se destruye al primer impacto.
@export var pierce: int = 0
# Radio (px) del daño en área al impactar; 0 = solo daña al enemigo golpeado.
@export var splash_radius: float = 0.0
# Opcional: sonido (en el bus SFX) al impactar.
@export var hit_sound: AudioStream
# Opcional: frena a los enemigos que daña (velocidad × slow_factor durante slow_duration s); 0 s = no frena.
# En una salva (TurretData.salvo_count) solo frena la primera bala.
@export var slow_factor: float = 1.0
@export var slow_duration: float = 0.0
# Opcional: bocanadas de humo (sin loop) que la bala va dejando en su camino.
@export var smoke_frames: SpriteFrames

## Filas de la ficha propias de la bala.
func get_stats() -> Array[StatEntry]:
	var stats: Array[StatEntry] = [
		StatEntry.new("damage", "STAT_DAMAGE", UiFormat.number(damage)),
		StatEntry.new("speed", "STAT_BULLET_SPEED", UiFormat.number(speed)),
	]
	if pierce > 0:
		stats.append(StatEntry.new("pierce", "STAT_PIERCE", UiFormat.number(pierce)))
	if splash_radius > 0:
		stats.append(StatEntry.new("splash", "STAT_AREA", UiFormat.number(splash_radius)))
	if slow_duration > 0:
		stats.append(StatEntry.new("slow", "STAT_SLOW", "-%d%%" % roundi((1.0 - slow_factor) * 100.0)))
		stats.append(StatEntry.new("duration", "STAT_DURATION", UiFormat.seconds(slow_duration)))
	return stats
