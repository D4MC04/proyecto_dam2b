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
const METEOR_RADIUS: float = 40.0
const METEOR_DAMAGE: float = 150.0
# Caída del meteorito: sale de este desplazamiento respecto al punto y tarda METEOR_FALL_TIME.
const METEOR_FALL_OFFSET: Vector2 = Vector2(-90, -150)
const METEOR_FALL_TIME: float = 0.3
# Chispas que quedan en la estela: una cada METEOR_SPARK_INTERVAL durante la caída.
const METEOR_SPARK_INTERVAL: float = 0.04
const METEOR_SHAKE_DAMAGE: int = 60
# La marca de quemado se apaga en este tiempo.
const METEOR_SCORCH_TIME: float = 3.0
const FREEZE_FACTOR: float = 0.3
const FREEZE_TIME: float = 4.0
# Onda de hielo: sale de la base y llega al borde del área en FREEZE_WAVE_TIME; la escarcha crece en FREEZE_GROW_TIME y se derrite en FREEZE_MELT_TIME.
const FREEZE_WAVE_TIME: float = 1.2
# Distancia (px) entre el frente de la onda y el último eco.
const FREEZE_WAVE_ECHO: float = 70.0
const FREEZE_GROW_TIME: float = 0.9
const FREEZE_MELT_TIME: float = 0.8
const FREEZE_TINT: Color = Color(0.45, 0.75, 1.0, 0.15)
# Copos: uno cada FREEZE_FLAKE_INTERVAL durante FREEZE_TIME; caen FREEZE_FLAKE_FALL px.
const FREEZE_FLAKE_INTERVAL: float = 0.04
const FREEZE_FLAKE_FALL: float = 140.0
# Ataque orbital: el rayo cae en el borde izquierdo (ORBITAL_FALL_TIME), barre la fila elegida hasta el
# borde derecho durante ORBITAL_TIME y se va hacia arriba en ORBITAL_EXIT_TIME.
const ORBITAL_TIME: float = 2.0
const ORBITAL_DPS: float = 400.0
const ORBITAL_HALF_WIDTH: float = 6.0
const ORBITAL_HALF_HEIGHT: float = 16.0
const ORBITAL_FALL_TIME: float = 0.15
const ORBITAL_EXIT_TIME: float = 0.08
const ORBITAL_SWEEP_END: float = ORBITAL_FALL_TIME + ORBITAL_TIME
const ORBITAL_END_TIME: float = ORBITAL_SWEEP_END + ORBITAL_EXIT_TIME
# Temblor del mapa mientras dura el rayo: se repite cada ORBITAL_SHAKE_INTERVAL con este "daño" (amplitud).
const ORBITAL_SHAKE_INTERVAL: float = 0.15
const ORBITAL_SHAKE_DAMAGE: int = 40
# Parte de ORBITAL_FALL_TIME que dura la carga (retícula arriba); en el resto el rayo cae hasta la fila.
const ORBITAL_CHARGE_PART: float = 0.6
# Altura del emisor (la retícula del satélite) respecto al borde de arriba del área de juego.
const ORBITAL_EMITTER_Y: float = 12.0
# Ramas que saltan del rayo en cada frame y chispas en el impacto (dos cada ORBITAL_SPARK_INTERVAL).
const ORBITAL_BRANCHES: int = 3
const ORBITAL_SPARK_INTERVAL: float = 0.03
# Estela quemada: un tramo (del ancho de su sprite) cada ORBITAL_SCORCH_STEP px, que se apaga en ORBITAL_SCORCH_TIME.
const ORBITAL_SCORCH_STEP: float = 8.0
const ORBITAL_SCORCH_TIME: float = 1.2
# Capas del rayo, de fuera a dentro.
const ORBITAL_HALO_COLOR: Color = Color(0.25, 0.88, 0.94, 0.25)
const ORBITAL_EDGE_COLOR: Color = Color("#1c7496")
const ORBITAL_BODY_COLOR: Color = Color("#40e0f0")
const ORBITAL_LIGHT_COLOR: Color = Color("#befaff")
const ORBITAL_CORE_COLOR: Color = Color("#f0faff")
const ORBITAL_BRANCH_GLOW_COLOR: Color = Color(0.25, 0.88, 0.94, 0.5)
const AIM_FILL_COLOR: Color = Color(1.0, 0.7, 0.24, 0.15)
const AIM_BORDER_COLOR: Color = Color("#ecb23c")

