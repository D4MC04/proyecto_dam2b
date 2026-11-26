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
const EFFECT_SIZE: float = 32.0
const SLOW_FLASH: Color = Color(3, 3, 3)
const SLOW_FLASH_TIME: float = 0.1
const SLOW_TINT: Color = Color(0.65, 0.85, 1.0)
const HIT_FLASH_TIME: float = 0.15
const SPAWN_IN_TIME: float = 0.2
# Mender: engancha el rayo a la nave más dañada a HEAL_RANGE px o menos y le pasa data.heal_rate de su
# vida por segundo. Cada HEAL_PULSE s la curada saca el número, las chispas y la onda verde.
const HEAL_RANGE: float = 64.0
# Solo cura lo que tiene delante: naves a menos de este ángulo (grados) de hacia donde mira.
const HEAL_CONE: float = 60.0
const HEAL_PULSE: float = 1.0
# Punta de la aguja en el sprite (sin contar su offset), de donde sale el rayo.
const NEEDLE_TIP: Vector2 = Vector2(0, -15)
const HEAL_TEXT_COLOR: Color = Color("#7ee89a")
# Onda de la curada: la de amplificar las torretas (amp_scan.gdshader), en verde.
const HEAL_SCAN_SHADER: Shader = preload("res://resources/shaders/amp_scan.gdshader")
const HEAL_SCAN_TIME: float = 0.45
const HEAL_SCAN_TRAIL: float = 3.0
const HEAL_SCAN_CORE: Color = Color("#f0fff4")
const HEAL_SCAN_COLOR: Color = Color("#7ee89a")
var _heal_target: Enemy
var _heal_beam: HealBeam
# Vida pasada a la curada que aún no ha salido en número, y cuánto falta para el siguiente.
var _heal_unshown: float = 0.0
var _heal_pulse_left: float = 0.0
var _heal_scan: ShaderMaterial
var _heal_scan_tween: Tween
# Nivel de data.drain_frames en uso (0 = sprite_frames, vida llena).
var _drain_level: int = 0
# Números de daño (opción show_damage_numbers): los golpes dentro de esta ventana (s) se suman en un solo número.
const DAMAGE_TEXT_COLOR: Color = Color("#ffffff")
const DAMAGE_TEXT_WINDOW: float = 0.25
var _pending_damage: float = 0.0
# Medio tramo (px) del camino con el que se calcula su tangente.
const TANGENT_STEP: float = 2.0

# Multiplicador de velocidad mientras está ralentizado.
var _slow: float = 1.0
var _slow_tween: Tween
var _frost: AnimatedSprite2D
var _health_bar: HealthBar

# Camuflado: las torretas no lo eligen como objetivo, pero los ataques de área le dan.
var cloaked: bool = false
const CLOAK_ALPHA: float = 0.2
# Disolución por píxeles con borde morado al camuflarse y al reaparecer.
const CLOAK_SHADER: Shader = preload("res://resources/shaders/cloak_dissolve.gdshader")
const CLOAK_DISSOLVE_TIME: float = 0.3
var _cloak_material: ShaderMaterial
var _cloak_tween: Tween

signal reached_end(damage: int)

func setup(enemy_data: EnemyData, health_multiplier: float = 1.0) -> void:
	data = enemy_data
	speed = data.speed
	max_hp = data.hp * health_multiplier
	hp = max_hp
	sprite.sprite_frames = data.sprite_frames
	collision_shape.shape = data.collision_shape
	_last_position = position
	_health_bar = HealthBar.new()
	add_child(_health_bar)
	var size: float = effect_scale() * EFFECT_SIZE
	_health_bar.setup(size, -size / 2.0)
	add_to_group(&"enemies")
	if data.reveal_time > 0.0:
		_start_cloaked()
	if data.heal_rate > 0.0:
		_heal_beam = HealBeam.new()
		add_child(_heal_beam)
	if data.emp_interval > 0.0:
		EmpWave.attach(self)

