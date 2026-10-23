extends PathFollow2D
class_name Enemy

signal died(reward: int)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var data: EnemyData
var speed: float
var hp: float
var max_hp: float
var _last_position: Vector2

# Los efectos que se pintan encima del enemigo son de 32 px; se escalan a su tamaño.
const EFFECT_SIZE := 32.0
const SLOW_FLASH := Color(3, 3, 3)
const SLOW_FLASH_TIME := 0.1
const SLOW_TINT := Color(0.65, 0.85, 1.0)
const HIT_FLASH_TIME := 0.15
const SPAWN_IN_TIME := 0.2
# Reparadora: cada HEAL_INTERVAL s cura HEAL_RATIO de su vida máxima a los enemigos a HEAL_RADIUS px o menos.
const HEAL_INTERVAL := 3.0
const HEAL_RATIO := 0.1
const HEAL_RADIUS := 48.0
const HEAL_TEXT_COLOR := Color("#7ee89a")
const HEAL_FLASH := Color(0.8, 2.5, 1.0)
const HEAL_FLASH_TIME := 0.4

# Multiplicador de velocidad mientras está ralentizado.
var _slow := 1.0
var _slow_tween: Tween
var _frost: AnimatedSprite2D
var _health_bar: HealthBar

# Camuflado: las torretas no lo eligen como objetivo, pero los ataques de área le dan.
var cloaked := false
const CLOAK_ALPHA := 0.2
# Disolución por píxeles con borde morado al camuflarse y al reaparecer.
const CLOAK_SHADER: Shader = preload("res://resources/shaders/cloak_dissolve.gdshader")
const CLOAK_DISSOLVE_TIME := 0.3

signal reached_end(damage: int)

func setup(enemy_data: EnemyData, health_multiplier: float = 1.0):
	data = enemy_data
	speed = data.speed
	max_hp = data.hp * health_multiplier
	hp = max_hp
	sprite.sprite_frames = data.sprite_frames
	collision_shape.shape = data.collision_shape
	_last_position = position
	_health_bar = HealthBar.new()
	add_child(_health_bar)
	var size := effect_scale() * EFFECT_SIZE
	_health_bar.setup(size, -size / 2.0)
	add_to_group(&"enemies")
	if data.cloak_interval > 0.0:
		_start_cloak_cycle()
	if data.heal_aura:
		var timer := Timer.new()
		timer.wait_time = HEAL_INTERVAL
		timer.autostart = true
		timer.timeout.connect(_heal_nearby)
		add_child(timer)
	if data.emp_interval > 0.0:
		EmpWave.attach(self)

## Sale del portal: crece de escala 0 a 1 con un destello.
func spawn_in() -> void:
	scale = Vector2.ZERO
	sprite.modulate = SLOW_FLASH
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, SPAWN_IN_TIME)
	tween.tween_property(sprite, "modulate", Color.WHITE, SPAWN_IN_TIME)

func _process(delta):
	progress += speed * _slow * delta
	_update_animation()
	if progress_ratio >= 1.0:
		set_process(false)
		reached_end.emit(data.base_damage)
		queue_free()

# Distancia que le falta para llegar al final de su camino.
func get_remaining_distance() -> float:
	return (get_parent() as Path2D).curve.get_baked_length() - progress

func _update_animation():
	# Posición local en el camino: el temblor del mapa mueve la global y no debe girar la nave.
	var direction := position - _last_position
	_last_position = position
	if direction.length() < 0.01:
		return
	if abs(direction.x) > abs(direction.y):
		sprite.play("right" if direction.x > 0 else "left")
	else:
		sprite.play("down" if direction.y > 0 else "up")
	if data.rotate_sprite:
		# El sprite base mira hacia arriba; se gira en pasos de 90°.
		sprite.rotation = snappedf(direction.angle() + PI / 2, PI / 2) + deg_to_rad(data.rotation_offset)

## `source`: la torreta que hiere (null si es un poder u otra cosa); se apunta el daño y la baja.
# `source` va sin tipo Turret a propósito: una bala sigue volando aunque su torreta se venda o se mejore,
# y pasar una torreta ya borrada a un parámetro tipado da error antes de poder comprobarla.
func take_damage(amount: float, source: Variant = null):
	var was_alive := hp > 0
	var dealt := clampf(amount, 0.0, maxf(hp, 0.0))
	hp -= amount
	if is_instance_valid(source):
		(source as Turret).register_damage(dealt, was_alive and hp <= 0)
	_health_bar.update(hp, max_hp)
	if hp <= 0:
		die()

