class_name Turret
extends Node2D

@export var data: TurretData
@export var bullet_scene: PackedScene

# Margen para disparar sin que el cañón esté perfectamente alineado.
const AIM_TOLERANCE := deg_to_rad(12.0)
# Color de la base y el cañón mientras un pulso EMP la tiene apagada: muy oscuro y azulado.
const DISABLED_TINT := Color(0.22, 0.25, 0.38)
# Destello al volver a encenderse.
const ENABLE_FLASH := Color(3, 3, 3)
const ENABLE_FLASH_TIME := 0.3
# Animación al construir (flash normal) y al fusionar (flash más fuerte).
const BUILD_FLASH := Color(2, 2, 2)
const FUSE_FLASH := Color(5, 5, 5)
const BUILD_TIME := 0.35
# Animación al vender: se encoge soltando chispas.
const SELL_TIME := 0.25
const SELL_SPARK_COLOR := Color("#ffe082")
# Fundido al cortar el sonido de disparo cuando la torreta se queda sin objetivo.
const SHOOT_FADE_TIME := 0.12
const SHOOT_FADE_DB := -40.0
# Sobrecalentamiento: tinte con el calor al máximo y parpadeo (cada OVERHEAT_BLINK s) mientras está parada.
const HEAT_TINT := Color(1.0, 0.3, 0.2)
const OVERHEAT_FLASH := Color(2.5, 0.6, 0.3)
const OVERHEAT_BLINK := 0.12
# Con este calor ya dispara a la cadencia máxima; de ahí al sobrecalentamiento sigue a tope.
const FULL_SPEED_HEAT := 0.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var cannon: AnimatedSprite2D = $Cannon
@onready var attack_range_area: Area2D = $RangeDetector
@onready var attack_range_shape: CollisionShape2D = $RangeDetector/CollisionShape2D
@onready var attack_timer: Timer = $Timer

# Dinero total gastado en esta torreta (colocación y fusiones); la venta devuelve la mitad.
var invested := 0
# Bajas y daño hecho por esta torreta (la fusión los hereda).
var kills := 0
var damage_dealt := 0.0
var enemies_in_range: Array[Enemy] = []
var _shots := 0
var _target: Enemy = null
# Cooldown cumplido, a la espera de que el cañón termine de girar hacia el enemigo.
var _pending_shot := false
# Sobrecalentamiento (ver TurretData.overheat_shots): calor de 0 a 1, segundos que le quedan parada
# y si base y cañón llevan tinte de calor (para devolverles el blanco una sola vez al enfriarse).
var _heat := 0.0
var _overheat_left := 0.0
var _heat_tinted := false
var _heat_glow: HeatGlow
# Mira de las torretas de haz; solo se ve durante la carga.
var _sight: Line2D
# Sonido de disparo; con poca polifonía, 10 torretas juntas no saturan.
var _shoot_player := AudioStreamPlayer2D.new()
var _shoot_fade: Tween
# Sonido de carga (opcional): suena desde que empieza fire_0 hasta el fire_frame.
var _charge_player: AudioStreamPlayer2D
# Apagada por un pulso EMP (ver disable): no apunta ni dispara.
var disabled := false
var _disable_tween: Tween
var _sparks: EmpSparks
# Ratón sobre la torreta: dibuja el alcance.
var _hovered := false
## Seleccionada en el mapa (ver LevelState.sellable_turret): dibuja el alcance.
var selected := false:
	set(value):
		selected = value
		queue_redraw()

const HOVER_HALF_SIZE := 8.0

func _ready() -> void:
	add_to_group(&"turrets")
	# Si cambia una opción en plena partida, se vuelve a dibujar el rango.
	Settings.changed.connect(queue_redraw.unbind(1))
	sprite.sprite_frames = data.sprite_frames
	cannon.sprite_frames = data.cannon
	set_process(data.cannon != null and not _is_static())
	if data.beam:
		_sight = Beam.make_sight(self)
		cannon.animation_changed.connect(_on_cannon_frame_changed)
	if _is_static() or data.beam:
		cannon.play()
		cannon.frame_changed.connect(_on_cannon_frame_changed)
		cannon.animation_finished.connect(cannon.play.bind(&"default"))
	_shoot_player.stream = data.shoot_sound
	_shoot_player.bus = &"SFX"
	_shoot_player.max_polyphony = 2
	add_child(_shoot_player)
	if data.charge_sound:
		_charge_player = AudioStreamPlayer2D.new()
		_charge_player.stream = data.charge_sound
		_charge_player.bus = &"SFX"
		add_child(_charge_player)
	attack_range_shape.shape = data.attack_range
	attack_timer.wait_time = data.attack_cooldown
	attack_timer.timeout.connect(_on_attack_timeout)
	attack_range_area.area_entered.connect(_on_area_entered)
	attack_range_area.area_exited.connect(_on_area_exited)
	attack_timer.start()
	if data.focus_beam:
		# El haz continuo no dispara por cooldown: lo lleva su propio nodo.
		attack_timer.stop()
		add_child(FocusBeam.new())