## Sale del portal: crece de escala 0 a 1 con un destello.
func spawn_in() -> void:
	scale = Vector2.ZERO
	sprite.modulate = SLOW_FLASH
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, SPAWN_IN_TIME)
	tween.tween_property(sprite, "modulate", Color.WHITE, SPAWN_IN_TIME)

func _process(delta: float) -> void:
	progress += get_move_speed() * delta
	_update_animation()
	if data.heal_rate > 0.0:
		_update_heal_beam(delta)
		if hp <= 0.0:
			return
	if progress_ratio >= 1.0:
		set_process(false)
		reached_end.emit(data.base_damage)
		queue_free()

# Velocidad (px/s) a lo largo del camino, con la ralentización actual.
func get_move_speed() -> float:
	return speed * _slow

## Velocidad global del enemigo (px/s): tangente del camino en su progreso por get_move_speed().
func get_move_velocity() -> Vector2:
	var path: Path2D = get_parent() as Path2D
	if path == null:
		return Vector2.ZERO
	var curve: Curve2D = path.curve
	var tangent: Vector2 = curve.sample_baked(minf(progress + TANGENT_STEP, curve.get_baked_length())) - curve.sample_baked(maxf(progress - TANGENT_STEP, 0.0))
	return path.global_transform.basis_xform(tangent).normalized() * get_move_speed()

# Distancia que le falta para llegar al final de su camino.
func get_remaining_distance() -> float:
	return (get_parent() as Path2D).curve.get_baked_length() - progress

func _update_animation() -> void:
	# Posición local en el camino: el temblor del mapa mueve la global y no debe girar la nave.
	var direction: Vector2 = position - _last_position
	_last_position = position
	if direction.length() < 0.01:
		return
	if abs(direction.x) > abs(direction.y):
		sprite.play("right" if direction.x > 0 else "left")
	else:
		sprite.play("down" if direction.y > 0 else "up")
	if data.rotate_sprite:
		# El sprite base mira hacia arriba; sigue la dirección del camino, así que en las curvas gira poco a poco.
		sprite.rotation = direction.angle() + PI / 2 + deg_to_rad(data.rotation_offset)

## `source`: la torreta que hiere (null si es un poder u otra cosa); se apunta el daño y la baja.
# `source` va sin tipo Turret a propósito: una bala sigue volando aunque su torreta se venda o se mejore,
# y pasar una torreta ya borrada a un parámetro tipado da error antes de poder comprobarla.
func take_damage(amount: float, source: Variant = null) -> void:
	var was_alive: bool = hp > 0
	var dealt: float = clampf(amount, 0.0, maxf(hp, 0.0))
	hp -= amount
	if is_instance_valid(source):
		(source as Turret).register_damage(dealt, was_alive and hp <= 0)
	_health_bar.update(hp, max_hp)
	_update_drain_frames()
	if data.reveal_time > 0.0 and amount > 0.0 and hp > 0:
		_reveal()
	if Settings.get_value(&"show_damage_numbers"):
		_queue_damage_text(dealt)
	if hp <= 0:
		_flush_damage_text()
		die()

# Acumula el daño; el número sale al acabar la ventana (o al morir) para no tapar la nave con una ráfaga.
func _queue_damage_text(dealt: float) -> void:
	if dealt <= 0.0:
		return
	if _pending_damage <= 0.0:
		get_tree().create_timer(DAMAGE_TEXT_WINDOW).timeout.connect(_flush_damage_text)
	_pending_damage += dealt

func _flush_damage_text() -> void:
	if _pending_damage <= 0.0:
		return
	FloatingText.spawn(get_parent(), global_position, UiFormat.number(_pending_damage), FloatingText.DURATION, DAMAGE_TEXT_COLOR)
	_pending_damage = 0.0

## Cura sin pasar de la vida máxima y devuelve lo curado (0 con la vida llena o ya muerto).
## No enseña nada: los efectos salen con show_heal().
func heal(amount: float) -> float:
	var healed: float = minf(amount, max_hp - hp)
	if healed <= 0.0 or hp <= 0.0:
		return 0.0
	set_health(hp + healed)
	return healed

