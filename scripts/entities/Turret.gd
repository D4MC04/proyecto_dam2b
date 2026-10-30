class_name Turret
extends Node2D

## Ha cambiado el nivel de amplificación (ver set_amplification).
signal amplification_changed
## Se ha apagado por un EMP o ha vuelto; si es un Amplificador, Grid recalcula las auras.
signal power_changed

@export var data: TurretData
@export var bullet_scene: PackedScene

# Margen para disparar sin que el cañón esté perfectamente alineado.
const AIM_TOLERANCE := deg_to_rad(12.0)
# Cambia de sentido de giro solo si el otro tarda menos de esta fracción del tiempo del actual.
const TURN_SWITCH_RATIO := 0.7
# Color de la base y el cañón mientras un pulso EMP la tiene apagada: muy oscuro y azulado.
const DISABLED_TINT := Color(0.22, 0.25, 0.38)
# Destello al volver a encenderse.
const ENABLE_FLASH := Color(3, 3, 3)
const ENABLE_FLASH_TIME := 0.3
# Animación al construir o mejorar: la línea de escaneo tarda BUILD_TIME en subir por la torreta y
# BUILD_TRAIL filas de estela salen por arriba antes de acabar.
const BUILD_SHADER: Shader = preload("res://resources/shaders/hologram_build.gdshader")
const BUILD_TIME := 0.8
const BUILD_TRAIL := 5.0
# Al llegarle la onda de un Amplificador: escaneo ámbar ligero, más corto que el de construir.
const AMP_SCAN_SHADER: Shader = preload("res://resources/shaders/amp_scan.gdshader")
const AMP_SCAN_TIME := 0.45
const AMP_SCAN_TRAIL := 3.0
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
# Tubos rotativos (ver TurretData.spin_up_time): segundos en frenar del todo y tope de velocidad de
# la animación "spin" respecto a la de la cadencia base, para que a tope no pase de 60 frames/s.
const SPIN_DOWN_TIME := 0.6
const SPIN_MAX_SCALE := 5.0
# Minero: frame de "generate" en el que las pepitas caen en las tolvas y sale el dinero.
const MINE_PAYOUT_FRAME := 4

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
# Giro con turn_speed > 0: sentido elegido (+1, -1 o 0 sin elegir) para el objetivo _turn_target y
# velocidad angular (rad/s) de ese enemigo vista desde la torreta en el último cálculo.
var _turn_direction := 0
var _turn_target: Enemy = null
var _enemy_rate := 0.0
# Cooldown cumplido, a la espera de que el cañón termine de girar hacia el enemigo.
var _pending_shot := false
# Sobrecalentamiento (ver TurretData.overheat_shots): calor de 0 a 1, segundos que le quedan parada
# y si base y cañón llevan tinte de calor (para devolverles el blanco una sola vez al enfriarse).
var _heat := 0.0
var _overheat_left := 0.0
var _heat_tinted := false
var _heat_glow: HeatGlow
# Tubos rotativos: 0 parados, 1 girando lo bastante para disparar.
var _spin := 0.0
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
## Nivel del mejor Amplificador encendido cuya aura la alcanza (0 = ninguno); lo pone Grid.
var amp_level := 0
var _amp_scan: ShaderMaterial
var _amp_scan_tween: Tween
var _sparks: EmpSparks
# Minero: estado del nivel (oleada en curso y dinero) y si ya cumplió su intervalo y espera a acabar
# la vuelta de reposo del cañón para generar.
var _level_state: LevelState
var _mine_pending := false
# Órbita de los proyectiles (solo torretas de órbita, ver TurretData.orbit).
var _orbit: Orbit
# Ratón sobre la torreta: dibuja el alcance.
var _hovered := false
## Seleccionada en el mapa (ver LevelState.sellable_turret): dibuja un borde ámbar en su casilla.
var selected := false:
	set(value):
		selected = value
		_selection_border.visible = value
		_selection_border.queue_redraw()