const METEOR_FALL_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/meteor_fall.tres")
const METEOR_SPARK_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/meteor_spark.tres")
const METEOR_EXPLOSION_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/meteor_explosion.tres")
const METEOR_WARNING_TEXTURE: Texture2D = preload("res://assets/sprites/effects/meteor/meteor_warning.png")
const METEOR_SCORCH_TEXTURE: Texture2D = preload("res://assets/sprites/effects/meteor/meteor_scorch.png")
const ORBITAL_CHARGE_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/orbital_charge.tres")
const ORBITAL_EMITTER_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/orbital_emitter.tres")
const ORBITAL_IMPACT_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/orbital_impact.tres")
const ORBITAL_SPARK_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/orbital_spark.tres")
const ORBITAL_FLASH_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/orbital_flash.tres")
const ORBITAL_SCORCH_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/effects/orbital/orbital_scorch_0.png"),
	preload("res://assets/sprites/effects/orbital/orbital_scorch_1.png"),
	preload("res://assets/sprites/effects/orbital/orbital_scorch_2.png"),
]
const EXPLOSION_SOUND: AudioStream = preload("res://assets/audio/effects/Turrets/Rocket/RocketExplosion.wav")
const FROST_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/cryo_frost.tres")
const FREEZE_CORNER_TEXTURE: Texture2D = preload("res://assets/sprites/effects/freeze/freeze_corner.png")
const FREEZE_FLAKE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/effects/freeze/freeze_flake_0.png"),
	preload("res://assets/sprites/effects/freeze/freeze_flake_1.png"),
	preload("res://assets/sprites/effects/freeze/freeze_flake_2.png"),
]

@export var state: LevelState

var _cooldown_left: Dictionary[Power, float] = {Power.METEOR: 0.0, Power.FREEZE: 0.0, Power.ORBITAL: 0.0}
# Poder que se está apuntando, o -1.
var _aimed_power: int = -1
var _orbital_row: float = 0.0
var _orbital_elapsed: float = ORBITAL_END_TIME
var _orbital_shake_left: float = 0.0
var _orbital_spark_left: float = 0.0
# x global del próximo tramo de estela quemada.
var _orbital_scorch_x: float = 0.0

func _ready() -> void:
	# Duerme hasta que se usa un poder.
	set_process(false)
	# Elegir torreta cancela el apuntado.
	state.selected_turret_changed.connect(func(data: TurretData) -> void:
		if data != null:
			cancel_aiming())

