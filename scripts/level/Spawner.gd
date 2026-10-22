class_name Spawner
extends Node

signal enemy_died(reward: int)
signal enemy_reached_end(damage: int)
## Se emite al empezar cada oleada, con su índice (desde 0) y el total de oleadas.
signal wave_started(index: int, total: int)
## Se emite cuando la oleada `index` ha sacado su último enemigo; puede haber enemigos vivos.
signal wave_spawn_finished(index: int)
## Se emite cuando, tras la oleada `index`, no quedan entradas pendientes ni enemigos vivos.
signal wave_cleared(index: int)
## Se emite cuando se limpia la última oleada.
signal all_waves_cleared
## Se emite al cambiar `auto_waves`.
signal auto_waves_changed(enabled: bool)

const NODRIZA: EnemyData = preload("res://resources/enemy_data/nodriza.tres")
const ENEMY_SCENE: PackedScene = preload("res://scenes/entities/Enemy.tscn")
## Al partirse: segundos que se ve agrietada, separación en px entre trozos al salir (de lado,
## según su dibujo), cuánto más se alejan y en cuántos segundos vuelven al camino.
const CRACK_TIME := 0.15
const SPLIT_GAP := 11.0
const SPLIT_PUSH := 6.0
const SPLIT_PUSH_TIME := 0.12
const SPLIT_RETURN_TIME := 0.35
## Pausa entre que el nivel queda limpio y el arranque de la siguiente oleada con AUTO.
const AUTO_WAVE_DELAY := 1.5

## Con AUTO activo, la siguiente oleada empieza sola cuando el nivel queda limpio.
var auto_waves: bool = false:
	set(value):
		if auto_waves == value:
			return
		auto_waves = value
		if auto_waves:
			_try_schedule_auto_wave()
		else:
			_auto_countdown = -1.0
		auto_waves_changed.emit(auto_waves)

var paths: Array[Path2D]
var waves: Array[WaveData]
var _elapsed: float = 0.0
var _next_index: int = 0
var _wave_index: int = -1
var _entries: Array[SpawnEntry] = []
var _spawning: bool = false
# Enemigos vivos; cada uno se borra una sola vez, al morir o al llegar al final.
var _alive: Dictionary[Enemy, bool] = {}
# Naves muertas que aún tienen que soltar sus piezas (ver _split).
var _pending_splits: int = 0
# Segundos que faltan para que AUTO lance la siguiente oleada; negativo si no hay cuenta atrás.
var _auto_countdown: float = -1.0
# Los caminos empiezan 2 casillas fuera del mapa: el portal y la salida de las naves van
# 40 px más adelante, media casilla dentro del borde, para que se vean.
const PORTAL_OFFSET := 40.0

# Portales abiertos de la oleada actual, por índice de camino.
var _portals: Dictionary[int, Portal] = {}

func setup(p: Array[Path2D], w: Array[WaveData]) -> void:
	paths = p
	waves = w

## Lanza la siguiente oleada. Devuelve false si el nivel no está limpio o no quedan oleadas.
func start_next_wave() -> bool:
	if not can_start_next_wave():
		return false
	_auto_countdown = -1.0
	_wave_index += 1
	_entries = waves[_wave_index].entries.duplicate()
	_entries.sort_custom(func(a: SpawnEntry, b: SpawnEntry) -> bool: return a.time < b.time)
	_elapsed = 0.0
	_next_index = 0
	_spawning = true
	_open_portals()
	wave_started.emit(_wave_index, waves.size())
	return true

## La oleada `index` trae la Nodriza (el jefe).
func wave_has_boss(index: int) -> bool:
	return waves[index].entries.any(func(entry: SpawnEntry) -> bool: return entry.enemy_data == NODRIZA)

func can_start_next_wave() -> bool:
	return is_clear() and has_waves_left()

func has_waves_left() -> bool:
	return _wave_index + 1 < waves.size()

## Índice de la última oleada lanzada; -1 si aún no ha empezado ninguna.
func get_wave_index() -> int:
	return _wave_index

## La oleada actual aún tiene entradas pendientes.
func is_spawning() -> bool:
	return _spawning

## La última oleada lanzada ya sacó todos sus enemigos (o no se ha lanzado ninguna).
func has_finished_spawning() -> bool:
	return not _spawning

## No quedan entradas de ninguna oleada lanzada ni enemigos vivos.
func is_clear() -> bool:
	return not _spawning and _alive.is_empty() and _pending_splits == 0

func get_alive_count() -> int:
	return _alive.size()

func _process(delta: float) -> void:
	if _auto_countdown >= 0.0:
		_auto_countdown -= delta
		if _auto_countdown < 0.0:
			start_next_wave()
	if not _spawning:
		return
	_elapsed += delta
	while _next_index < _entries.size() and _entries[_next_index].time <= _elapsed:
		_spawn(_entries[_next_index])
		_next_index += 1
	if _next_index >= _entries.size():
		_spawning = false
		_close_portals()
		wave_spawn_finished.emit(_wave_index)
		_check_cleared()