# Borde de selección, por encima de los sprites.
var _selection_border := Node2D.new()

const HOVER_HALF_SIZE := 8.0
const SELECTION_COLOR := Color("ecb23c")
# Mitad del lado (px) de la rejilla donde se calcula el contorno; los sprites son de 32x32.
const SELECTION_GRID_HALF := 20
static var _image_cache: Dictionary = {}

func _ready() -> void:
	add_to_group(&"turrets")
	_selection_border.z_index = 1
	_selection_border.visible = selected
	_selection_border.draw.connect(_draw_selection_border)
	add_child(_selection_border)
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
	if data.is_amplifier():
		# Sin ataque: no apunta ni dispara. El emisor brilla en bucle y se pinta el borde del aura.
		set_process(false)
		attack_timer.stop()
		cannon.play()
		add_child(AmpAura.new())
		return
	if data.is_miner():
		_setup_miner()
		return
	attack_range_shape.shape = data.attack_range
	attack_timer.wait_time = data.attack_cooldown
	attack_timer.timeout.connect(_on_attack_timeout)
	attack_range_area.area_entered.connect(_on_area_entered)
	attack_range_area.area_exited.connect(_on_area_exited)
	attack_timer.start()
	if _has_spin():
		# Los tubos empiezan parados: la animación corre a la velocidad que marque _update_spin.
		cannon.speed_scale = 0.0
		cannon.play(&"spin")
	if data.focus_beam:
		# El haz continuo no dispara por cooldown: lo lleva su propio nodo.
		attack_timer.stop()
		add_child(FocusBeam.new())
	if data.orbit:
		_orbit = Orbit.new()
		add_child(_orbit)

# Con la opción "mostrar rango" activada, cada torreta dibuja su alcance bajo sus sprites.
# Con la opción apagada, solo la que tiene el ratón encima (esté seleccionada o no).
func _draw() -> void:
	if not (Settings.get_value(&"show_turret_range") or _hovered):
		return
	if data.is_amplifier():
		# El aura, en ámbar.
		AmpAura.draw_circle_aura(self, data.attack_range)
	elif attack_range_shape.shape:
		# La forma del detector, que crece con el efecto de alcance del Amplificador.
		BuildManager.draw_range_circle(self, attack_range_shape.shape, data.min_range)

# Contorno de 1 px alrededor de la silueta de la base y el cañón (en su frame y giro actuales), por
# fuera de los píxeles opacos y sin antialiasing.
func _draw_selection_border() -> void:
	var size := SELECTION_GRID_HALF * 2
	var opaque := PackedByteArray()
	opaque.resize(size * size)
	for node: AnimatedSprite2D in [sprite, cannon]:
		if node.sprite_frames == null or not node.sprite_frames.has_animation(node.animation):
			continue
		var texture := node.sprite_frames.get_frame_texture(node.animation, node.frame)
		if texture == null:
			continue
		var image := _opaque_image(texture)
		var texture_size := texture.get_size()
		for y in size:
			for x in size:
				var local := ((Vector2(x - SELECTION_GRID_HALF, y - SELECTION_GRID_HALF) + Vector2(0.5, 0.5) - node.position).rotated(-node.rotation)) / node.scale
				var texel := Vector2i((local + texture_size * 0.5 - node.offset).floor()) if node.centered else Vector2i((local - node.offset).floor())
				if texel.x >= 0 and texel.y >= 0 and texel.x < image.get_width() and texel.y < image.get_height() and image.get_pixelv(texel).a > 0.5:
					opaque[y * size + x] = 1
	for y in size:
		for x in size:
			if opaque[y * size + x] == 1:
				continue
			var touches := false
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var nx := x + step.x
				var ny := y + step.y
				if nx >= 0 and ny >= 0 and nx < size and ny < size and opaque[ny * size + nx] == 1:
					touches = true
					break
			if touches:
				_selection_border.draw_rect(Rect2(x - SELECTION_GRID_HALF, y - SELECTION_GRID_HALF, 1, 1), SELECTION_COLOR)