# Con la opción "mostrar rango" activada, cada torreta dibuja su alcance bajo sus sprites.
# Con la opción apagada, solo la que tiene el ratón encima o está seleccionada.
func _draw() -> void:
	if (Settings.get_value(&"show_turret_range") or _hovered or selected) and data.attack_range:
		BuildManager.draw_range_circle(self, data.attack_range)

# Con el ratón encima (casilla de 16 px) se ve el alcance aunque la opción esté apagada.
func _physics_process(_delta: float) -> void:
	var delta := (get_global_mouse_position() - global_position).abs()
	var hovered: bool = maxf(delta.x, delta.y) <= HOVER_HALF_SIZE
	if hovered != _hovered:
		_hovered = hovered
		queue_redraw()

func _process(delta: float) -> void:
	if disabled:
		return
	var target := _get_target()
	if data.overheat_shots > 0 and _update_overheat(delta, target != null):
		return
	if target == null:
		# El haz (continuo o de carga) lleva su propio corte y no debe apagar el disparo que acaba de salir.
		if not data.focus_beam and not data.beam:
			_stop_shoot_sound()
		return
	# Gira poco a poco por el camino más corto; sin enemigo se queda donde está.
	if data.turn_speed > 0:
		cannon.rotation = rotate_toward(cannon.rotation, _target_angle(target), deg_to_rad(data.turn_speed) * delta)
	else:
		cannon.rotation = _target_angle(target)
	if _pending_shot and _is_aimed(target):
		_pending_shot = false
		attack_timer.start()
		_shoot(target)

## Enfría o cuenta la parada y tiñe la torreta según el calor. Devuelve true mientras está sobrecalentada.
func _update_overheat(delta: float, has_target: bool) -> bool:
	if _overheat_left > 0.0:
		_overheat_left -= delta
		if _overheat_left > 0.0:
			var flash_on := fmod(_overheat_left, OVERHEAT_BLINK * 2.0) < OVERHEAT_BLINK
			_set_heat_tint(OVERHEAT_FLASH if flash_on else HEAT_TINT)
			_heat_tinted = true
			_show_heat(true)
			return true
		# Ya se ha enfriado: vuelve a la cadencia base.
		_heat = 0.0
		attack_timer.start(data.attack_cooldown)
	elif not has_target and _heat > 0.0:
		_heat = move_toward(_heat, 0.0, delta / data.overheat_cool_time)
		attack_timer.wait_time = _heat_cooldown()
	if _heat > 0.0 or _heat_tinted:
		_set_heat_tint(Color.WHITE.lerp(HEAT_TINT, _heat))
		_heat_tinted = _heat > 0.0
	_show_heat(false)
	return false

# Cuanto más caliente, menos cooldown. Empieza lento, acelera (curva al cuadrado) y desde
# FULL_SPEED_HEAT dispara a la cadencia máxima hasta sobrecalentarse.
func _heat_cooldown() -> float:
	var t := minf(_heat / FULL_SPEED_HEAT, 1.0)
	return lerpf(data.attack_cooldown, data.overheat_min_cooldown, t * t)

# Halo y chispas de calor (HeatGlow) en la boca del cañón; se crea la primera vez que hay calor.
func _show_heat(overheated: bool) -> void:
	if _heat_glow == null:
		if _heat <= 0.0 and not overheated:
			return
		_heat_glow = HeatGlow.new()
		_heat_glow.position = data.muzzle_offset
		cannon.add_child(_heat_glow)
	_heat_glow.heat = _heat
	_heat_glow.overheated = overheated

func _set_heat_tint(color: Color) -> void:
	sprite.modulate = color
	# self_modulate: el tinte no debe oscurecer el halo y las chispas (HeatGlow cuelga del cañón).
	cannon.self_modulate = color