## Cura sin pasar de la vida máxima, con el número en verde, un destello y chispas. Con la vida llena no hace nada.
func heal(amount: float) -> void:
	var healed := minf(amount, max_hp - hp)
	if healed <= 0.0 or hp <= 0.0:
		return
	hp += healed
	_health_bar.update(hp, max_hp)
	FloatingText.spawn(get_parent(), global_position, "+" + UiFormat.number(healed), FloatingText.DURATION, HEAL_TEXT_COLOR)
	HealEffect.spawn_sparks(self, effect_scale() * EFFECT_SIZE)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", _rest_color(), HEAL_FLASH_TIME).from(HEAL_FLASH)
	tween.tween_callback(func(): sprite.modulate = _rest_color())

# Reparadora: suelta el anillo y cura a los demás enemigos a HEAL_RADIUS px o menos (a sí misma no).
func _heal_nearby() -> void:
	HealEffect.spawn_ring(get_parent(), global_position, HEAL_RADIUS)
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy != self and enemy.global_position.distance_to(global_position) <= HEAL_RADIUS:
			enemy.heal(max_hp * HEAL_RATIO)

# Ralentiza durante `duration` segundos con un destello y la escarcha encima.
# Si ya estaba ralentizado se renueva la duración, no se acumula.
func slow(factor: float, duration: float, frost_frames: SpriteFrames = null) -> void:
	_slow = factor
	if _frost == null and frost_frames:
		_frost = AnimatedSprite2D.new()
		_frost.sprite_frames = frost_frames
		_frost.scale = Vector2.ONE * effect_scale()
		add_child(_frost)
		_frost.play()
	if _slow_tween:
		_slow_tween.kill()
	_slow_tween = create_tween()
	_slow_tween.tween_property(sprite, "modulate", SLOW_TINT, SLOW_FLASH_TIME).from(SLOW_FLASH)
	_slow_tween.tween_interval(duration)
	_slow_tween.tween_callback(_end_slow)

func _end_slow() -> void:
	_slow = 1.0
	sprite.modulate = Color.WHITE
	if _frost:
		_frost.queue_free()
		_frost = null

# Destello de golpe; al acabar vuelve al color normal, o al tinte si está ralentizado.
func flash() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", _rest_color(), HIT_FLASH_TIME).from(SLOW_FLASH)
	tween.tween_callback(func(): sprite.modulate = _rest_color())

func _rest_color() -> Color:
	return SLOW_TINT if _slow < 1.0 else Color.WHITE

func effect_scale() -> float:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if texture == null:
		return 1.0
	var frame_size := texture.get_size() * sprite.scale
	return maxf(frame_size.x, frame_size.y) / EFFECT_SIZE

# Bucle de camuflaje: visible `cloak_interval` s y camuflado `cloak_time` s.
# El sprite se disuelve con CLOAK_SHADER; la barra de vida se atenúa a la vez.
func _start_cloak_cycle() -> void:
	var material := ShaderMaterial.new()
	material.shader = CLOAK_SHADER
	material.set_shader_parameter(&"progress", 0.0)
	material.set_shader_parameter(&"cloaked_alpha", CLOAK_ALPHA)
	sprite.material = material
	var tween := create_tween().set_loops()
	tween.tween_interval(data.cloak_interval)
	tween.tween_callback(_set_cloaked.bind(true))
	_tween_dissolve(tween, material, 1.0, CLOAK_ALPHA)
	tween.tween_interval(data.cloak_time)
	tween.tween_callback(_set_cloaked.bind(false))
	_tween_dissolve(tween, material, 0.0, 1.0)

func _tween_dissolve(tween: Tween, material: ShaderMaterial, progress: float, bar_alpha: float) -> void:
	tween.tween_property(material, "shader_parameter/progress", progress, CLOAK_DISSOLVE_TIME)
	tween.parallel().tween_property(_health_bar, "modulate:a", bar_alpha, CLOAK_DISSOLVE_TIME)

func _set_cloaked(value: bool) -> void:
	cloaked = value

func die():
	died.emit(data.reward)
	_play_death_sound()
	FloatingText.spawn(get_parent(), global_position, "+" + UiFormat.money(data.reward))
	Debris.spawn(get_parent(), global_position, _sprite_colors(), effect_scale())
	queue_free()

# Colores de los restos por textura: get_image() es caro, así que se lee una vez por textura.
static var _debris_colors: Dictionary[Texture2D, Array] = {}

# Colores opacos del frame actual del sprite (cada 2 px), para los restos.
func _sprite_colors() -> Array[Color]:
	var colors: Array[Color] = []
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return colors
	if _debris_colors.has(texture):
		colors.assign(_debris_colors[texture])
		return colors
	var image := texture.get_image()
	_debris_colors[texture] = colors
	if image == null or image.is_compressed():
		return colors
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var color := image.get_pixel(x, y)
			if color.a > 0.9:
				colors.append(color)
	return colors

# El reproductor cuelga del padre (el camino) porque el enemigo se libera enseguida.
func _play_death_sound() -> void:
	if data.death_sound == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = data.death_sound
	player.bus = &"SFX"
	player.finished.connect(player.queue_free)
	get_parent().add_child(player)
	player.play()