func _process(delta: float) -> void:
	for power: Power in _cooldown_left:
		_cooldown_left[power] = maxf(_cooldown_left[power] - delta, 0.0)
	if _orbital_elapsed < ORBITAL_END_TIME:
		var was_sweeping: bool = _orbital_elapsed < ORBITAL_SWEEP_END
		_orbital_elapsed += delta
		_orbital_shake_left -= delta
		if _orbital_shake_left <= 0.0:
			_orbital_shake_left = ORBITAL_SHAKE_INTERVAL
			(get_parent() as Level).shake_map(ORBITAL_SHAKE_DAMAGE)
		var beam: Vector2 = _beam_position()
		if was_sweeping and _orbital_elapsed >= ORBITAL_FALL_TIME:
			for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
				var offset: Vector2 = (enemy.global_position - beam).abs()
				if enemy.hp > 0 and offset.x <= ORBITAL_HALF_WIDTH and offset.y <= ORBITAL_HALF_HEIGHT:
					enemy.take_damage(ORBITAL_DPS * delta)
			_burn_row(beam, delta)
			if _orbital_elapsed >= ORBITAL_SWEEP_END:
				Effect.spawn(self, ORBITAL_FLASH_FRAMES, beam)
		queue_redraw()
	if _orbital_elapsed >= ORBITAL_END_TIME and _cooldown_left.values().all(func(left: float) -> bool: return left <= 0.0):
		set_process(false)

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
		# Apuntando no se coloca torreta: se suelta la seleccionada.
		state.selected_turret = null
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
	if _orbital_elapsed < ORBITAL_END_TIME:
		_draw_beam()
	if _aimed_power == Power.ORBITAL:
		var row: Vector2 = to_local(Vector2(Level.GAME_AREA_RECT.position.x, get_global_mouse_position().y)).round()
		var band: Rect2 = Rect2(row.x, row.y - ORBITAL_HALF_HEIGHT, Level.GAME_AREA_RECT.size.x, ORBITAL_HALF_HEIGHT * 2.0)
		draw_rect(band, AIM_FILL_COLOR, true)
		# Solo las líneas de arriba y abajo: la franja cruza el área de punta a punta.
		draw_rect(Rect2(band.position, Vector2(band.size.x, 1.0)), AIM_BORDER_COLOR)
		draw_rect(Rect2(band.position.x, band.end.y - 1.0, band.size.x, 1.0), AIM_BORDER_COLOR)
		return
	if _aimed_power != Power.METEOR:
		return
	var center: Vector2 = get_local_mouse_position().round()
	draw_circle(center, METEOR_RADIUS, AIM_FILL_COLOR, true, -1.0, false)
	draw_circle(center, METEOR_RADIUS, AIM_BORDER_COLOR, false, 1.0, false)

func _drop_meteor(target: Vector2) -> void:
	cancel_aiming()
	_cooldown_left[Power.METEOR] = COOLDOWNS[Power.METEOR]
	set_process(true)
	power_used.emit(Power.METEOR)
	# Marca en el suelo: se cierra hasta el radio del área mientras cae la roca.
	var warning: Sprite2D = Sprite2D.new()
	warning.texture = METEOR_WARNING_TEXTURE
	add_child(warning)
	warning.global_position = target
	warning.scale = Vector2.ONE * 1.4
	warning.modulate.a = 0.4
	var start: Vector2 = target + METEOR_FALL_OFFSET
	var meteor: AnimatedSprite2D = AnimatedSprite2D.new()
	meteor.sprite_frames = METEOR_FALL_FRAMES
	add_child(meteor)
	meteor.global_position = start
	# La cabeza mira a +x: se gira hacia donde cae.
	meteor.rotation = (-METEOR_FALL_OFFSET).angle()
	meteor.play()
	var tween: Tween = meteor.create_tween()
	tween.tween_property(meteor, "global_position", target, METEOR_FALL_TIME)
	tween.parallel().tween_property(warning, "scale", Vector2.ONE, METEOR_FALL_TIME)
	tween.parallel().tween_property(warning, "modulate:a", 1.0, METEOR_FALL_TIME)
	# Chispas que se quedan atrás, en la trayectoria.
	var sparks: int = int(METEOR_FALL_TIME / METEOR_SPARK_INTERVAL)
	for i: int in sparks:
		var spot: Vector2 = start.lerp(target, float(i) / sparks) + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		tween.parallel().tween_callback(Effect.spawn.bind(self, METEOR_SPARK_FRAMES, spot)).set_delay(i * METEOR_SPARK_INTERVAL)
	tween.tween_callback(func() -> void:
		meteor.queue_free()
		warning.queue_free()
		_explode(target))

func _explode(target: Vector2) -> void:
	Effect.spawn(self, METEOR_EXPLOSION_FRAMES, target)
	var level: Level = get_parent() as Level
	level.shake_map(METEOR_SHAKE_DAMAGE)
	# Marca de quemado: va en el mapa (tiembla con él, queda bajo las naves) y se apaga sola.
	var scorch: Sprite2D = Sprite2D.new()
	scorch.texture = METEOR_SCORCH_TEXTURE
	level.map.add_child(scorch)
	scorch.global_position = target
	var fade: Tween = scorch.create_tween()
	fade.tween_property(scorch, "modulate:a", 0.0, METEOR_SCORCH_TIME)
	fade.tween_callback(scorch.queue_free)
	var player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
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
	set_process(true)
	power_used.emit(Power.FREEZE)
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.hp > 0:
			enemy.slow(FREEZE_FACTOR, FREEZE_TIME, FROST_FRAMES)
	_freeze_effects()