## Pone la vida sin golpe ni efectos (barra y saco de la Mender al día).
func set_health(value: float) -> void:
	hp = value
	_health_bar.update(hp, max_hp)
	_update_drain_frames()

## Efectos de recibir cura: el número en verde (si `amount` > 0), chispas y la onda verde.
func show_heal(amount: float) -> void:
	if amount > 0.0:
		FloatingText.spawn(get_parent(), global_position, "+" + UiFormat.number(amount), FloatingText.DURATION, HEAL_TEXT_COLOR)
		HealEffect.spawn_sparks(self, effect_scale() * EFFECT_SIZE)
	_flash_heal()

# Onda verde que sube por la nave con el contorno brillando, como la del Amplificador en las torretas.
# No pisa otro material (la disolución del camuflaje).
func _flash_heal() -> void:
	if sprite.material != null and sprite.material != _heal_scan:
		return
	if _heal_scan == null:
		_heal_scan = ShaderMaterial.new()
		_heal_scan.shader = HEAL_SCAN_SHADER
		_heal_scan.set_shader_parameter("trail_length", HEAL_SCAN_TRAIL)
		_heal_scan.set_shader_parameter("core_color", HEAL_SCAN_CORE)
		_heal_scan.set_shader_parameter("amber_color", HEAL_SCAN_COLOR)
	var half_height: float = effect_scale() * EFFECT_SIZE / 2.0
	_heal_scan.set_shader_parameter("line_start", global_position.y + half_height)
	_heal_scan.set_shader_parameter("line_end", global_position.y - half_height - HEAL_SCAN_TRAIL)
	_heal_scan.set_shader_parameter("progress", 0.0)
	sprite.material = _heal_scan
	if _heal_scan_tween:
		_heal_scan_tween.kill()
	_heal_scan_tween = create_tween()
	_heal_scan_tween.tween_method(func(value: float) -> void: _heal_scan.set_shader_parameter("progress", value), 0.0, 1.0, HEAL_SCAN_TIME)
	_heal_scan_tween.tween_callback(func() -> void:
		if sprite.material == _heal_scan:
			sprite.material = null)

# Mender: mantiene el rayo en la curada (o busca otra) y le pasa vida de la suya. Si se vacía, muere.
func _update_heal_beam(delta: float) -> void:
	if not _can_heal(_heal_target):
		_set_heal_target(_find_heal_target())
	if _heal_target == null:
		return
	_heal_beam.update_ends(sprite.to_global(sprite.offset + NEEDLE_TIP), _heal_target.global_position)
	var healed: float = _heal_target.heal(minf(data.heal_rate * delta, hp))
	_heal_unshown += healed
	_heal_pulse_left -= delta
	if _heal_pulse_left <= 0.0:
		_heal_pulse_left = HEAL_PULSE
		_heal_target.show_heal(_heal_unshown)
		_heal_unshown = 0.0
	set_health(hp - healed)
	if hp <= 0.0:
		_set_heal_target(null)
		set_process(false)
		die()

func _can_heal(enemy: Enemy) -> bool:
	if not is_instance_valid(enemy) or enemy == self or enemy.is_queued_for_deletion() \
			or enemy.hp <= 0.0 or enemy.hp >= enemy.max_hp:
		return false
	var offset: Vector2 = enemy.global_position - global_position
	if offset.length() > HEAL_RANGE:
		return false
	# Hacia donde mira el sprite (el dibujo mira hacia arriba).
	var facing: Vector2 = Vector2.UP.rotated(sprite.global_rotation - deg_to_rad(data.rotation_offset))
	return facing.dot(offset.normalized()) >= cos(deg_to_rad(HEAL_CONE))

# La nave a curar con menos vida en proporción (null si no hay ninguna dañada cerca).
func _find_heal_target() -> Enemy:
	var best: Enemy = null
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy: Enemy = node as Enemy
		if _can_heal(enemy) and (best == null or enemy.hp / enemy.max_hp < best.hp / best.max_hp):
			best = enemy
	return best

