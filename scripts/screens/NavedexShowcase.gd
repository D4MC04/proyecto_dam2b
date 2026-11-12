class_name NavedexShowcase
extends Control
## Vitrina de la Navedex: una escena en vivo de cómo es lo elegido en partida, con sus sprites del juego.
## Torretas: la torreta gira hacia una nave de prueba que pasa y le dispara con su efecto (balas, onda,
## rayo encadenado, haz, orbes); el amplificador emite ondas y la excavadora suelta dinero.
## Naves: la nave cruza la vitrina con su animación y enseña su habilidad (curar, camuflarse, dividirse,
## pulso EMP). Las naves no vistas salen como silueta negra, sin habilidad.

# Aumento de los sprites y medidas del mundo de la vitrina (en píxeles del juego, antes del aumento).
const ZOOM: int = 2
const TARGET_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/dart_verde.tres")
# La torreta va a esta distancia del borde izquierdo, centrada en alto.
const TURRET_X: float = 36.0
# Nave de prueba para las torretas: sube por la derecha, con un vaivén, una vez cada TARGET_TIME.
const TARGET_X: float = 118.0
const TARGET_SWAY: float = 14.0
const TARGET_TIME: float = 2.6
# Disparo: tiempo entre disparos (el de la torreta, entre estos topes) y velocidad de las balas.
const MIN_COOLDOWN: float = 0.3
const MAX_COOLDOWN: float = 1.2
const BULLET_SPEED: float = 150.0
const EFFECT_TIME: float = 0.18
const RING_TIME: float = 0.6
const ORBIT_RADIUS: float = 18.0
# Naves: una pasada de izquierda a derecha cada FLY_TIME, con un vaivén vertical.
const FLY_TIME: float = 4.0
const FLY_SWAY: float = 6.0
const ABILITY_TIME: float = 1.2
const COMPANION_GAP: float = 26.0
const GRID_STEP: int = 8
const HEAL_COLOR: Color = Color("#7ee89a")
const MONEY_COLOR: Color = Color("#ffe082")

var _data: InspectableData
var _known: bool = true
var _time: float = 0.0
var _cooldown: float = 0.0
var _turret_at: Vector2
var _world: Node2D
var _effects: Node2D
var _turret_base: AnimatedSprite2D
var _cannon: AnimatedSprite2D
var _ship: AnimatedSprite2D
var _companion: AnimatedSprite2D
var _splits: Array[AnimatedSprite2D] = []
# Efectos en curso: {kind, from, to, t, ...}; las balas llevan su sprite.
var _shots: Array[Dictionary] = []

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world = Node2D.new()
	_world.scale = Vector2(ZOOM, ZOOM)
	add_child(_world)
	_effects = Node2D.new()
	_effects.z_index = 1
	_effects.draw.connect(_draw_effects)
	_world.add_child(_effects)
	resized.connect(_place_world)

## Enseña la escena de `data`; `known` en falso la deja en silueta y sin habilidad.
func show_data(data: InspectableData, known: bool) -> void:
	_data = data
	_known = known
	_time = 0.0
	_cooldown = 0.0
	for shot: Dictionary in _shots:
		if shot.has("sprite"):
			(shot.sprite as Node).queue_free()
	_shots.clear()
	for node: Node in _world.get_children():
		if node != _effects:
			node.queue_free()
	_turret_base = null
	_cannon = null
	_ship = null
	_companion = null
	_splits.clear()
	var turret: TurretData = data as TurretData
	if turret != null:
		_turret_base = _sprite(turret.sprite_frames, &"default")
		if turret.cannon != null:
			_cannon = AnimatedSprite2D.new()
			_cannon.sprite_frames = turret.cannon
			_turret_base.add_child(_cannon)
			_cannon.play(&"default")
			_cannon.animation_finished.connect(_cannon.play.bind(&"default"))
		if _attacks():
			_ship = _sprite(TARGET_FRAMES, &"up")
	else:
		var enemy: EnemyData = data as EnemyData
		_ship = _sprite(enemy.sprite_frames, &"right")
		if enemy.rotate_sprite:
			_ship.rotation = PI / 2.0 + deg_to_rad(enemy.rotation_offset)
		if not known:
			_ship.modulate = Color.BLACK
		elif enemy.heal_aura:
			_companion = _sprite(TARGET_FRAMES, &"right")
	_place_world()

# El mundo centrado en la vitrina y la torreta en su sitio (la vitrina crece con el hueco que sobra).
func _place_world() -> void:
	_world.position = ((size - Vector2(_world_size()) * ZOOM) / 2.0).round()
	_turret_at = Vector2(TURRET_X, roundf(_world_size().y / 2.0))
	if _turret_base != null:
		_turret_base.position = _turret_at

func _world_size() -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(int(size.x) / ZOOM, int(size.y) / ZOOM)

func _sprite(frames: SpriteFrames, animation: StringName) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	_world.add_child(sprite)
	_world.move_child(_effects, -1)
	if frames.has_animation(animation):
		sprite.play(animation)
	else:
		sprite.play()
	return sprite

