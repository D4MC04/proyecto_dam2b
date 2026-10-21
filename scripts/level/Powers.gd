extends Node2D
class_name Powers
## Poderes del jugador: meteorito (con apuntado) y congelar. Lleva sus recargas, que corren en
## _process: siguen Engine.time_scale y se paran con la pausa. Va dentro de Level, así que al
## reiniciar se crea uno nuevo con los dos poderes listos. Solo LevelUI lo usa (y solo jugando).

enum Power { METEOR, FREEZE }

## Recarga de cada poder, en segundos de juego.
const COOLDOWNS: Dictionary[Power, float] = {
	Power.METEOR: 45.0,
	Power.FREEZE: 60.0,
}
const METEOR_RADIUS := 40.0
const METEOR_DAMAGE := 150.0
# Caída del meteorito: sale de este desplazamiento respecto al punto y tarda METEOR_FALL_TIME.
const METEOR_FALL_OFFSET := Vector2(-90, -150)
const METEOR_FALL_TIME := 0.3
# El impacto del lanzacohetes es de 24 px; a ×3 cubre casi todo el área (80 px).
const METEOR_EXPLOSION_SCALE := 3.0
const FREEZE_FACTOR := 0.3
const FREEZE_TIME := 4.0
const AIM_FILL_COLOR := Color(1.0, 0.7, 0.24, 0.15)
const AIM_BORDER_COLOR := Color("#ecb23c")

const METEOR_TEXTURE: Texture2D = preload("res://assets/sprites/backgrounds/espacio/cometa.png")
const EXPLOSION_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/rocket_launcher_impact.tres")
const EXPLOSION_SOUND: AudioStream = preload("res://assets/audio/effects/Turrets/Rocket/RocketExplosion.wav")
const FROST_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/cryo_frost.tres")

@export var state: LevelState

var _cooldown_left: Dictionary[Power, float] = {Power.METEOR: 0.0, Power.FREEZE: 0.0}
var _aiming := false

func _ready() -> void:
	# Elegir torre cancela el apuntado.
	state.selected_tower_changed.connect(func(data: TowerData) -> void:
		if data != null:
			cancel_aiming())

func _process(delta: float) -> void:
	for power: Power in _cooldown_left:
		_cooldown_left[power] = maxf(_cooldown_left[power] - delta, 0.0)

func get_cooldown_left(power: Power) -> float:
	return _cooldown_left[power]

func is_ready(power: Power) -> bool:
	return _cooldown_left[power] <= 0.0

func is_aiming() -> bool:
	return _aiming

## Pulsar un poder: el meteorito entra (o sale) del modo apuntar; congelar se lanza ya.
func use(power: Power) -> void:
	if power == Power.METEOR and _aiming:
		cancel_aiming()
	elif not is_ready(power):
		return
	elif power == Power.METEOR:
		# Apuntando no se coloca torre: se suelta la seleccionada.
		state.selected_tower = null
		_aiming = true
		queue_redraw()
	else:
		_freeze()

func cancel_aiming() -> void:
	_aiming = false
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _aiming:
		return
	if event is InputEventMouseMotion:
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_drop_meteor(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_aiming()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if not _aiming:
		return
	var center := get_local_mouse_position().round()
	draw_circle(center, METEOR_RADIUS, AIM_FILL_COLOR, true, -1.0, false)
	draw_circle(center, METEOR_RADIUS, AIM_BORDER_COLOR, false, 1.0, false)

func _drop_meteor(target: Vector2) -> void:
	cancel_aiming()
	_cooldown_left[Power.METEOR] = COOLDOWNS[Power.METEOR]
	var meteor := Sprite2D.new()
	meteor.texture = METEOR_TEXTURE
	add_child(meteor)
	meteor.global_position = target + METEOR_FALL_OFFSET
	# La cabeza del cometa mira a +x: se gira hacia donde cae.
	meteor.rotation = (-METEOR_FALL_OFFSET).angle()
	var tween := meteor.create_tween()
	tween.tween_property(meteor, "global_position", target, METEOR_FALL_TIME)
	tween.tween_callback(func() -> void:
		meteor.queue_free()
		_explode(target))

func _explode(target: Vector2) -> void:
	Effect.spawn(self, EXPLOSION_FRAMES, target, METEOR_EXPLOSION_SCALE)
	var player := AudioStreamPlayer2D.new()
	player.stream = EXPLOSION_SOUND
	player.bus = &"SFX"
	player.finished.connect(player.queue_free)
	add_child(player)
	player.global_position = target
	player.play()
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		# hp > 0: los que ya han muerto este frame siguen en el grupo hasta liberarse.
		if enemy.hp > 0 and enemy.global_position.distance_to(target) <= METEOR_RADIUS:
			enemy.take_damage(METEOR_DAMAGE)

func _freeze() -> void:
	_cooldown_left[Power.FREEZE] = COOLDOWNS[Power.FREEZE]
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.hp > 0:
			enemy.slow(FREEZE_FACTOR, FREEZE_TIME, FROST_FRAMES)
