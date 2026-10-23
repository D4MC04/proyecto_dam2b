extends Node2D

# Batalla lejana de fondo: cada pocos segundos cruza un grupo de naves enemigas en formación
# por las franjas de arriba o abajo (lejos de los botones) y de vez en cuando les llegan
# disparos desde fuera de la pantalla; algunas explotan.

# Cada nave con el giro extra (grados) que usa su EnemyData; null = no se gira, usa la animación left/right
const SHIPS: Array[Array] = [
	[preload("res://resources/sprite_frames/nave_normal.tres"), 180.0],
	[preload("res://resources/sprite_frames/nave_agresiva.tres"), 180.0],
	[preload("res://resources/sprite_frames/wasp.tres"), 0.0],
]
const IMPACT_FRAMES: SpriteFrames = preload("res://resources/sprite_frames/laser_impact.tres")
const SHIP_SCALE: float = 0.5
# Las naves y sus impactos van oscurecidos, como lejanos, pero opacos: no transparentan lo que tengan detrás
const SHIP_TINT: Color = Color(0.62, 0.66, 0.74)
const MARGIN: float = 40.0
const SHIP_SPEED: float = 60.0
const SHOT_SPEED: float = 320.0
const SHOT_LENGTH: float = 12.0
const SHOT_COLOR: Color = Color(0.25, 0.88, 0.94)
const KILL_CHANCE: float = 0.4
# Franjas verticales (fracción de la altura) por las que pasan; el centro queda libre para los botones
const LANES: Array[Vector2] = [Vector2(0.05, 0.2), Vector2(0.8, 0.95)]

# Si está, los disparos salen de sus torretas; si no, de fuera de la pantalla
@export var outpost: Outpost

var viewport_size: Vector2
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var ships: Array[AnimatedSprite2D] = []
var shots: Array[Line2D] = []
var shot_targets: Array[AnimatedSprite2D] = []
var group_wait: float = 0.0
var shot_wait: float = 0.0
var velocity: Vector2

func _ready() -> void:
	viewport_size = get_viewport_rect().size
	rng.randomize()
	group_wait = rng.randf_range(2.0, 5.0)
	shot_wait = rng.randf_range(4.0, 7.0)

func _process(delta: float) -> void:
	group_wait -= delta
	if group_wait <= 0.0:
		_spawn_group()
		group_wait = rng.randf_range(6.0, 12.0)
	shot_wait -= delta
	if shot_wait <= 0.0 and not ships.is_empty():
		_fire()
		shot_wait = rng.randf_range(1.5, 4.0)
	_move_ships(delta)
	_move_shots(delta)

func _spawn_group() -> void:
	var lane: Vector2 = LANES[rng.randi() % LANES.size()]
	var y: float = viewport_size.y * rng.randf_range(lane.x, lane.y)
	var going_right: bool = rng.randf() < 0.5
	var dir: Vector2 = Vector2.RIGHT if going_right else Vector2.LEFT
	var kind: Array = SHIPS[rng.randi() % SHIPS.size()]
	var frames: SpriteFrames = kind[0]
	var count: int = rng.randi_range(2, 4)
	var start_x: float = -MARGIN if going_right else viewport_size.x + MARGIN
	for i in count:
		var ship: AnimatedSprite2D = AnimatedSprite2D.new()
		ship.sprite_frames = frames
		ship.scale = Vector2(SHIP_SCALE, SHIP_SCALE)
		ship.modulate = SHIP_TINT
		# Formación en V hacia atrás: cada nave queda más atrás y alternando a un lado
		var rank: int = (i + 1) / 2
		var side: float = 1.0 if i % 2 == 1 else -1.0
		ship.position = Vector2(start_x - dir.x * rank * 28.0, y + side * rank * 18.0)
		ship.set_meta("dir", dir)
		add_child(ship)
		ship.play("right" if going_right else "left")
		if kind[1] != null:
			# El sprite base mira hacia arriba (como Enemy._update_animation)
			ship.rotation = snappedf(dir.angle() + PI / 2.0, PI / 2.0) + deg_to_rad(kind[1])
		ships.append(ship)

func _move_ships(delta: float) -> void:
	for i in range(ships.size() - 1, -1, -1):
		var ship: AnimatedSprite2D = ships[i]
		var dir: Vector2 = ship.get_meta("dir")
		ship.position += dir * SHIP_SPEED * delta
		if ship.position.x < -MARGIN * 3.0 or ship.position.x > viewport_size.x + MARGIN * 3.0:
			_remove_ship(ship)

func _remove_ship(ship: AnimatedSprite2D) -> void:
	ships.erase(ship)
	# Los disparos en vuelo contra ella se quedan sin objetivo
	for i in shot_targets.size():
		if shot_targets[i] == ship:
			shot_targets[i] = null
	ship.queue_free()

func _fire() -> void:
	# Solo contra naves ya visibles en pantalla
	var visible_ships: Array[AnimatedSprite2D] = ships.filter(
		func(s: AnimatedSprite2D) -> bool: return s.position.x > 0.0 and s.position.x < viewport_size.x)
	if visible_ships.is_empty():
		return
	var target: AnimatedSprite2D = visible_ships[rng.randi() % visible_ships.size()]
	# Sale de fuera de la pantalla por arriba o por abajo, apuntando a donde estará la nave
	var from_top: bool = target.position.y < viewport_size.y * 0.5
	var origin: Vector2 = Vector2(target.position.x + rng.randf_range(-150.0, 150.0),
			-MARGIN if from_top else viewport_size.y + MARGIN)
	if outpost != null:
		origin = to_local(outpost.global_position)
	var aim: Vector2 = target.position
	for _i in 2:
		aim = target.position + (target.get_meta("dir") as Vector2) * SHIP_SPEED * (origin.distance_to(aim) / SHOT_SPEED)
	if outpost != null:
		origin = to_local(outpost.fire_at(to_global(aim)))
	var shot: Line2D = Line2D.new()
	shot.width = 1.0
	shot.default_color = SHOT_COLOR
	shot.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, -SHOT_LENGTH)])
	shot.position = origin
	shot.rotation = (aim - origin).angle() + PI / 2.0
	shot.set_meta("aim", aim)
	add_child(shot)
	shots.append(shot)
	shot_targets.append(target)

func _move_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot: Line2D = shots[i]
		var aim: Vector2 = shot.get_meta("aim")
		var step: float = SHOT_SPEED * delta
		if shot.position.distance_to(aim) > step:
			shot.position += (aim - shot.position).normalized() * step
			continue
		var target: AnimatedSprite2D = shot_targets[i]
		_explode(aim)
		if target != null and rng.randf() < KILL_CHANCE:
			_remove_ship(target)
		shot.queue_free()
		shots.remove_at(i)
		shot_targets.remove_at(i)

func _explode(at: Vector2) -> void:
	var fx: AnimatedSprite2D = AnimatedSprite2D.new()
	fx.sprite_frames = IMPACT_FRAMES
	fx.position = at
	fx.modulate = SHIP_TINT
	add_child(fx)
	fx.animation_finished.connect(fx.queue_free)
	fx.play()