func _spawn(entry: SpawnEntry) -> void:
	var index := entry.path_index % paths.size()
	_spawn_enemy(entry.enemy_data, paths[index], PORTAL_OFFSET).spawn_in()
	if _portals.has(index):
		_portals[index].flash_exit()

func _spawn_enemy(data: EnemyData, path: Path2D, progress: float) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	path.add_child(enemy)
	# El avance antes de setup(), para que su primer giro salga del camino y no de un salto.
	enemy.progress = progress
	enemy.setup(data, waves[_wave_index].health_multiplier)
	GameState.mark_enemy_seen(data)
	_alive[enemy] = true
	enemy.reached_end.connect(_on_enemy_reached_end.bind(enemy))
	enemy.died.connect(_on_enemy_died.bind(enemy))
	return enemy

# Abre un portal a la entrada de cada camino que use la oleada.
func _open_portals() -> void:
	for entry in _entries:
		var index := entry.path_index % paths.size()
		if _portals.has(index):
			continue
		var portal := Portal.new()
		var curve := paths[index].curve
		portal.position = curve.sample_baked(PORTAL_OFFSET)
		# La grieta (horizontal en Portal) queda atravesada al camino; girada en múltiplos de 90° para no deformar los píxeles.
		var direction := curve.sample_baked(PORTAL_OFFSET + 1.0) - portal.position
		# La Nodriza sale con un temblor más fuerte.
		if _entries.any(func(e: SpawnEntry) -> bool: return e.path_index % paths.size() == index and e.enemy_data == NODRIZA):
			portal.shake_strength = Portal.BOSS_SHAKE
		portal.rotation = snappedf(direction.angle() + PI / 2.0, PI / 2.0)
		paths[index].add_child(portal)
		_portals[index] = portal

func _close_portals() -> void:
	for portal in _portals.values():
		portal.close()
	_portals.clear()

func _on_enemy_died(reward: int, enemy: Enemy) -> void:
	if not _alive.erase(enemy):
		return
	# Si se parte, sus trozos salen tras la grieta; hasta entonces cuentan como pendientes
	# para que la oleada no se dé por limpia.
	if not enemy.data.split_into.is_empty():
		_pending_splits += 1
		_crack(enemy)
	enemy_died.emit(reward)
	_check_cleared()

# Deja en el sitio de la nave muerta su frame agrietado con un destello y luego la parte.
# Es un sprite suelto (sin área), así que se puede crear dentro de una señal de física.
func _crack(enemy: Enemy) -> void:
	var path := enemy.get_parent() as Path2D
	var crack := AnimatedSprite2D.new()
	crack.sprite_frames = enemy.sprite.sprite_frames
	crack.animation = &"crack" if crack.sprite_frames.has_animation(&"crack") else enemy.sprite.animation
	crack.position = enemy.position
	crack.rotation = enemy.sprite.rotation
	path.add_child(crack)
	var tween := crack.create_tween()
	tween.tween_property(crack, "modulate", Color.WHITE, CRACK_TIME).from(Enemy.SLOW_FLASH)
	tween.tween_callback(_split.bind(enemy.data, path, enemy.progress, crack.rotation))
	tween.tween_callback(crack.queue_free)

# Suelta los trozos en el punto de la nave, cada uno en su sitio del dibujo (de izquierda a
# derecha), con destello; salen despedidos de lado y vuelven al camino. Se mueve el sprite,
# no el enemigo, para que el empujón no cambie hacia dónde mira.
func _split(data: EnemyData, path: Path2D, progress: float, sprite_rotation: float) -> void:
	_pending_splits -= 1
	var side := Vector2.RIGHT.rotated(sprite_rotation)
	var count := data.split_into.size()
	for i in count:
		var piece := _spawn_enemy(data.split_into[i], path, progress)
		var offset := side * (i - (count - 1) / 2.0)
		piece.sprite.rotation = sprite_rotation
		piece.flash()
		var tween := piece.create_tween()
		tween.tween_property(piece.sprite, "position", offset * (SPLIT_GAP + SPLIT_PUSH), SPLIT_PUSH_TIME).from(offset * SPLIT_GAP)
		tween.tween_property(piece.sprite, "position", Vector2.ZERO, SPLIT_RETURN_TIME).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_enemy_reached_end(damage: int, enemy: Enemy) -> void:
	if not _alive.erase(enemy):
		return
	enemy_reached_end.emit(damage)
	_check_cleared()

func _check_cleared() -> void:
	if _wave_index < 0 or not is_clear():
		return
	wave_cleared.emit(_wave_index)
	if has_waves_left():
		_try_schedule_auto_wave()
	else:
		all_waves_cleared.emit()

func _try_schedule_auto_wave() -> void:
	if auto_waves and is_clear() and has_waves_left() and _auto_countdown < 0.0:
		_auto_countdown = AUTO_WAVE_DELAY