# Cada disparo calienta; al llegar al máximo se para overheat_time segundos.
func _add_heat() -> void:
	_heat = minf(_heat + 1.0 / data.overheat_shots, 1.0)
	if _heat >= 0.999:
		_heat = 1.0
		_overheat_left = data.overheat_time
		attack_timer.stop()
	else:
		attack_timer.start(_heat_cooldown())

# El sprite del cañón mira hacia arriba: ángulo hacia el enemigo más 90°.
func _target_angle(target: Enemy) -> float:
	return (target.global_position - global_position).angle() + PI / 2

func _is_aimed(target: Enemy) -> bool:
	return data.cannon == null or absf(angle_difference(cannon.rotation, _target_angle(target))) <= AIM_TOLERANCE

func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy is Enemy:
		enemies_in_range.append(enemy)

func _on_area_exited(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy is Enemy:
		enemies_in_range.erase(enemy)

func _on_attack_timeout() -> void:
	var target := _get_target()
	# La onda es de área: sale aunque en rango solo haya naves camufladas.
	var pulse_has_enemies := data.pulse != null and enemies_in_range.any(is_instance_valid)
	if target == null and not pulse_has_enemies:
		_stop_shoot_sound()
		return
	if _is_static():
		_start_charge()
		cannon.play(&"fire_0")
		return
	if _is_aimed(target):
		_shoot(target)
	else:
		# El cooldown no se gasta: dispara en cuanto el cañón quede alineado.
		_pending_shot = true
		attack_timer.stop()

# Torretas de onda o de rayo: el cañón no gira ni dispara balas.
func _is_static() -> bool:
	return data.pulse != null or data.chain != null

# La onda, el rayo o el haz salen en su frame de la animación de disparo.
func _on_cannon_frame_changed() -> void:
	var firing := cannon.animation == &"fire_0" and not disabled
	if _sight:
		_sight.visible = firing and cannon.frame < data.beam.fire_frame
	if not firing:
		return
	if _charge_player and cannon.frame == _fire_frame():
		_charge_player.stop()
	if data.pulse and cannon.frame == data.pulse.fire_frame:
		_play_shoot()
		Pulse.spawn(self)
	elif data.chain and cannon.frame == data.chain.fire_frame:
		var target := _get_target()
		if target:
			_play_shoot()
			Chain.spawn(self, target)
	elif data.beam and cannon.frame == data.beam.fire_frame:
		_play_shoot()
		Beam.spawn(self)

# Frame de fire_0 en el que sale el ataque de la torreta estática o de haz.
func _fire_frame() -> int:
	if data.beam:
		return data.beam.fire_frame
	if data.chain:
		return data.chain.fire_frame
	if data.pulse:
		return data.pulse.fire_frame
	return -1

func _start_charge() -> void:
	if _charge_player:
		_charge_player.play()

# Un disparo nuevo cancela el fundido en curso y devuelve el volumen normal.
func _play_shoot() -> void:
	if _shoot_fade:
		_shoot_fade.kill()
	_shoot_player.volume_db = 0.0
	_shoot_player.play()

# Sin objetivo, el disparo que siga sonando se apaga con un fundido corto.
func _stop_shoot_sound() -> void:
	if not _shoot_player.playing or (_shoot_fade and _shoot_fade.is_valid()):
		return
	_shoot_fade = create_tween()
	_shoot_fade.tween_property(_shoot_player, "volume_db", SHOOT_FADE_DB, SHOOT_FADE_TIME)
	_shoot_fade.tween_callback(_shoot_player.stop)

func _shoot(target: Enemy) -> void:
	if data.beam:
		# Empieza la carga; el haz sale después, hacia donde apunte el cañón en ese momento.
		_start_charge()
		cannon.play(&"fire_0")
		return
	_play_shoot()
	var bullet: Bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	# La boca gira con el cañón (sin cañón, su rotación es 0 y no cambia nada).
	# Con dos cañones (muzzle_offset.x != 0) los disparos alternan de lado.
	var muzzle := data.muzzle_offset * Vector2(-1 if _shots % 2 else 1, 1)
	bullet.global_position = global_position + muzzle.rotated(cannon.rotation)
	bullet.source = self
	bullet.setup(data.bullet_data, target)
	if data.muzzle_flash:
		Effect.spawn(cannon, data.muzzle_flash, bullet.global_position, data.bullet_data.sprite_scale)
	var fire_anims := data.cannon.get_animation_names().size() - 1 if data.cannon else 0
	if fire_anims > 0:
		cannon.play("fire_%d" % (_shots % fire_anims))
	_shots += 1
	if data.overheat_shots > 0:
		_add_heat()

# Mantiene el objetivo mientras siga vivo y dentro del rango.
func _get_target() -> Enemy:
	if not is_instance_valid(_target) or not enemies_in_range.has(_target) or _target.cloaked:
		_target = _best_enemy()
	return _target

func _best_enemy() -> Enemy:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	var best: Enemy = null
	var best_remaining: float = INF
	for enemy in enemies_in_range:
		# Las naves camufladas no se apuntan.
		if enemy.cloaked:
			continue
		var remaining := enemy.get_remaining_distance()
		if remaining < best_remaining:
			best_remaining = remaining
			best = enemy
	return best

## La apaga `seconds` segundos: no apunta ni dispara, se oscurece y le saltan chispas.
## Si ya estaba apagada se renueva la duración, no se acumula.
func disable(seconds: float) -> void:
	disabled = true
	attack_timer.paused = true
	sprite.modulate = DISABLED_TINT
	cannon.modulate = DISABLED_TINT
	# Corta la carga o el disparo que estuviera a medias.
	if cannon.sprite_frames and cannon.animation != &"default":
		cannon.play(&"default")
	if _charge_player:
		_charge_player.stop()
	_stop_shoot_sound()
	# El cañón se queda quieto aunque algo vuelva a lanzar su animación.
	cannon.speed_scale = 0.0
	if _sparks == null:
		_sparks = EmpSparks.new()
		add_child(_sparks)
	_sparks.start(seconds)
	if _disable_tween:
		_disable_tween.kill()
	_disable_tween = create_tween()
	_disable_tween.tween_interval(seconds)
	_disable_tween.tween_callback(_enable)

func _enable() -> void:
	disabled = false
	attack_timer.paused = false
	cannon.speed_scale = 1.0
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "modulate", Color.WHITE, ENABLE_FLASH_TIME).from(ENABLE_FLASH)
	tween.tween_property(cannon, "modulate", Color.WHITE, ENABLE_FLASH_TIME).from(ENABLE_FLASH)
	_sparks.queue_free()
	_sparks = null

