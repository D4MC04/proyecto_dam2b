extends Node2D
class_name Powers
## Poderes del jugador: meteorito y ataque orbital (con apuntado) y congelar. Lleva sus recargas, que corren en
## _process: siguen Engine.time_scale y se paran con la pausa. Va dentro de Level, así que al
## reiniciar se crea uno nuevo con los dos poderes listos. Solo LevelUI lo usa (y solo jugando).

enum Power { METEOR, FREEZE, ORBITAL }

## Un poder se ha lanzado (el meteorito, al caer, y el ataque orbital, al empezar el rayo; no al empezar a apuntar).
signal power_used(power: Power)

## Recarga de cada poder, en segundos de juego.
const COOLDOWNS: Dictionary[Power, float] = {
	Power.METEOR: 45.0,
	Power.FREEZE: 60.0,
	Power.ORBITAL: 75.0,
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
# Ataque orbital: un rayo vertical barre la fila elegida de izquierda a derecha durante ORBITAL_TIME.
const ORBITAL_TIME := 2.0
const ORBITAL_DPS := 120.0
const ORBITAL_HALF_WIDTH := 6.0
const ORBITAL_HALF_HEIGHT := 16.0
const ORBITAL_BEAM_COLOR := Color("#40e0f0")
const ORBITAL_CORE_COLOR := Color("#ffffff")
const AIM_FILL_COLOR := Color(1.0, 0.7, 0.24, 0.15)
const AIM_BORDER_COLOR := Color("#ecb23c")

const METEOR_TEXTURE: Texture2D = preload("res://assets/sprites/backgrounds/espacio/cometa.png")
const EXPLOSION_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/rocket_launcher_impact.tres")
const EXPLOSION_SOUND: AudioStream = preload("res://assets/audio/effects/Turrets/Rocket/RocketExplosion.wav")
const FROST_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/cryo_frost.tres")

@export var state: LevelState

var _cooldown_left: Dictionary[Power, float] = {Power.METEOR: 0.0, Power.FREEZE: 0.0, Power.ORBITAL: 0.0}
# Poder que se está apuntando, o -1.
var _aimed_power := -1
var _orbital_row := 0.0
var _orbital_elapsed := ORBITAL_TIME

func _ready() -> void:
	# Elegir torre cancela el apuntado.
	state.selected_tower_changed.connect(func(data: TowerData) -> void:
		if data != null:
			cancel_aiming())

func _process(delta: float) -> void:
	for power: Power in _cooldown_left:
		_cooldown_left[power] = maxf(_cooldown_left[power] - delta, 0.0)
	if _orbital_elapsed < ORBITAL_TIME:
		_orbital_elapsed += delta
		var beam := _beam_position()
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			var offset := (enemy.global_position - beam).abs()
			if enemy.hp > 0 and offset.x <= ORBITAL_HALF_WIDTH and offset.y <= ORBITAL_HALF_HEIGHT:
				enemy.take_damage(ORBITAL_DPS * delta)
		queue_redraw()

func get_cooldown_left(power: Power) -> float:
	return _cooldown_left[power]

func is_ready(power: Power) -> bool:
	return _cooldown_left[power] <= 0.0

func is_aiming() -> bool:
	return _aimed_power != -1

func get_aimed_power() -> int:
	return _aimed_power

## Pulsar un poder: meteorito y ataque orbital entran (o salen) del modo apuntar; congelar se lanza ya.
func use(power: Power) -> void:
	if _aimed_power == power:
		cancel_aiming()
	elif not is_ready(power):
		return
	elif power == Power.FREEZE:
		_freeze()
	else:
		# Apuntando no se coloca torre: se suelta la seleccionada.
		state.selected_tower = null
		_aimed_power = power
		queue_redraw()

func cancel_aiming() -> void:
	_aimed_power = -1
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _aimed_power == -1:
		return
	if event is InputEventMouseMotion:
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _aimed_power == Power.METEOR:
				_drop_meteor(get_global_mouse_position())
			else:
				_fire_orbital(get_global_mouse_position().y)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_aiming()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if _orbital_elapsed < ORBITAL_TIME:
		var beam := to_local(_beam_position())
		var top := to_local(Vector2(0.0, Level.GAME_AREA_RECT.position.y)).y
		draw_rect(Rect2(beam.x - ORBITAL_HALF_WIDTH, top, ORBITAL_HALF_WIDTH * 2.0, beam.y - top), ORBITAL_BEAM_COLOR, true)
		draw_rect(Rect2(beam.x - 1.0, top, 2.0, beam.y - top), ORBITAL_CORE_COLOR, true)
		draw_rect(Rect2(beam.x - ORBITAL_HALF_WIDTH, beam.y - ORBITAL_HALF_HEIGHT, ORBITAL_HALF_WIDTH * 2.0, ORBITAL_HALF_HEIGHT * 2.0), ORBITAL_BEAM_COLOR, true)
	if _aimed_power == Power.ORBITAL:
		var row := to_local(Vector2(Level.GAME_AREA_RECT.position.x, get_global_mouse_position().y)).round()
		var band := Rect2(row.x, row.y - ORBITAL_HALF_HEIGHT, Level.GAME_AREA_RECT.size.x, ORBITAL_HALF_HEIGHT * 2.0)
		draw_rect(band, AIM_FILL_COLOR, true)
		draw_rect(band, AIM_BORDER_COLOR, false, 1.0)
		return
	if _aimed_power != Power.METEOR:
		return
	var center := get_local_mouse_position().round()
	draw_circle(center, METEOR_RADIUS, AIM_FILL_COLOR, true, -1.0, false)
	draw_circle(center, METEOR_RADIUS, AIM_BORDER_COLOR, false, 1.0, false)

func _drop_meteor(target: Vector2) -> void:
	cancel_aiming()
	_cooldown_left[Power.METEOR] = COOLDOWNS[Power.METEOR]
	power_used.emit(Power.METEOR)
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
	power_used.emit(Power.FREEZE)
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.hp > 0:
			enemy.slow(FREEZE_FACTOR, FREEZE_TIME, FROST_FRAMES)

func _fire_orbital(row_y: float) -> void:
	cancel_aiming()
	_cooldown_left[Power.ORBITAL] = COOLDOWNS[Power.ORBITAL]
	_orbital_row = row_y
	_orbital_elapsed = 0.0
	power_used.emit(Power.ORBITAL)

# Posición global del rayo: recorre el ancho del área de juego en ORBITAL_TIME.
func _beam_position() -> Vector2:
	var rect := Level.GAME_AREA_RECT
	return Vector2(rect.position.x + rect.size.x * _orbital_elapsed / ORBITAL_TIME, _orbital_row)