# Imagen de la textura, guardada para no pedirla a la GPU en cada redibujado.
static func _opaque_image(texture: Texture2D) -> Image:
	if not _image_cache.has(texture):
		_image_cache[texture] = texture.get_image()
	return _image_cache[texture]

# Con el ratón encima (casilla de 16 px) se ve el alcance aunque la opción esté apagada.
func _physics_process(_delta: float) -> void:
	if selected:
		# El cañón gira y cambia de frame: el contorno se recalcula.
		_selection_border.queue_redraw()
	var delta := (get_global_mouse_position() - global_position).abs()
	var hovered: bool = maxf(delta.x, delta.y) <= HOVER_HALF_SIZE
	if hovered != _hovered:
		_hovered = hovered
		queue_redraw()

func _process(delta: float) -> void:
	if disabled:
		return
	var target := _get_target()
	var overheated := data.overheat_shots > 0 and _update_overheat(delta, target != null)
	if _has_spin():
		_update_spin(delta, target != null and not overheated)
	if overheated:
		return
	if target == null:
		# El haz (continuo o de carga) lleva su propio corte y no debe apagar el disparo que acaba de salir.
		if not data.focus_beam and not data.beam:
			_stop_shoot_sound()
		return
	# Gira poco a poco hacia el lado con el que alcanza antes al enemigo; sin enemigo se queda donde está.
	if data.turn_speed > 0:
		_turn_toward(target, delta)
	else:
		cannon.rotation = _target_angle(target)
	if _pending_shot and _is_aimed(target) and _is_spun_up():
		_pending_shot = false
		attack_timer.start()
		_shoot(target)

func _has_spin() -> bool:
	return data.spin_up_time > 0.0

# Sin ataque: no apunta. El Timer solo corre con una oleada en curso y la torreta encendida; al cumplirse
# espera a que el cañón acabe su vuelta de reposo, reproduce "generate" y da el dinero en MINE_PAYOUT_FRAME.
func _setup_miner() -> void:
	set_process(false)
	_level_state = (get_parent() as BuildManager).state
	_level_state.wave_in_progress_changed.connect(_update_mine_timer.unbind(1))
	cannon.play()
	cannon.animation_looped.connect(_on_mine_idle_looped)
	cannon.frame_changed.connect(_on_mine_frame_changed)
	cannon.animation_finished.connect(cannon.play.bind(&"default"))
	attack_timer.wait_time = data.attack_cooldown
	attack_timer.timeout.connect(func() -> void: _mine_pending = true)
	attack_timer.start()
	_update_mine_timer()

func _update_mine_timer() -> void:
	attack_timer.paused = disabled or not _level_state.wave_in_progress

func _on_mine_idle_looped() -> void:
	if _mine_pending and not disabled and cannon.animation == &"default":
		_mine_pending = false
		cannon.play(&"generate")

func _on_mine_frame_changed() -> void:
	if cannon.animation == &"generate" and cannon.frame == MINE_PAYOUT_FRAME and not disabled:
		_level_state.add_money(data.money_amount)
		FloatingText.spawn(get_parent(), global_position, "+" + UiFormat.money(data.money_amount))

# Sin tubos rotativos siempre está lista; con ellos, cuando han terminado de arrancar.
func _is_spun_up() -> bool:
	return not _has_spin() or _spin >= 1.0

## Arranca los tubos (en spin_up_time s) mientras quiere disparar y los frena (en SPIN_DOWN_TIME s)
## si no. La animación "spin" va más rápida cuanto menor es el cooldown actual, así que acelera y
## frena con la cadencia.
func _update_spin(delta: float, wanted: bool) -> void:
	if wanted:
		_spin = move_toward(_spin, 1.0, delta / data.spin_up_time)
	else:
		_spin = move_toward(_spin, 0.0, delta / SPIN_DOWN_TIME)
	var cooldown := _heat_cooldown() if data.overheat_shots > 0 else data.attack_cooldown
	cannon.speed_scale = _spin * minf(data.attack_cooldown / cooldown, SPIN_MAX_SCALE)

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
	# Amplificada llega antes a la cadencia máxima.
	var full_speed_heat := FULL_SPEED_HEAT / amp_value(AmpEffect.Kind.HEAT, 1.0)
	var t := minf(_heat / full_speed_heat, 1.0)
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