# Torretas que disparan a una nave (el amplificador y la excavadora no).
func _attacks() -> bool:
	var turret: TurretData = _data as TurretData
	return turret.money_amount == 0 and (turret.bullet_data != null or turret.pulse != null or turret.chain != null
			or turret.beam != null or turret.focus_beam != null or turret.orbit != null)

func _process(delta: float) -> void:
	if _data == null or not is_visible_in_tree():
		return
	_time += delta
	if _data is TurretData:
		_update_turret(delta)
	else:
		_update_ship()
	_update_shots(delta)
	_effects.queue_redraw()
	queue_redraw()

# --- Torretas -----------------------------------------------------------------------------

func _update_turret(delta: float) -> void:
	var turret: TurretData = _data as TurretData
	var world: Vector2i = _world_size()
	if _ship != null:
		var loop: float = fmod(_time, TARGET_TIME) / TARGET_TIME
		_ship.position = Vector2(TARGET_X + sin(_time * 2.0) * TARGET_SWAY, lerpf(world.y + 12.0, -12.0, loop))
		if _cannon != null:
			# Los cañones miran hacia arriba, como en Turret._target_angle.
			_cannon.rotation = (_ship.position - _turret_at).angle() + PI / 2.0
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = clampf(turret.attack_cooldown, MIN_COOLDOWN, MAX_COOLDOWN)
	if turret.money_amount > 0:
		_shots.append({"kind": "money", "from": _turret_at + Vector2(0, -12), "t": 0.0, "text": "+%d" % turret.money_amount})
		return
	if _ship == null:
		_shots.append({"kind": "ring", "from": _turret_at, "t": 0.0, "radius": 40.0, "color": OfficePaint.CYAN_LIGHT})
		return
	if _ship.position.y < 0.0 or _ship.position.y > world.y:
		return
	_animate_cannon()
	var muzzle: Vector2 = _turret_at + (turret.muzzle_offset.rotated(_cannon.rotation) if _cannon != null else Vector2.ZERO)
	var target: Vector2 = _ship.position
	if turret.bullet_data != null and turret.bullet_data.sprite_frames != null:
		var bullet: AnimatedSprite2D = _sprite(turret.bullet_data.sprite_frames, &"default")
		bullet.position = muzzle
		bullet.rotation = (target - muzzle).angle() + PI / 2.0 + deg_to_rad(turret.bullet_data.rotation_offset)
		if turret.bullet_data.sprite_scale > 0.0:
			bullet.scale = Vector2.ONE * turret.bullet_data.sprite_scale
		_shots.append({"kind": "bullet", "sprite": bullet, "to": target, "impact": turret.bullet_data.impact_frames, "t": 0.0})
	elif turret.pulse != null:
		_shots.append({"kind": "ring", "from": _turret_at, "t": 0.0, "radius": 50.0, "color": OfficePaint.CYAN_LIGHT})
	elif turret.chain != null:
		_shots.append({"kind": "chain", "from": muzzle, "to": target, "t": 0.0, "seed": randi()})
	elif turret.beam != null:
		_shots.append({"kind": "beam", "from": muzzle, "to": muzzle + (target - muzzle).normalized() * 200.0, "t": 0.0,
				"color": OfficePaint.CYAN_LIGHT})
	elif turret.focus_beam != null:
		_shots.append({"kind": "beam", "from": muzzle, "to": target, "t": 0.0, "color": turret.focus_beam.tint})

# El cañón anima el disparo como en Outpost.fire_at.
func _animate_cannon() -> void:
	if _cannon == null:
		return
	if _cannon.sprite_frames.has_animation(&"fire_0"):
		_cannon.play(&"fire_0")
	elif _cannon.sprite_frames.has_animation(&"spin"):
		_cannon.play(&"spin")

# --- Naves --------------------------------------------------------------------------------

func _update_ship() -> void:
	var enemy: EnemyData = _data as EnemyData
	var world: Vector2i = _world_size()
	var loop: float = fmod(_time, FLY_TIME) / FLY_TIME
	if loop < 0.02 and not _splits.is_empty():
		for split: AnimatedSprite2D in _splits:
			split.queue_free()
		_splits.clear()
		_ship.show()
	var x: float = lerpf(-20.0, world.x + 20.0, loop)
	var y: float = world.y / 2.0 + sin(_time * 1.5) * FLY_SWAY
	_ship.position = Vector2(x, y)
	if _companion != null:
		_companion.position = Vector2(x + COMPANION_GAP, y - 4.0)
	if not _known:
		return
	var ability_now: bool = fmod(_time, ABILITY_TIME) < get_process_delta_time()
	if enemy.heal_aura and ability_now:
		_shots.append({"kind": "ring", "from": _ship.position, "t": 0.0, "radius": 22.0, "color": HEAL_COLOR})
		_shots.append({"kind": "money", "from": _companion.position + Vector2(0, -8), "t": 0.0, "text": "+", "color": HEAL_COLOR})
	if enemy.emp_interval > 0.0 and ability_now:
		_shots.append({"kind": "ring", "from": _ship.position, "t": 0.0, "radius": 30.0, "color": OfficePaint.CYAN})
	if enemy.cloak_interval > 0.0:
		# Camuflada en la mitad de la pasada.
		_ship.modulate.a = 0.25 if loop > 0.35 and loop < 0.65 else 1.0
	if not enemy.split_into.is_empty() and loop > 0.55 and _splits.is_empty():
		_ship.hide()
		_shots.append({"kind": "ring", "from": _ship.position, "t": 0.0, "radius": 16.0, "color": OfficePaint.CYAN_LIGHT})
		for i: int in enemy.split_into.size():
			var split: AnimatedSprite2D = _sprite(enemy.split_into[i].sprite_frames, &"right")
			split.position = _ship.position
			split.set_meta(&"spread", (i - (enemy.split_into.size() - 1) / 2.0) * 12.0)
			_splits.append(split)
	for split: AnimatedSprite2D in _splits:
		split.position = Vector2(x, y + split.get_meta(&"spread") * clampf((loop - 0.55) * 6.0, 0.0, 1.0))