# Congelar: tinte azul que se desvanece, onda de hielo que sale de la base, escarcha en las esquinas
# (crece, aguanta FREEZE_TIME y se derrite) y copos que caen mientras dura.
func _freeze_effects() -> void:
	var rect: Rect2 = Level.GAME_AREA_RECT
	var root: Node2D = Node2D.new()
	add_child(root)
	root.global_position = Vector2.ZERO
	var tint: ColorRect = ColorRect.new()
	tint.color = FREEZE_TINT
	tint.position = rect.position
	tint.size = rect.size
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tint)
	# Onda de hielo: sale de la base y crece hasta cubrir el área; se recorta al área de juego.
	var clip: Control = Control.new()
	clip.position = rect.position
	clip.size = rect.size
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(clip)
	var wave: Node2D = Node2D.new()
	clip.add_child(wave)
	var base: Base = (get_parent() as Level).base
	var origin: Vector2 = (base.global_position if base else rect.get_center()) - rect.position
	var max_radius: float = maxf(origin.distance_to(Vector2.ZERO), maxf(origin.distance_to(Vector2(rect.size.x, 0.0)), maxf(origin.distance_to(Vector2(0.0, rect.size.y)), origin.distance_to(rect.size))))
	wave.draw.connect(_draw_freeze_wave.bind(wave, origin))
	wave.set_meta(&"radius", 0.0)
	var frost: Node2D = Node2D.new()
	root.add_child(frost)
	# Esquinas: la textura es la de arriba a la izquierda; el signo de la escala la voltea.
	var corners: Array[Array] = [
		[rect.position, Vector2(1, 1)],
		[Vector2(rect.end.x, rect.position.y), Vector2(-1, 1)],
		[Vector2(rect.position.x, rect.end.y), Vector2(1, -1)],
		[rect.end, Vector2(-1, -1)],
	]
	var grow: Tween = create_tween().set_parallel()
	for corner: Array in corners:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = FREEZE_CORNER_TEXTURE
		sprite.centered = false
		sprite.position = corner[0]
		sprite.scale = Vector2.ZERO
		frost.add_child(sprite)
		grow.tween_property(sprite, "scale", corner[1], FREEZE_GROW_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Secuencia general: ola, aguante y derretido. Los copos salen en paralelo.
	var life: Tween = root.create_tween().set_parallel()
	life.tween_method(func(radius: float) -> void:
		wave.set_meta(&"radius", radius)
		wave.queue_redraw(), 0.0, max_radius + FREEZE_WAVE_ECHO, FREEZE_WAVE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	life.tween_property(tint, "modulate:a", 0.0, FREEZE_WAVE_TIME + 0.5).from(1.0)
	life.tween_property(frost, "modulate:a", 0.0, FREEZE_MELT_TIME).set_delay(FREEZE_TIME)
	var flakes: int = int(FREEZE_TIME / FREEZE_FLAKE_INTERVAL)
	for i: int in flakes:
		life.tween_callback(_spawn_flake.bind(root)).set_delay(i * FREEZE_FLAKE_INTERVAL)
	# Espera a que los últimos copos acaben de caer.
	life.tween_callback(root.queue_free).set_delay(FREEZE_TIME + FREEZE_MELT_TIME + 2.0)

# Frente helado (anillo grueso con borde claro) y dos ecos detrás, más tenues; se apaga al irse lejos.
func _draw_freeze_wave(wave: Node2D, origin: Vector2) -> void:
	var radius: float = wave.get_meta(&"radius")
	var fade: float = clampf(1.0 - radius / 900.0, 0.2, 1.0)
	var rings: Array[Array] = [[0.0, 4.0, Color("#ecfaff"), 0.9], [4.0, 5.0, Color("#a6defa"), 0.7], [9.0, 4.0, Color("#54a0e2"), 0.5], [FREEZE_WAVE_ECHO * 0.5, 2.0, Color("#a6defa"), 0.35], [FREEZE_WAVE_ECHO, 2.0, Color("#54a0e2"), 0.25]]
	for ring: Array in rings:
		var r: float = radius - ring[0]
		if r > 0.0:
			var color: Color = ring[2]
			color.a = ring[3] * fade
			wave.draw_arc(origin, r, 0.0, TAU, 128, color, ring[1], false)

func _spawn_flake(root: Node2D) -> void:
	var rect: Rect2 = Level.GAME_AREA_RECT
	var flake: Sprite2D = Sprite2D.new()
	flake.texture = FREEZE_FLAKE_TEXTURES[randi() % FREEZE_FLAKE_TEXTURES.size()]
	root.add_child(flake)
	flake.global_position = Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y + randf_range(-10.0, rect.size.y * 0.9))
	var fall: float = randf_range(0.6, 1.0) * FREEZE_FLAKE_FALL
	var time: float = randf_range(1.0, 1.8)
	var tween: Tween = flake.create_tween().set_parallel()
	tween.tween_property(flake, "global_position", flake.global_position + Vector2(randf_range(-20.0, 20.0), fall), time)
	tween.tween_property(flake, "modulate:a", 0.0, time * 0.4).set_delay(time * 0.6)
	tween.chain().tween_callback(flake.queue_free)

func _fire_orbital(row_y: float) -> void:
	cancel_aiming()
	_cooldown_left[Power.ORBITAL] = COOLDOWNS[Power.ORBITAL]
	set_process(true)
	_orbital_row = row_y
	_orbital_elapsed = 0.0
	_orbital_spark_left = 0.0
	_orbital_scorch_x = Level.GAME_AREA_RECT.position.x
	power_used.emit(Power.ORBITAL)

# Posición global del rayo: quieto en el borde izquierdo mientras cae, recorre el ancho del área de juego en
# ORBITAL_TIME y se queda en el borde derecho mientras se va.
func _beam_position() -> Vector2:
	var rect: Rect2 = Level.GAME_AREA_RECT
	var sweep: float = clampf((_orbital_elapsed - ORBITAL_FALL_TIME) / ORBITAL_TIME, 0.0, 1.0)
	return Vector2(rect.position.x + rect.size.x * sweep, _orbital_row)

# Lo que deja el rayo al barrer la fila: tramos de estela quemada hasta donde ha llegado y chispas en el impacto.
func _burn_row(beam: Vector2, delta: float) -> void:
	var level: Level = get_parent() as Level
	while _orbital_scorch_x <= beam.x:
		# En el mapa, como la marca del meteorito: tiembla con él y queda bajo las naves.
		var scorch: Sprite2D = Sprite2D.new()
		scorch.texture = ORBITAL_SCORCH_TEXTURES.pick_random()
		level.map.add_child(scorch)
		scorch.global_position = Vector2(_orbital_scorch_x, _orbital_row).round()
		var fade: Tween = scorch.create_tween()
		fade.tween_property(scorch, "modulate:a", 0.0, ORBITAL_SCORCH_TIME)
		fade.tween_callback(scorch.queue_free)
		_orbital_scorch_x += ORBITAL_SCORCH_STEP
	_orbital_spark_left -= delta
	if _orbital_spark_left <= 0.0:
		_orbital_spark_left = ORBITAL_SPARK_INTERVAL
		for i: int in 2:
			Effect.spawn(self, ORBITAL_SPARK_FRAMES, beam + Vector2(randf_range(-14.0, 14.0), randf_range(-12.0, 2.0)))

# Rayo: primero la retícula de carga arriba; luego cae hasta la fila (y al final sube) en capas (halo, borde, cuerpo y núcleo
# que vibra) con pulsos que bajan, ramas que saltan a los lados, el emisor arriba y el impacto en el suelo.
# Todo en píxeles enteros y re-sorteado cada frame para que parpadee.
func _draw_beam() -> void:
	var beam: Vector2 = to_local(_beam_position()).round()
	var top: float = roundf(to_local(Vector2(0.0, Level.GAME_AREA_RECT.position.y + ORBITAL_EMITTER_Y)).y)
	var lens: Vector2 = Vector2(beam.x, top)
	var charge_time: float = ORBITAL_FALL_TIME * ORBITAL_CHARGE_PART
	if _orbital_elapsed < charge_time:
		_draw_frame(ORBITAL_CHARGE_FRAMES, int(_orbital_elapsed / charge_time * ORBITAL_CHARGE_FRAMES.get_frame_count(&"default")), lens)
		return
	var fall: float = minf((_orbital_elapsed - charge_time) / (ORBITAL_FALL_TIME - charge_time), 1.0)
	# Al acabar el barrido, la punta sube hasta el emisor.
	var leaving: float = clampf((_orbital_elapsed - ORBITAL_SWEEP_END) / ORBITAL_EXIT_TIME, 0.0, 1.0)
	var bottom: float = roundf(lerpf(top, beam.y, fall * (1.0 - leaving)))
	var height: float = bottom - top
	var x: float = beam.x
	var halo: float = 8.0 + randi_range(0, 1)
	draw_rect(Rect2(x - halo, top, halo * 2.0, height), ORBITAL_HALO_COLOR)
	draw_rect(Rect2(x - 5.0, top, 10.0, height), ORBITAL_EDGE_COLOR)
	draw_rect(Rect2(x - 4.0, top, 8.0, height), ORBITAL_BODY_COLOR)
	draw_rect(Rect2(x - 2.0, top, 4.0, height), ORBITAL_LIGHT_COLOR)
	var core: float = randi_range(1, 2)
	draw_rect(Rect2(x - core + randi_range(-1, 1), top, core * 2.0, height), ORBITAL_CORE_COLOR)
	# Pulsos de energía que bajan por el rayo.
	var phase: int = int(_orbital_elapsed * 300.0) % 16
	for y: int in range(int(top) + phase, int(bottom) - 3, 16):
		draw_rect(Rect2(x - 5.0, y, 10.0, 3.0), ORBITAL_LIGHT_COLOR)
	for i: int in ORBITAL_BRANCHES:
		# Más ramas cerca del suelo que arriba.
		var side: float = 1.0 if randf() < 0.5 else -1.0
		_draw_branch(Vector2(x + side * 4.0, roundf(lerpf(top, bottom, sqrt(randf())))), side)
	_draw_frame(ORBITAL_EMITTER_FRAMES, int(_orbital_elapsed * ORBITAL_EMITTER_FRAMES.get_animation_speed(&"default")), lens)
	if fall >= 1.0 and leaving == 0.0:
		# El óvalo del sprite de impacto está 4 px por debajo de su centro.
		_draw_frame(ORBITAL_IMPACT_FRAMES, int(_orbital_elapsed * ORBITAL_IMPACT_FRAMES.get_animation_speed(&"default")), Vector2(x, bottom - 4.0))

# Rama quebrada que sale del rayo hacia un lado (side: 1 derecha, -1 izquierda).
func _draw_branch(start: Vector2, side: float) -> void:
	var points: PackedVector2Array = PackedVector2Array([start])
	var point: Vector2 = start
	for k: int in randi_range(2, 4):
		point += Vector2(side * randi_range(3, 6), randi_range(-4, 4))
		points.append(point)
	draw_polyline(points, ORBITAL_BRANCH_GLOW_COLOR, 3.0, false)
	draw_polyline(points, ORBITAL_LIGHT_COLOR, 1.0, false)

# Dibuja un frame de la animación por defecto (en bucle) centrado en el punto, en píxeles enteros.
func _draw_frame(frames: SpriteFrames, index: int, center: Vector2) -> void:
	var texture: Texture2D = frames.get_frame_texture(&"default", index % frames.get_frame_count(&"default"))
	draw_texture(texture, (center - texture.get_size() / 2.0).round())