# Gira el cañón un paso hacia el objetivo. Alineado sigue al enemigo por el camino corto; si no, elige
# el sentido con el que lo alcanza antes (ver _best_turn_direction) y lo mantiene mientras el objetivo
# sea el mismo, salvo que el otro sea claramente mejor.
func _turn_toward(target: Enemy, delta: float) -> void:
	var step := deg_to_rad(data.turn_speed) * delta
	var goal := _target_angle(target)
	if target != _turn_target or absf(angle_difference(cannon.rotation, goal)) <= AIM_TOLERANCE:
		_turn_target = target
		_turn_direction = 0
		cannon.rotation = rotate_toward(cannon.rotation, goal, step)
		return
	var distances := _turn_distances(goal)
	var times := _turn_times(target, goal)
	var current_time: float = times[_turn_direction] if _turn_direction != 0 else INF
	var best := _best_turn_direction(times)
	if _turn_direction == 0 or (best != _turn_direction and times[best] < current_time * TURN_SWITCH_RATIO):
		_turn_direction = best
	var remaining: float = distances[_turn_direction]
	if step >= remaining:
		cannon.rotation = goal
	else:
		cannon.rotation = wrapf(cannon.rotation + _turn_direction * step, -PI, PI)

# Ángulo a recorrer hasta `goal` girando en sentido positivo (+1) y negativo (-1).
func _turn_distances(goal: float) -> Dictionary:
	var positive := fposmod(angle_difference(cannon.rotation, goal), TAU)
	return {1: positive, -1: TAU - positive}

# Tiempo hasta alcanzar al enemigo girando en cada sentido (INF si en ese sentido no lo alcanza nunca).
# Su velocidad angular alrededor de la torreta es la componente perpendicular de su velocidad entre la distancia.
func _turn_times(target: Enemy, goal: float) -> Dictionary:
	var offset := target.global_position - global_position
	var enemy_rate := 0.0
	if offset.length_squared() > 0.0:
		enemy_rate = offset.cross(target.get_move_velocity()) / offset.length_squared()
	var turn_rate := deg_to_rad(data.turn_speed)
	var distances := _turn_distances(goal)
	var times := {1: INF, -1: INF}
	# El enemigo se aleja o se acerca al cañón según su propia velocidad angular.
	if turn_rate - enemy_rate > 0.0:
		times[1] = distances[1] / (turn_rate - enemy_rate)
	if turn_rate + enemy_rate > 0.0:
		times[-1] = distances[-1] / (turn_rate + enemy_rate)
	_enemy_rate = enemy_rate
	return times

# Sentido con menor tiempo; si ninguno lo alcanza, hacia donde va el enemigo.
func _best_turn_direction(times: Dictionary) -> int:
	if is_inf(times[1]) and is_inf(times[-1]):
		return 1 if _enemy_rate >= 0.0 else -1
	return 1 if times[1] <= times[-1] else -1

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
	if data.orbit:
		# No apunta: genera un proyectil en cada cooldown mientras quepa en la órbita.
		if not _orbit.is_full():
			_start_charge()
			cannon.play(&"fire_0")
		return
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
	if _is_aimed(target) and _is_spun_up():
		_shoot(target)
	else:
		# El cooldown no se gasta: dispara en cuanto el cañón quede alineado (y los tubos girando).
		_pending_shot = true
		attack_timer.stop()