## Apunta el daño que ha hecho un disparo suyo y si ha matado.
func register_damage(amount: float, killed: bool) -> void:
	damage_dealt += amount
	if killed:
		kills += 1

## Dinero que devuelve vender la torreta: la mitad de lo invertido, redondeada hacia abajo.
func get_sell_value() -> int:
	return floori(invested / 2.0)

## Aparece con escala de 0 a 1 con rebote y un destello (más fuerte si es una fusión).
func play_build(fused := false) -> void:
	scale = Vector2.ZERO
	var flash := FUSE_FLASH if fused else BUILD_FLASH
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, BUILD_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color.WHITE, BUILD_TIME).from(flash)
	tween.tween_property(cannon, "modulate", Color.WHITE, BUILD_TIME).from(flash)

## Al vender: deja una copia visual que se encoge soltando chispas; la torreta real se libera ya.
func play_sell() -> void:
	var ghost := Node2D.new()
	ghost.global_position = global_position
	ghost.z_index = z_index
	for node: AnimatedSprite2D in [sprite, cannon]:
		var copy: AnimatedSprite2D = node.duplicate()
		copy.pause()
		ghost.add_child(copy)
	var sparks := CPUParticles2D.new()
	sparks.emitting = true
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 10
	sparks.lifetime = SELL_TIME * 2.0
	sparks.spread = 180.0
	# Sin gravedad: las chispas salen en todas direcciones y frenan, como un estallido.
	sparks.gravity = Vector2.ZERO
	sparks.damping_min = 40.0
	sparks.damping_max = 40.0
	sparks.initial_velocity_min = 30.0
	sparks.initial_velocity_max = 70.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 2.0
	sparks.color = SELL_SPARK_COLOR
	ghost.add_child(sparks)
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "scale", Vector2.ZERO, SELL_TIME).set_ease(Tween.EASE_IN)
	tween.tween_interval(SELL_TIME)
	tween.tween_callback(ghost.queue_free)
