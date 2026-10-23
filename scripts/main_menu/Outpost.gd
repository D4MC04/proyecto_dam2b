extends Node2D
class_name Outpost
## Puesto defensivo del menú: la estación del jugador con unas torretas alrededor, con los mismos
## sprites y animaciones que en los niveles. Las torretas giran y disparan cuando Skirmish las usa.
## En la escena va a la escala y con el tono de las naves de Skirmish, como parte del fondo.

const STATION_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/estacion.tres")
const STATION_ANIMATION: StringName = &"fase_0"
# Cada torreta: sus datos y su posición respecto a la estación
const TURRETS: Array[Array] = [
	[preload("res://resources/turret_data/turret.tres"), Vector2(-58, -66)],
	[preload("res://resources/turret_data/minigun.tres"), Vector2(66, -30)],
	[preload("res://resources/turret_data/turret.tres"), Vector2(26, 70)],
]

var _cannons: Array[AnimatedSprite2D] = []
var _data: Array[TurretData] = []


func _ready() -> void:
	var station: AnimatedSprite2D = AnimatedSprite2D.new()
	station.name = "Station"
	station.sprite_frames = STATION_FRAMES
	add_child(station)
	station.play(STATION_ANIMATION)
	for entry: Array in TURRETS:
		_add_turret(entry[0], entry[1])


func _add_turret(data: TurretData, offset: Vector2) -> void:
	var base: AnimatedSprite2D = AnimatedSprite2D.new()
	base.sprite_frames = data.sprite_frames
	base.position = offset
	add_child(base)
	base.play()
	var cannon: AnimatedSprite2D = AnimatedSprite2D.new()
	cannon.sprite_frames = data.cannon
	cannon.rotation = randf() * TAU
	base.add_child(cannon)
	cannon.play(&"default")
	cannon.animation_finished.connect(cannon.play.bind(&"default"))
	_cannons.append(cannon)
	_data.append(data)


## Gira la torreta más cercana hacia target (en coordenadas globales), anima el disparo y devuelve
## la posición global de su boca, de donde sale el disparo.
func fire_at(target: Vector2) -> Vector2:
	var best: int = 0
	for i: int in _cannons.size():
		if _cannons[i].global_position.distance_to(target) < _cannons[best].global_position.distance_to(target):
			best = i
	var cannon: AnimatedSprite2D = _cannons[best]
	# Los cañones miran hacia arriba, como en Turret._target_angle
	cannon.rotation = (target - cannon.global_position).angle() + PI / 2.0
	if cannon.sprite_frames.has_animation(&"fire_0"):
		cannon.play(&"fire_0")
	return cannon.to_global(_data[best].muzzle_offset)