# Torretas de onda, de rayo o de órbita: el cañón no gira ni dispara balas.
func _is_static() -> bool:
	return data.pulse != null or data.chain != null or data.orbit != null

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
		# La carga amplificada va más rápida; el disparo y la recuperación, a su velocidad.
		cannon.speed_scale = 1.0
		_play_shoot()
		Beam.spawn(self)
	elif data.orbit and cannon.frame == data.orbit.fire_frame:
		_play_shoot()
		_orbit.spawn_orb()

# Frame de fire_0 en el que sale el ataque de la torreta estática o de haz.
func _fire_frame() -> int:
	if data.beam:
		return data.beam.fire_frame
	if data.chain:
		return data.chain.fire_frame
	if data.pulse:
		return data.pulse.fire_frame
	if data.orbit:
		return data.orbit.fire_frame
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
		cannon.speed_scale = amp_value(AmpEffect.Kind.CHARGE, 1.0)
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
	# Las animaciones de disparo son las fire_N (los tubos rotativos no tienen: su "spin" no se corta).
	var fire_anims := 0
	if data.cannon:
		for animation: String in data.cannon.get_animation_names():
			if animation.begins_with("fire_"):
				fire_anims += 1
	if fire_anims > 0:
		cannon.play("fire_%d" % (_shots % fire_anims))
	_shots += 1
	if data.overheat_shots > 0:
		_add_heat()

# Mantiene el objetivo mientras siga vivo y dentro del rango.
func _get_target() -> Enemy:
	if not is_instance_valid(_target) or not enemies_in_range.has(_target) or _target.cloaked or _is_too_close(_target):
		_target = _best_enemy()
	return _target

func _best_enemy() -> Enemy:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	var best: Enemy = null
	var best_remaining: float = INF
	for enemy in enemies_in_range:
		# Las naves camufladas no se apuntan, ni las que están dentro del radio mínimo.
		if enemy.cloaked or _is_too_close(enemy):
			continue
		var remaining := enemy.get_remaining_distance()
		if remaining < best_remaining:
			best_remaining = remaining
			best = enemy
	return best

# Con rango en anillo (min_range > 0) no llega a lo que tiene más cerca que min_range.
func _is_too_close(enemy: Enemy) -> bool:
	return data.min_range > 0.0 and enemy.global_position.distance_to(global_position) < data.min_range

## La apaga `seconds` segundos: no apunta ni dispara, se oscurece y le saltan chispas.
## Si ya estaba apagada se renueva la duración, no se acumula.
func disable(seconds: float) -> void:
	disabled = true
	attack_timer.paused = true
	sprite.modulate = DISABLED_TINT
	cannon.modulate = DISABLED_TINT
	# Corta la carga o el disparo que estuviera a medias. Los tubos rotativos se paran en seco y al
	# volver tienen que arrancar otra vez.
	_spin = 0.0
	# El Minero pierde lo que fuera a sacar.
	_mine_pending = false
	if cannon.sprite_frames and cannon.animation != &"default" and not _has_spin():
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
	power_changed.emit()

func _enable() -> void:
	disabled = false
	attack_timer.paused = false
	if data.is_miner():
		# Entre oleadas sigue parado.
		_update_mine_timer()
	cannon.speed_scale = 1.0
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "modulate", Color.WHITE, ENABLE_FLASH_TIME).from(ENABLE_FLASH)
	tween.tween_property(cannon, "modulate", Color.WHITE, ENABLE_FLASH_TIME).from(ENABLE_FLASH)
	_sparks.queue_free()
	_sparks = null
	power_changed.emit()

## Valor del efecto `kind` de amplificación de esta torreta (ver AmpEffect), o `fallback` si no está
## amplificada o su efecto es otro.
func amp_value(kind: AmpEffect.Kind, fallback: float = 0.0) -> float:
	if amp_level == 0 or data.amp_effect == null or data.amp_effect.kind != kind:
		return fallback
	return data.amp_effect.get_value(amp_level)