# Cambia de curada: la anterior saca lo que le faltaba por enseñar y la nueva, la onda al engancharse.
func _set_heal_target(enemy: Enemy) -> void:
	if enemy == _heal_target:
		return
	if is_instance_valid(_heal_target) and _heal_unshown > 0.0:
		_heal_target.show_heal(_heal_unshown)
	_heal_unshown = 0.0
	_heal_pulse_left = HEAL_PULSE
	_heal_target = enemy
	_heal_beam.visible = enemy != null
	if enemy != null:
		enemy.show_heal(0.0)

# Con data.drain_frames, cambia el dibujo según la vida que le queda (el saco de la Mender se encoge).
func _update_drain_frames() -> void:
	if data.drain_frames.is_empty():
		return
	var levels: int = data.drain_frames.size() + 1
	var level: int = clampi(int((1.0 - hp / max_hp) * levels), 0, levels - 1)
	if level == _drain_level:
		return
	_drain_level = level
	var animation: StringName = sprite.animation
	var frame: int = sprite.frame
	var frame_progress: float = sprite.frame_progress
	sprite.sprite_frames = data.sprite_frames if level == 0 else data.drain_frames[level - 1]
	sprite.play(animation)
	sprite.set_frame_and_progress(frame, frame_progress)

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
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", _rest_color(), HIT_FLASH_TIME).from(SLOW_FLASH)
	tween.tween_callback(func() -> void: sprite.modulate = _rest_color())

func _rest_color() -> Color:
	return SLOW_TINT if _slow < 1.0 else Color.WHITE

func effect_scale() -> float:
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if texture == null:
		return 1.0
	var frame_size: Vector2 = texture.get_size() * sprite.scale
	return maxf(frame_size.x, frame_size.y) / EFFECT_SIZE

# Camuflaje: sale ya camuflado (sprite disuelto con CLOAK_SHADER y barra de vida atenuada).
func _start_cloaked() -> void:
	_cloak_material = ShaderMaterial.new()
	_cloak_material.shader = CLOAK_SHADER
	_cloak_material.set_shader_parameter(&"progress", 1.0)
	_cloak_material.set_shader_parameter(&"cloaked_alpha", CLOAK_ALPHA)
	sprite.material = _cloak_material
	_health_bar.modulate.a = CLOAK_ALPHA
	_set_cloaked(true)

# Al recibir daño se destapa `reveal_time` s (cada golpe reinicia la cuenta) y luego se vuelve a camuflar.
func _reveal() -> void:
	if _cloak_tween:
		_cloak_tween.kill()
	_set_cloaked(false)
	_cloak_tween = create_tween()
	_tween_dissolve(_cloak_tween, _cloak_material, 0.0, 1.0)
	_cloak_tween.tween_interval(data.reveal_time)
	_cloak_tween.tween_callback(_set_cloaked.bind(true))
	_tween_dissolve(_cloak_tween, _cloak_material, 1.0, CLOAK_ALPHA)

func _tween_dissolve(tween: Tween, material: ShaderMaterial, progress: float, bar_alpha: float) -> void:
	tween.tween_property(material, "shader_parameter/progress", progress, CLOAK_DISSOLVE_TIME)
	tween.parallel().tween_property(_health_bar, "modulate:a", bar_alpha, CLOAK_DISSOLVE_TIME)

func _set_cloaked(value: bool) -> void:
	cloaked = value

func die() -> void:
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
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return colors
	if _debris_colors.has(texture):
		colors.assign(_debris_colors[texture])
		return colors
	var image: Image = texture.get_image()
	_debris_colors[texture] = colors
	if image == null or image.is_compressed():
		return colors
	for y: int in range(0, image.get_height(), 2):
		for x: int in range(0, image.get_width(), 2):
			var color: Color = image.get_pixel(x, y)
			if color.a > 0.9:
				colors.append(color)
	return colors

# El reproductor cuelga del padre (el camino) porque el enemigo se libera enseguida.
func _play_death_sound() -> void:
	if data.death_sound == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = data.death_sound
	player.bus = &"SFX"
	player.finished.connect(player.queue_free)
	get_parent().add_child(player)
	player.play()