# --- Efectos ------------------------------------------------------------------------------

func _update_shots(delta: float) -> void:
	for shot: Dictionary in _shots.duplicate():
		shot.t += delta
		if shot.kind == "bullet":
			var sprite: AnimatedSprite2D = shot.sprite
			var to: Vector2 = shot.to
			sprite.position = sprite.position.move_toward(to, BULLET_SPEED * delta)
			if sprite.position.is_equal_approx(to):
				sprite.queue_free()
				_shots.erase(shot)
				_impact(to, shot.impact)
		elif shot.t > (RING_TIME if shot.kind in ["ring", "money"] else EFFECT_TIME):
			_shots.erase(shot)

# Explosión de impacto (la de la bala si la tiene) que se borra al acabar.
func _impact(at: Vector2, frames: SpriteFrames) -> void:
	if frames == null:
		_shots.append({"kind": "ring", "from": at, "t": 0.0, "radius": 6.0, "color": OfficePaint.AMBER_LIGHT})
		return
	var boom: AnimatedSprite2D = _sprite(frames, &"default")
	boom.position = at
	boom.sprite_frames = frames.duplicate()
	boom.sprite_frames.set_animation_loop(boom.animation, false)
	boom.play(boom.animation)
	boom.animation_finished.connect(boom.queue_free)

func _draw_effects() -> void:
	var turret: TurretData = _data as TurretData
	if turret != null and turret.orbit != null:
		for i: int in turret.orbit.max_orbs:
			var angle: float = _time * deg_to_rad(turret.orbit.orbit_speed) + TAU * i / turret.orbit.max_orbs
			_effects.draw_circle(_turret_at + Vector2.from_angle(angle) * ORBIT_RADIUS, 2.0, OfficePaint.CYAN_LIGHT, true, -1.0, false)
	for shot: Dictionary in _shots:
		var fade: float = 1.0 - shot.t / (RING_TIME if shot.kind in ["ring", "money"] else EFFECT_TIME)
		match shot.kind:
			"ring":
				var color: Color = shot.color
				_effects.draw_arc(shot.from, maxf(1.0, shot.radius * (1.0 - fade)), 0.0, TAU, 24, Color(color, fade), 1.0, false)
			"beam":
				var color: Color = shot.color
				_effects.draw_line(shot.from, shot.to, Color(color, fade), 2.0, false)
			"chain":
				_draw_bolt(shot.from, shot.to, shot.seed, fade)
			"money":
				var color: Color = shot.get("color", MONEY_COLOR)
				var at: Vector2 = shot.from + Vector2(0, -14.0 * (1.0 - fade))
				_effects.draw_string(OfficePaint.FONT, at.round(), shot.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(color, fade))

# Rayo en zigzag (siempre igual para el mismo disparo).
func _draw_bolt(from: Vector2, to: Vector2, bolt_seed: int, fade: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = bolt_seed
	var points: PackedVector2Array = [from]
	var normal: Vector2 = (to - from).orthogonal().normalized()
	for k: int in range(1, 6):
		points.append(from.lerp(to, k / 6.0) + normal * rng.randf_range(-4.0, 4.0))
	points.append(to)
	_effects.draw_polyline(points, Color(OfficePaint.CYAN_LIGHT, fade), 1.0, false)

# Fondo de la vitrina: pantalla oscura con cuadrícula tenue y borde cian.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), OfficePaint.SCREEN_DARK)
	for x: int in range(GRID_STEP, int(size.x), GRID_STEP * ZOOM):
		draw_rect(Rect2(x, 0, 1, size.y), OfficePaint.SCREEN)
	for y: int in range(GRID_STEP, int(size.y), GRID_STEP * ZOOM):
		draw_rect(Rect2(0, y, size.x, 1), OfficePaint.SCREEN)
	OfficePaint.brackets(self, Rect2i(Vector2i(4, 4), Vector2i(size) - Vector2i(8, 8)), OfficePaint.CYAN_DARK)
	draw_rect(Rect2(Vector2.ZERO, size), OfficePaint.CYAN_DARK, false, 1.0)