## Lo llama Grid con el nivel del mejor Amplificador encendido de alrededor (0 = ninguno).
## Las torretas sin efecto (los propios Amplificadores) se quedan sin amplificar.
func set_amplification(level: int) -> void:
	if data.amp_effect == null:
		level = 0
	if level == amp_level:
		return
	amp_level = level
	_update_range()
	queue_redraw()
	amplification_changed.emit()

## Cuando le llega la onda de un Amplificador (ver AmpAura): una línea ámbar sube por la torreta con
## una estela corta y el contorno brilla y se apaga (resources/shaders/amp_scan.gdshader). No pisa la
## animación de construir.
func flash_amp() -> void:
	if sprite.material != null and sprite.material != _amp_scan:
		return
	if _amp_scan == null:
		_amp_scan = ShaderMaterial.new()
		_amp_scan.shader = AMP_SCAN_SHADER
		_amp_scan.set_shader_parameter("trail_length", AMP_SCAN_TRAIL)
	var half_height := _half_height()
	_amp_scan.set_shader_parameter("line_start", global_position.y + half_height)
	_amp_scan.set_shader_parameter("line_end", global_position.y - half_height - AMP_SCAN_TRAIL)
	_amp_scan.set_shader_parameter("progress", 0.0)
	sprite.material = _amp_scan
	cannon.material = _amp_scan
	if _amp_scan_tween:
		_amp_scan_tween.kill()
	_amp_scan_tween = create_tween()
	_amp_scan_tween.tween_method(func(value: float) -> void: _amp_scan.set_shader_parameter("progress", value), 0.0, 1.0, AMP_SCAN_TIME)
	_amp_scan_tween.tween_callback(func() -> void:
		sprite.material = null
		cannon.material = null)

# Con el efecto de alcance el detector usa un círculo propio más grande (el de data es compartido).
func _update_range() -> void:
	var circle := data.attack_range as CircleShape2D
	var bonus := amp_value(AmpEffect.Kind.RANGE)
	if circle == null or bonus <= 0.0:
		attack_range_shape.shape = data.attack_range
		return
	var amplified := CircleShape2D.new()
	amplified.radius = circle.radius * (1.0 + bonus)
	attack_range_shape.shape = amplified

## Apunta el daño que ha hecho un disparo suyo y si ha matado.
func register_damage(amount: float, killed: bool) -> void:
	damage_dealt += amount
	if killed:
		kills += 1

## Dinero que devuelve vender la torreta: la mitad de lo invertido, redondeada hacia abajo.
func get_sell_value() -> int:
	return floori(invested / 2.0)

## Se materializa: una línea de escaneo cian sube por la base y el cañón; lo de encima es holograma.
## Al acabar se quita el material y la torreta queda normal.
func play_build() -> void:
	# El escaneo de construir manda sobre el de la onda del Amplificador.
	if _amp_scan_tween:
		_amp_scan_tween.kill()
	var half_height := _half_height()
	var material := ShaderMaterial.new()
	material.shader = BUILD_SHADER
	material.set_shader_parameter("line_start", global_position.y + half_height)
	material.set_shader_parameter("line_end", global_position.y - half_height - BUILD_TRAIL)
	material.set_shader_parameter("trail_length", BUILD_TRAIL)
	material.set_shader_parameter("progress", 0.0)
	sprite.material = material
	cannon.material = material
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void: material.set_shader_parameter("progress", value), 0.0, 1.0, BUILD_TIME)
	tween.tween_callback(func() -> void:
		sprite.material = null
		cannon.material = null)

# Mitad de la altura del sprite (los frames son de 32x32, con la torreta centrada).
func _half_height() -> float:
	var half_height := 0.0
	for node: AnimatedSprite2D in [sprite, cannon]:
		if node.sprite_frames:
			var frame_texture := node.sprite_frames.get_frame_texture(node.animation, 0)
			half_height = maxf(half_height, frame_texture.get_height() * node.scale.y * 0.5)
	return half_height

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
